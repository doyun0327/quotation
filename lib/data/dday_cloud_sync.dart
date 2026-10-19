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

    await _applySharedLayout(data, myUid == hostUid);
  }

  /// Host-centric layout → viewer-relative me/friend offsets.
  static Future<void> _applySharedLayout(
    Map<String, dynamic> data,
    bool iAmHost,
  ) async {
    if (!data.containsKey('layoutHostX') &&
        !data.containsKey('layoutGuestX')) {
      return;
    }
    final hostX = (data['layoutHostX'] as num?)?.toInt() ?? 0;
    final hostY = (data['layoutHostY'] as num?)?.toInt() ?? 0;
    final guestX = (data['layoutGuestX'] as num?)?.toInt() ?? 0;
    final guestY = (data['layoutGuestY'] as num?)?.toInt() ?? 0;
    if (iAmHost) {
      await ddayController.setDuoOffsets(
        meX: hostX,
        meY: hostY,
        friendX: guestX,
        friendY: guestY,
        fromCloud: true,
      );
    } else {
      await ddayController.setDuoOffsets(
        meX: guestX,
        meY: guestY,
        friendX: hostX,
        friendY: hostY,
        fromCloud: true,
      );
    }
  }

  /// Push current duo offsets as shared host/guest layout for the widget room.
  static Future<void> pushSharedLayout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final item = ddayController.widgetDday;
    if (uid == null || item == null) return;

    try {
      await DdayInviteRepository.ensureHostMembership(item.id);
    } catch (_) {}

    final iAmHost = item.cloudOwnerUid == null || item.cloudOwnerUid == uid;
    final hostX =
        iAmHost ? ddayController.duoMeOffsetX : ddayController.duoFriendOffsetX;
    final hostY =
        iAmHost ? ddayController.duoMeOffsetY : ddayController.duoFriendOffsetY;
    final guestX =
        iAmHost ? ddayController.duoFriendOffsetX : ddayController.duoMeOffsetX;
    final guestY =
        iAmHost ? ddayController.duoFriendOffsetY : ddayController.duoMeOffsetY;

    try {
      await _db.collection('dday_memberships').doc(item.id).set(
        {
          'layoutHostX': hostX,
          'layoutHostY': hostY,
          'layoutGuestX': guestX,
          'layoutGuestY': guestY,
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
