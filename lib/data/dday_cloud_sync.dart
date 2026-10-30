import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotation/data/cloud_consent.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:quotation/data/together_crowd_layout.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/dday_invite_repository.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/together_test_room.dart';
import 'package:quotation/data/user_profile_sync.dart';
import 'package:quotation/widgets/together_widget_preview.dart';

/// A friend's home-widget apply that has already been written on this phone.
class TogetherLayoutNotice {
  const TogetherLayoutNotice({
    required this.roomId,
    required this.roomTitle,
    required this.actorName,
    required this.stamp,
  });

  final String roomId;
  final String roomTitle;
  final String actorName;
  final String stamp;
}

/// Keeps local D-Days + membership friend lists in sync with Firestore.
class DdayCloudSync {
  DdayCloudSync._();

  static final _db = FirebaseFirestore.instance;
  static final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _roomSubs = {};
  static final Map<String, String> _seenLayoutNotify = {};
  static bool _started = false;
  static bool _roomsHooked = false;

  /// Fired after a friend's applied layout is saved on this phone.
  static void Function(TogetherLayoutNotice notice)? onRemoteWidgetEdit;

  static Future<void> start() async {
    if (!CloudConsent.accepted) return;
    await stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _started = true;
    if (!_roomsHooked) {
      ddayController.addListener(_onRoomsChanged);
      _roomsHooked = true;
    }
    await UserProfileSync.upsertCurrentUser();
    await pushOwnedDdays();
    await pullMemberships();
    _bindRoomWatches();
  }

  static void _onRoomsChanged() {
    if (!_started) return;
    _bindRoomWatches();
  }

  /// Each open room listens to its own membership document.
  /// A document read is allowed for any signed-in user, so a friend sees
  /// character, background, and cheer updates without a collection query.
  static void _bindRoomWatches() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ids = ddayController.items.map((e) => e.id).toSet();
    for (final id in _roomSubs.keys.toList()) {
      if (ids.contains(id)) continue;
      _roomSubs.remove(id)?.cancel();
    }
    for (final id in ids) {
      if (_roomSubs.containsKey(id)) continue;
      var first = true;
      _roomSubs[id] = _db.collection('dday_memberships').doc(id).snapshots().listen(
        (snap) async {
          final data = snap.data();
          if (data == null || !_started) return;
          final notify = !first;
          first = false;
          try {
            final notice = await _applyMembershipDoc(
              snap.id,
              data,
              uid,
              notifyRemote: notify,
            );
            await HomeWidgetSync.syncDday();
            if (notice != null) onRemoteWidgetEdit?.call(notice);
          } catch (e) {
            debugPrint('room watch $id: $e');
          }
        },
        onError: (Object e) => debugPrint('room watch $id: $e'),
      );
    }
  }

  static Future<void> stop() async {
    for (final s in _roomSubs.values) {
      await s.cancel();
    }
    _roomSubs.clear();
    _started = false;
  }

  static Future<void> pushOwnedDdays() async {
    if (!CloudConsent.accepted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (final item in ddayController.items) {
      if (item.cloudOwnerUid != null && item.cloudOwnerUid != uid) {
        continue; // joined dday owned by someone else
      }
      try {
        await _db.collection('ddays').doc(item.id).set(
          {
            'ownerUid': uid,
            'title': item.title,
            'targetDate': Timestamp.fromDate(
              DateTime(
                item.targetDate.year,
                item.targetDate.month,
                item.targetDate.day,
              ),
            ),
            'iconId': item.iconId,
            'repeatYearly': item.repeatYearly,
            'status': item.hasFriend ? 'paired' : 'solo',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('pushOwnedDdays ${item.id}: $e');
      }
    }
  }

  static Future<void> pushDday(DdayItem item) async {
    if (!CloudConsent.accepted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (item.cloudOwnerUid != null && item.cloudOwnerUid != uid) return;
    await _db.collection('ddays').doc(item.id).set(
      {
        'ownerUid': uid,
        'title': item.title,
        'targetDate': Timestamp.fromDate(
          DateTime(
            item.targetDate.year,
            item.targetDate.month,
            item.targetDate.day,
          ),
        ),
        'iconId': item.iconId,
        'repeatYearly': item.repeatYearly,
        'status': item.hasFriend ? 'paired' : 'solo',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    try {
      await DdayInviteRepository.ensureHostMembership(item.id);
    } catch (e) {
      debugPrint('ensureHostMembership after pushDday: $e');
    }
  }

  static Future<void> pullMemberships() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final docs = await DdayInviteRepository.allMembershipsForUser(uid);
      for (final doc in docs) {
        await _applyMembershipDoc(doc.id, doc.data(), uid);
      }
      await HomeWidgetSync.syncDday();
    } catch (e) {
      debugPrint('pullMemberships: $e');
    }
  }

  static String? _cheerForDevice(String roomId, Map<String, dynamic> data) {
    final text = (data['latestCheer'] as String?)?.trim();
    final author = data['latestCheerAuthorUid'] as String?;
    final visible = blockedUsersController.visibleCheer(
      roomId,
      text,
      authorUid: author,
    );
    return visible.isEmpty ? null : visible;
  }

  static Future<TogetherLayoutNotice?> _applyMembershipDoc(
    String ddayId,
    Map<String, dynamic> data,
    String myUid, {
    bool notifyRemote = false,
  }) async {
    final hostUid = data['hostUid'] as String? ?? '';
    final hostCharacterId = data['hostCharacterId'] as String? ?? 'basic';
    var hostName = (data['hostDisplayName'] as String?)?.trim() ?? '';
    if (hostName.isEmpty && hostUid.isNotEmpty && hostUid != myUid) {
      final profile = await UserProfileSync.fetchUser(hostUid);
      hostName = (profile?['displayName'] as String?)?.trim() ?? '';
    }
    final membersRaw = data['members'] as List<dynamic>? ?? [];
    final members = membersRaw
        .map((e) => DdayFriendMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.uid.isNotEmpty)
        .toList();
    final namedMembers = <DdayFriendMember>[];
    for (final member in members) {
      var name = member.displayName?.trim() ?? '';
      if (name.isEmpty) {
        final profile = await UserProfileSync.fetchUser(member.uid);
        name = (profile?['displayName'] as String?)?.trim() ?? '';
      }
      namedMembers.add(
        DdayFriendMember(
          uid: member.uid,
          characterId: member.characterId,
          displayName: name.isEmpty ? null : name,
        ),
      );
    }
    final rawCheer = (data['latestCheer'] as String?)?.trim() ?? '';
    final latestCheer = _cheerForDevice(ddayId, data);
    if (rawCheer.isNotEmpty && (latestCheer == null || latestCheer.isEmpty)) {
      final stored = ddayController.items.where((e) => e.id == ddayId);
      final localCheer = stored.isEmpty
          ? ''
          : (stored.first.latestCheer ?? '').trim();
      if (localCheer.isEmpty || localCheer == rawCheer) {
        await ddayController.setRoomCheer(ddayId, '');
      }
    }

    if (ddayId == TogetherTestRoom.roomId && !togetherTestRoom.enabled) {
      if (ddayController.items.any((e) => e.id == ddayId)) {
        await ddayController.remove(ddayId);
      }
      return null;
    }

    // Friends shown to me: if I'm host → guests; if I'm guest → host + other guests.
    final List<DdayFriendMember> friendsForMe;
    if (myUid == hostUid) {
      friendsForMe = namedMembers;
    } else {
      friendsForMe = [
        DdayFriendMember(
          uid: hostUid,
          characterId: hostCharacterId,
          displayName: hostName.isEmpty ? null : hostName,
        ),
        ...namedMembers.where((m) => m.uid != myUid),
      ].toList();
    }
    final shownFriends = (ddayId == TogetherTestRoom.roomId &&
            friendsForMe.isEmpty &&
            togetherTestRoom.enabled)
        ? [TogetherTestRoom.placeholderFriend()]
        : _withLayoutCharacters(friendsForMe, data['layoutCrowd']);

    final hasLocal = ddayController.items.any((e) => e.id == ddayId);

    if (!hasLocal) {
      // Guest may not have the room locally — pull from cloud.
      final ddaySnap = await _db.collection('ddays').doc(ddayId).get();
      final dday = ddaySnap.data();
      if (dday == null) return null;
      final target = (dday['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      await ddayController.upsertFromCloud(
        DdayItem(
          id: ddayId,
          title: dday['title'] as String? ?? 'Together',
          targetDate: target,
          iconId: dday['iconId'] as String? ?? 'heart',
          repeatYearly: dday['repeatYearly'] as bool? ?? false,
          cloudOwnerUid: hostUid,
          friends: shownFriends,
          latestCheer: (latestCheer == null || latestCheer.isEmpty)
              ? null
              : latestCheer,
        ),
        cheerAuthorUid: data['latestCheerAuthorUid'] as String?,
      );
    } else {
      await ddayController.applyFriendsFromCloud(
        ddayId: ddayId,
        friends: shownFriends,
        cloudOwnerUid: hostUid,
        latestCheer: (latestCheer == null || latestCheer.isEmpty)
            ? null
            : latestCheer,
        latestCheerAuthorUid: data['latestCheerAuthorUid'] as String?,
      );
    }

    final actor =
        (data['updatedBy'] ?? data['layoutUpdatedBy'])?.toString() ?? '';
    // Our own write is already in local dp. Applying it again would scale it
    // a second time when this phone's canvas differs from the saved one.
    if (actor.isEmpty || actor != myUid) {
      await _applySharedLayout(ddayId, data, myUid == hostUid);
    }
    await _rememberCrowd(ddayId, myUid);

    final stamp = _layoutStamp(data['layoutNotifyAt']);
    final unseen = stamp.isNotEmpty && _seenLayoutNotify[ddayId] != stamp;
    if (stamp.isNotEmpty) _seenLayoutNotify[ddayId] = stamp;
    if (!notifyRemote || !unseen || actor.isEmpty || actor == myUid) {
      return null;
    }
    final local = ddayController.items.where((e) => e.id == ddayId);
    final roomTitle = local.isEmpty ? '' : local.first.title;
    var actorName = (data['layoutUpdatedByName'] as String?)?.trim() ?? '';
    if (actorName.isEmpty) {
      for (final member in members) {
        final name = member.displayName?.trim() ?? '';
        if (member.uid == actor && name.isNotEmpty) {
          actorName = name;
          break;
        }
      }
    }
    if (actorName.isEmpty) {
      final profile = await UserProfileSync.fetchUser(actor);
      actorName = (profile?['displayName'] as String?)?.trim() ?? '';
    }
    return TogetherLayoutNotice(
      roomId: ddayId,
      roomTitle: roomTitle,
      actorName: actorName,
      stamp: stamp,
    );
  }

  static String _layoutStamp(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch.toString();
    return value?.toString() ?? '';
  }

  /// Stores the current arrangement so a new friend can be added without
  /// moving people who are already on the widget.
  static Future<void> _rememberCrowd(String ddayId, String myUid) async {
    final matches = ddayController.items.where((e) => e.id == ddayId);
    if (matches.isEmpty || myUid.isEmpty) return;
    final room = matches.first;
    final people = TogetherCrowdLayout.roster(
      myUid: myUid,
      myCharacterId: characterController.character.id,
      hostUid: room.cloudOwnerUid,
      friends: room.friends,
    );
    if (people.isEmpty) return;
    final key = TogetherCrowdLayout.keyFor(people);
    final saved = ddayController.crowdForRoom(ddayId);
    if (key == ddayController.crowdKeyForRoom(ddayId) &&
        saved.length == people.length) {
      return;
    }
    final canvas = await _localCanvas(ddayId);
    final placed = TogetherCrowdLayout.resolve(
      people: people,
      canvasW: canvas.width,
      canvasH: canvas.height,
      saved: saved,
    );
    if (placed.isEmpty) return;
    await ddayController.setDuoOffsets(
      roomId: ddayId,
      crowdKey: key,
      crowd: [
        for (final slot in placed)
          (
            uid: slot.uid,
            x: slot.x.round(),
            y: slot.y.round(),
            rotation: slot.rotationDegrees,
          ),
      ],
      fromCloud: true,
    );
  }

  /// Host-centric layout → this phone, so both widgets match.
  static Future<void> _applySharedLayout(
    String roomId,
    Map<String, dynamic> data,
    bool iAmHost,
  ) async {
    if (!data.containsKey('layoutHostX') &&
        !data.containsKey('layoutGuestX') &&
        !data.containsKey('layoutCharScale') &&
        !data.containsKey('layoutHostScale') &&
        !data.containsKey('layoutGuestScale') &&
        !data.containsKey('layoutShape') &&
        !data.containsKey('layoutWidgetSize') &&
        !data.containsKey('layoutBgColor') &&
        !data.containsKey('layoutBgOpacity') &&
        !data.containsKey('layoutTextColor') &&
        !data.containsKey('layoutTextX') &&
        !data.containsKey('layoutCrowdKey')) {
      return;
    }
    final local = await _localCanvas(roomId);
    final sx = _canvasRatio(
      local.width,
      (data['layoutCanvasW'] as num?)?.toDouble(),
    );
    final sy = _canvasRatio(
      local.height,
      (data['layoutCanvasH'] as num?)?.toDouble(),
    );
    int ax(int v) => (v * sx).round();
    int ay(int v) => (v * sy).round();
    // Scale is a percent, not a canvas offset. Do not stretch it per phone.
    int? aScale(int? v) => v;
    final hostX = ax((data['layoutHostX'] as num?)?.toInt() ?? 0);
    final hostY = ay((data['layoutHostY'] as num?)?.toInt() ?? 0);
    final guestX = ax((data['layoutGuestX'] as num?)?.toInt() ?? 0);
    final guestY = ay((data['layoutGuestY'] as num?)?.toInt() ?? 0);
    final rawTextX = (data['layoutTextX'] as num?)?.toInt();
    final rawTextY = (data['layoutTextY'] as num?)?.toInt();
    final textX = rawTextX == null ? null : ax(rawTextX);
    final textY = rawTextY == null ? null : ay(rawTextY);
    final legacyScale = (data['layoutCharScale'] as num?)?.toInt();
    final hostScale =
        aScale((data['layoutHostScale'] as num?)?.toInt() ?? legacyScale);
    final guestScale =
        aScale((data['layoutGuestScale'] as num?)?.toInt() ?? legacyScale);
    final textScale = aScale((data['layoutTextScale'] as num?)?.toInt());
    final rawBg = data['layoutBgTheme'] as String?;
    final bgTheme = rawBg == TogetherBgTheme.albumId ? null : rawBg;
    final textColor = (data['layoutTextColor'] as num?)?.toInt();
    final shapeId = data['layoutShape'] as String?;
    final shape =
        shapeId == null ? null : TogetherWidgetShape.byId(shapeId);
    final sizeId = data['layoutWidgetSize'] as String?;
    final widgetSize =
        sizeId == null ? null : TogetherWidgetSize.byId(sizeId);
    final crowdKey = data['layoutCrowdKey'] as String?;
    final crowd = _crowdPoints(data['layoutCrowd'], ax, ay);
    final sharedCrowd = crowd.isEmpty ? null : crowd;
    final sharedCrowdKey = (crowdKey == null || crowdKey.isEmpty)
        ? null
        : crowdKey;
    if (iAmHost) {
      await ddayController.setDuoOffsets(
        roomId: roomId,
        meX: hostX,
        meY: hostY,
        friendX: guestX,
        friendY: guestY,
        textX: textX,
        textY: textY,
        charScale: hostScale,
        friendScale: guestScale,
        textScale: textScale,
        bgTheme: bgTheme,
        textColor: textColor,
        shape: shape,
        widgetSize: widgetSize,
        crowdKey: sharedCrowd == null ? null : sharedCrowdKey,
        crowd: sharedCrowd,
        fromCloud: true,
      );
    } else {
      await ddayController.setDuoOffsets(
        roomId: roomId,
        meX: guestX,
        meY: guestY,
        friendX: hostX,
        friendY: hostY,
        textX: textX,
        textY: textY,
        charScale: guestScale,
        friendScale: hostScale,
        textScale: textScale,
        bgTheme: bgTheme,
        textColor: textColor,
        shape: shape,
        widgetSize: widgetSize,
        crowdKey: sharedCrowd == null ? null : sharedCrowdKey,
        crowd: sharedCrowd,
        fromCloud: true,
      );
    }
  }

  static List<TogetherCrowdSaved> _crowdPoints(
    Object? raw,
    int Function(int) ax,
    int Function(int) ay,
  ) {
    if (raw is! List) return const [];
    final out = <TogetherCrowdSaved>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final uid = entry['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;
      out.add((
        uid: uid,
        x: ax((entry['x'] as num?)?.toInt() ?? 0),
        y: ay((entry['y'] as num?)?.toInt() ?? 0),
        rotation: (entry['rotation'] as num?)?.toInt() ??
            (entry['r'] as num?)?.toInt() ??
            0,
      ));
    }
    return out;
  }

  /// Push duo offsets as shared host/guest layout for a room.
  /// Preview size this phone draws the together widget at.
  static Future<Size> _localCanvas(String roomId) async {
    final host = await HomeWidgetSync.loadHostPreviewSize(roomId: roomId);
    return TogetherWidgetPreview.sizeForShape(
      TogetherWidgetShape.square,
      TogetherWidgetSize.s42,
      host?.size,
      host?.forSize,
    );
  }

  /// Map a sender-canvas dp value onto this phone's canvas.
  static double _canvasRatio(double local, double? sender) {
    if (sender == null || sender < 40 || local < 40) return 1;
    final ratio = local / sender;
    if (!ratio.isFinite || ratio <= 0) return 1;
    return ratio.clamp(0.5, 2.2);
  }

  static Future<void> pushSharedLayout({
    String? roomId,
    bool notifyFriends = false,
    double? canvasW,
    double? canvasH,
  }) async {
    if (!CloudConsent.accepted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    DdayItem? item = ddayController.widgetDday;
    if (roomId != null) {
      final matches = ddayController.items.where((e) => e.id == roomId);
      item = matches.isEmpty ? null : matches.first;
    }
    if (uid == null || item == null) return;

    try {
      await DdayInviteRepository.ensureHostMembership(item.id);
    } catch (_) {}

    final meX = ddayController.meOffsetXForRoom(item.id);
    final meY = ddayController.meOffsetYForRoom(item.id);
    final friendX = ddayController.friendOffsetXForRoom(item.id);
    final friendY = ddayController.friendOffsetYForRoom(item.id);
    final textX = ddayController.textOffsetXForRoom(item.id);
    final textY = ddayController.textOffsetYForRoom(item.id);
    final meScale = ddayController.charScaleForRoom(item.id);
    final friendScale = ddayController.friendScaleForRoom(item.id);
    final textScale = ddayController.textScaleForRoom(item.id);
    final bgTheme = ddayController.bgThemeForRoom(item.id);
    final textColor = ddayController.textColorForRoom(item.id);
    const shape = TogetherWidgetShape.square;
    final widgetSize = ddayController.widgetSizeForRoom(item.id);
    final crowdKey = ddayController.crowdKeyForRoom(item.id);
    final crowd = ddayController.crowdForRoom(item.id);
    var hostUid = item.cloudOwnerUid ?? '';
    try {
      final mem = await _db.collection('dday_memberships').doc(item.id).get();
      final remoteHost = mem.data()?['hostUid'] as String?;
      if (remoteHost != null && remoteHost.isNotEmpty) hostUid = remoteHost;
    } catch (_) {}
    final people = TogetherCrowdLayout.roster(
      myUid: uid,
      myCharacterId: characterController.character.id,
      hostUid: hostUid.isEmpty ? item.cloudOwnerUid : hostUid,
      friends: item.friends,
    );
    final charByUid = {
      for (final person in people) person.uid: person.characterId,
    };
    final iAmHost = hostUid.isEmpty || hostUid == uid;
    final hostX = iAmHost ? meX : friendX;
    final hostY = iAmHost ? meY : friendY;
    final guestX = iAmHost ? friendX : meX;
    final guestY = iAmHost ? friendY : meY;
    final hostScale = iAmHost ? meScale : friendScale;
    final guestScale = iAmHost ? friendScale : meScale;
    var cw = canvasW;
    var ch = canvasH;
    if (cw == null || ch == null || cw < 40 || ch < 40) {
      final canvas = await _localCanvas(item.id);
      cw = canvas.width;
      ch = canvas.height;
    }

    try {
      await _db.collection('dday_memberships').doc(item.id).set(
        {
          'layoutCanvasW': cw,
          'layoutCanvasH': ch,
          'layoutHostX': hostX,
          'layoutHostY': hostY,
          'layoutGuestX': guestX,
          'layoutGuestY': guestY,
          'layoutTextX': textX,
          'layoutTextY': textY,
          'layoutCharScale': hostScale,
          'layoutHostScale': hostScale,
          'layoutGuestScale': guestScale,
          'layoutTextScale': textScale,
          'layoutBgTheme': bgTheme,
          'layoutTextColor': textColor,
          'layoutShape': shape.id,
          'layoutWidgetSize': widgetSize.id,
          if (crowdKey.isNotEmpty) 'layoutCrowdKey': crowdKey,
          if (crowd.isNotEmpty)
            'layoutCrowd': [
              for (final slot in crowd)
                {
                  'uid': slot.uid,
                  'x': slot.x,
                  'y': slot.y,
                  'rotation': slot.rotation,
                  if ((charByUid[slot.uid] ?? '').isNotEmpty)
                    'characterId': charByUid[slot.uid],
                },
            ],
          'layoutUpdatedBy': uid,
          'layoutUpdatedByName':
              FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '',
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          if (notifyFriends) 'layoutNotifyAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('pushSharedLayout: $e');
    }
  }

  static List<DdayFriendMember> _withLayoutCharacters(
    List<DdayFriendMember> friends,
    Object? raw,
  ) {
    if (raw is! List) return friends;
    final chars = <String, String>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final uid = entry['uid']?.toString() ?? '';
      final id = entry['characterId']?.toString() ?? '';
      if (uid.isEmpty || id.isEmpty) continue;
      chars[uid] = id;
    }
    if (chars.isEmpty) return friends;
    return [
      for (final friend in friends)
        if (chars.containsKey(friend.uid))
          DdayFriendMember(
            uid: friend.uid,
            characterId: chars[friend.uid]!,
            displayName: friend.displayName,
          )
        else
          friend,
    ];
  }

  static bool get isStarted => _started;
}
