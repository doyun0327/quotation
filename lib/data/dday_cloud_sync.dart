import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/together_bg_themes.dart';
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
  static final List<StreamSubscription<dynamic>> _subs = [];
  static final Map<String, String> _seenLayoutNotify = {};
  static bool _started = false;

  /// Fired after a friend's applied layout is saved on this phone.
  static void Function(TogetherLayoutNotice notice)? onRemoteWidgetEdit;

  static Future<void> start() async {
    await stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _started = true;
    await UserProfileSync.upsertCurrentUser();
    await pushOwnedDdays();
    await pullMemberships();
    await _listenOwnedAndJoined(uid);
  }

  static Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _started = false;
  }

  static Future<void> pushOwnedDdays() async {
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

  static Future<void> _listenOwnedAndJoined(String uid) async {
    final hostSub = _db
        .collection('dday_memberships')
        .where('hostUid', isEqualTo: uid)
        .snapshots()
        .listen((snap) async {
      final notices = <TogetherLayoutNotice>[];
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final notice = await _applyMembershipDoc(
          change.doc.id,
          data,
          uid,
          notifyRemote: change.type == DocumentChangeType.modified,
        );
        if (notice != null) notices.add(notice);
      }
      await HomeWidgetSync.syncDday();
      for (final notice in notices) {
        onRemoteWidgetEdit?.call(notice);
      }
    });
    final guestSub = _db
        .collection('dday_memberships')
        .where('guestUids', arrayContains: uid)
        .snapshots()
        .listen((snap) async {
      final notices = <TogetherLayoutNotice>[];
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final notice = await _applyMembershipDoc(
          change.doc.id,
          data,
          uid,
          notifyRemote: change.type == DocumentChangeType.modified,
        );
        if (notice != null) notices.add(notice);
      }
      await HomeWidgetSync.syncDday();
      for (final notice in notices) {
        onRemoteWidgetEdit?.call(notice);
      }
    });
    _subs.add(hostSub);
    _subs.add(guestSub);
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
    final membersRaw = data['members'] as List<dynamic>? ?? [];
    final members = membersRaw
        .map((e) => DdayFriendMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.uid.isNotEmpty)
        .toList();
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
      friendsForMe = members;
    } else {
      friendsForMe = [
        DdayFriendMember(uid: hostUid, characterId: hostCharacterId),
        ...members.where((m) => m.uid != myUid),
      ].toList();
    }
    final shownFriends = (ddayId == TogetherTestRoom.roomId &&
            friendsForMe.isEmpty &&
            togetherTestRoom.enabled)
        ? [TogetherTestRoom.placeholderFriend()]
        : friendsForMe;

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
      );
    } else {
      await ddayController.applyFriendsFromCloud(
        ddayId: ddayId,
        friends: shownFriends,
        cloudOwnerUid: hostUid,
        latestCheer: (latestCheer == null || latestCheer.isEmpty)
            ? null
            : latestCheer,
      );
    }

    final actor =
        (data['updatedBy'] ?? data['layoutUpdatedBy'])?.toString() ?? '';
    // Our own write is already in local dp. Applying it again would scale it
    // a second time when this phone's canvas differs from the saved one.
    if (actor.isEmpty || actor != myUid) {
      await _applySharedLayout(ddayId, data, myUid == hostUid);
    }

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

  /// Host-centric layout → viewer-relative me/friend offsets.
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
        !data.containsKey('layoutTextX')) {
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
    int? aScale(int? v) => v == null ? null : (v * sx).round();
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
        fromCloud: true,
      );
    }
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
    var hostUid = item.cloudOwnerUid ?? '';
    try {
      final mem = await _db.collection('dday_memberships').doc(item.id).get();
      final remoteHost = mem.data()?['hostUid'] as String?;
      if (remoteHost != null && remoteHost.isNotEmpty) hostUid = remoteHost;
    } catch (_) {}
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
          if (bgTheme != TogetherBgTheme.albumId) 'layoutBgTheme': bgTheme,
          'layoutTextColor': textColor,
          'layoutShape': shape.id,
          'layoutWidgetSize': widgetSize.id,
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

  static bool get isStarted => _started;
}
