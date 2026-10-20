import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/dday_invite_repository.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/user_profile_sync.dart';

/// Keeps local D-Days + membership friend lists in sync with Firestore.
class DdayCloudSync {
  DdayCloudSync._();

  static final _db = FirebaseFirestore.instance;
  static final List<StreamSubscription<dynamic>> _subs = [];
  static bool _started = false;

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
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        await _applyMembershipDoc(change.doc.id, data, uid);
      }
      await HomeWidgetSync.syncDday();
    });
    final guestSub = _db
        .collection('dday_memberships')
        .where('guestUids', arrayContains: uid)
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        await _applyMembershipDoc(change.doc.id, data, uid);
      }
      await HomeWidgetSync.syncDday();
    });
    _subs.add(hostSub);
    _subs.add(guestSub);
  }

  static Future<void> _applyMembershipDoc(
    String ddayId,
    Map<String, dynamic> data,
    String myUid,
  ) async {
    final hostUid = data['hostUid'] as String? ?? '';
    final hostCharacterId = data['hostCharacterId'] as String? ?? 'basic';
    final membersRaw = data['members'] as List<dynamic>? ?? [];
    final members = membersRaw
        .map((e) => DdayFriendMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.uid.isNotEmpty)
        .take(DdayInviteLimits.maxFriends)
        .toList();
    final latestCheer = (data['latestCheer'] as String?)?.trim();

    // Friends shown to me: if I'm host → guests; if I'm guest → host + other guests.
    final List<DdayFriendMember> friendsForMe;
    if (myUid == hostUid) {
      friendsForMe = members;
    } else {
      friendsForMe = [
        DdayFriendMember(uid: hostUid, characterId: hostCharacterId),
        ...members.where((m) => m.uid != myUid),
      ].take(DdayInviteLimits.maxFriends).toList();
    }

    final hasLocal = ddayController.items.any((e) => e.id == ddayId);

    if (!hasLocal) {
      // Guest may not have the room locally — pull from cloud.
      final ddaySnap = await _db.collection('ddays').doc(ddayId).get();
      final dday = ddaySnap.data();
      if (dday == null) return;
      final target = (dday['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      await ddayController.upsertFromCloud(
        DdayItem(
          id: ddayId,
          title: dday['title'] as String? ?? 'Together',
          targetDate: target,
          iconId: dday['iconId'] as String? ?? 'heart',
          repeatYearly: dday['repeatYearly'] as bool? ?? false,
          cloudOwnerUid: hostUid,
          friends: friendsForMe,
          latestCheer: (latestCheer == null || latestCheer.isEmpty)
              ? null
              : latestCheer,
        ),
      );
    } else {
      await ddayController.applyFriendsFromCloud(
        ddayId: ddayId,
        friends: friendsForMe,
        cloudOwnerUid: hostUid,
        latestCheer: (latestCheer == null || latestCheer.isEmpty)
            ? null
            : latestCheer,
      );
    }

    await _applySharedLayout(ddayId, data, myUid == hostUid);
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
        !data.containsKey('layoutShape') &&
        !data.containsKey('layoutWidgetSize') &&
        !data.containsKey('layoutBgColor') &&
        !data.containsKey('layoutBgOpacity') &&
        !data.containsKey('layoutTextColor') &&
        !data.containsKey('layoutTextX')) {
      return;
    }
    final hostX = (data['layoutHostX'] as num?)?.toInt() ?? 0;
    final hostY = (data['layoutHostY'] as num?)?.toInt() ?? 0;
    final guestX = (data['layoutGuestX'] as num?)?.toInt() ?? 0;
    final guestY = (data['layoutGuestY'] as num?)?.toInt() ?? 0;
    final textX = (data['layoutTextX'] as num?)?.toInt();
    final textY = (data['layoutTextY'] as num?)?.toInt();
    final charScale = (data['layoutCharScale'] as num?)?.toInt();
    final textScale = (data['layoutTextScale'] as num?)?.toInt();
    final bgColor = (data['layoutBgColor'] as num?)?.toInt();
    final bgOpacity = (data['layoutBgOpacity'] as num?)?.toInt();
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
        charScale: charScale,
        textScale: textScale,
        bgColor: bgColor,
        bgOpacity: bgOpacity,
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
        charScale: charScale,
        textScale: textScale,
        bgColor: bgColor,
        bgOpacity: bgOpacity,
        textColor: textColor,
        shape: shape,
        widgetSize: widgetSize,
        fromCloud: true,
      );
    }
  }

  /// Push duo offsets as shared host/guest layout for a room.
  static Future<void> pushSharedLayout({String? roomId}) async {
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
    final charScale = ddayController.charScaleForRoom(item.id);
    final textScale = ddayController.textScaleForRoom(item.id);
    final bgColor = ddayController.bgColorForRoom(item.id);
    final bgOpacity = ddayController.bgOpacityForRoom(item.id);
    final textColor = ddayController.textColorForRoom(item.id);
    const shape = TogetherWidgetShape.square;
    final widgetSize = ddayController.widgetSizeForRoom(item.id);
    final iAmHost = item.cloudOwnerUid == null || item.cloudOwnerUid == uid;
    final hostX = iAmHost ? meX : friendX;
    final hostY = iAmHost ? meY : friendY;
    final guestX = iAmHost ? friendX : meX;
    final guestY = iAmHost ? friendY : meY;

    try {
      await _db.collection('dday_memberships').doc(item.id).set(
        {
          'layoutHostX': hostX,
          'layoutHostY': hostY,
          'layoutGuestX': guestX,
          'layoutGuestY': guestY,
          'layoutTextX': textX,
          'layoutTextY': textY,
          'layoutCharScale': charScale,
          'layoutTextScale': textScale,
          'layoutBgColor': bgColor,
          'layoutBgOpacity': bgOpacity,
          'layoutTextColor': textColor,
          'layoutShape': shape.id,
          'layoutWidgetSize': widgetSize.id,
          'layoutUpdatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('pushSharedLayout: $e');
    }
  }

  static bool get isStarted => _started;
}
