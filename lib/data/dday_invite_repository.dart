import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/user_profile_sync.dart';

class DdayInviteResult {
  const DdayInviteResult({
    required this.code,
    required this.inviteId,
    required this.shareUrl,
  });

  final String code;
  final String inviteId;
  final String shareUrl;
}

class DdayInviteRepository {
  DdayInviteRepository._();

  static final _db = FirebaseFirestore.instance;
  static final _rng = Random.secure();

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Upsert cloud dday owned by current user, then create/reuse a pending invite.
  static Future<DdayInviteResult> createOrGetInvite({
    required String ddayId,
    required String title,
    required DateTime targetDate,
    required String iconId,
    required bool repeatYearly,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('not_signed_in');
    }
    await UserProfileSync.upsertCurrentUser();

    final ddayRef = _db.collection('ddays').doc(ddayId);
    await ddayRef.set(
      {
        'ownerUid': uid,
        'title': title,
        'targetDate': Timestamp.fromDate(
          DateTime(targetDate.year, targetDate.month, targetDate.day),
        ),
        'iconId': iconId,
        'repeatYearly': repeatYearly,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Reuse pending invite for this dday if still valid.
    final existing = await _db
        .collection('dday_invites')
        .where('ddayId', isEqualTo: ddayId)
        .where('hostUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final code = doc.data()['code'] as String;
      final expiresAt = (doc.data()['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt == null || expiresAt.isAfter(DateTime.now())) {
        return DdayInviteResult(
          code: code,
          inviteId: doc.id,
          shareUrl: DdayInviteLimits.shareUrl(code),
        );
      }
      await doc.reference.update({'status': 'expired'});
    }

    final code = await _uniqueCode();
    final inviteRef = _db.collection('dday_invites').doc();
    final expiresAt = DateTime.now().add(DdayInviteLimits.inviteTtl);
    await inviteRef.set({
      'ddayId': ddayId,
      'hostUid': uid,
      'code': code,
      'status': 'pending',
      'maxGuests': DdayInviteLimits.maxFriends,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return DdayInviteResult(
      code: code,
      inviteId: inviteRef.id,
      shareUrl: DdayInviteLimits.shareUrl(code),
    );
  }

  static Future<String> _uniqueCode() async {
    for (var i = 0; i < 12; i++) {
      final code = _randomCode();
      final hit = await _db
          .collection('dday_invites')
          .where('code', isEqualTo: code)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (hit.docs.isEmpty) return code;
    }
    throw StateError('code_exhausted');
  }

  static String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      DdayInviteLimits.codeLength,
      (_) => chars[_rng.nextInt(chars.length)],
    ).join();
  }

  /// Accept invite by 6-char code. Up to [DdayInviteLimits.maxFriends] guests.
  static Future<String> acceptInviteByCode(String rawCode) async {
    final uid = _uid;
    if (uid == null) throw StateError('not_signed_in');
    final code = rawCode.trim().toUpperCase();
    if (code.length != DdayInviteLimits.codeLength) {
      throw StateError('invalid_code');
    }
    await UserProfileSync.upsertCurrentUser();

    final invites = await _db
        .collection('dday_invites')
        .where('code', isEqualTo: code)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (invites.docs.isEmpty) throw StateError('invite_not_found');

    final inviteDoc = invites.docs.first;
    final invite = inviteDoc.data();
    final hostUid = invite['hostUid'] as String? ?? '';
    final ddayId = invite['ddayId'] as String? ?? '';
    if (hostUid.isEmpty || ddayId.isEmpty) throw StateError('invite_invalid');
    if (hostUid == uid) throw StateError('cannot_join_own');

    final expiresAt = (invite['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      await inviteDoc.reference.update({'status': 'expired'});
      throw StateError('invite_expired');
    }

    final membershipRef = _db.collection('dday_memberships').doc(ddayId);
    final ddayRef = _db.collection('ddays').doc(ddayId);
    final guestProfile = await UserProfileSync.fetchUser(uid);
    final guestChar =
        guestProfile?['characterId'] as String? ?? characterController.character.id;
    final guestName = guestProfile?['displayName'] as String? ??
        FirebaseAuth.instance.currentUser?.displayName;
    final hostProfile = await UserProfileSync.fetchUser(hostUid);
    final hostCharacterId =
        hostProfile?['characterId'] as String? ?? 'basic';

    await _db.runTransaction((tx) async {
      final memSnap = await tx.get(membershipRef);
      final ddaySnap = await tx.get(ddayRef);
      if (!ddaySnap.exists) throw StateError('dday_missing');

      List<Map<String, dynamic>> members = [];
      var resolvedHostChar = hostCharacterId;
      if (memSnap.exists) {
        final data = memSnap.data()!;
        members = (data['members'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        resolvedHostChar = data['hostCharacterId'] as String? ?? hostCharacterId;
        final guestUids = (data['guestUids'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        if (guestUids.contains(uid) || members.any((m) => m['uid'] == uid)) {
          return; // already joined
        }
        if (members.length >= DdayInviteLimits.maxFriends) {
          throw StateError('friends_full');
        }
      }

      members.add({
        'uid': uid,
        'characterId': guestChar,
        if (guestName != null) 'displayName': guestName,
        'joinedAt': Timestamp.now(),
      });
      final guestUids = members.map((m) => m['uid'] as String).toList();

      tx.set(
        membershipRef,
        {
          'hostUid': hostUid,
          'hostCharacterId': resolvedHostChar,
          'members': members,
          'guestUids': guestUids,
          'maxGuests': DdayInviteLimits.maxFriends,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!memSnap.exists) 'pairedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        ddayRef,
        {
          'status': 'paired',
          'memberCount': members.length,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      // Keep invite pending so more friends (up to 5) can join with same code.
      tx.set(
        inviteDoc.reference,
        {
          'lastAcceptedBy': uid,
          'acceptedCount': guestUids.length,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    return ddayId;
  }

  static Future<void> revokeInvitesForDday(String ddayId) async {
    final uid = _uid;
    if (uid == null) return;
    final snaps = await _db
        .collection('dday_invites')
        .where('ddayId', isEqualTo: ddayId)
        .where('hostUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in snaps.docs) {
      await doc.reference.update({'status': 'revoked'});
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchMembership(
    String ddayId,
  ) {
    return _db.collection('dday_memberships').doc(ddayId).snapshots();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getMembership(
    String ddayId,
  ) {
    return _db.collection('dday_memberships').doc(ddayId).get();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> membershipsForUser(
    String uid,
  ) async {
    final asHost = await _db
        .collection('dday_memberships')
        .where('hostUid', isEqualTo: uid)
        .get();
    final asGuest = await _db
        .collection('dday_memberships')
        .where('guestUids', arrayContains: uid)
        .get();
    // Caller merges; return host query primarily — use dedicated method below.
    debugPrint(
      'memberships host=${asHost.docs.length} guest=${asGuest.docs.length}',
    );
    return asGuest;
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      allMembershipsForUser(String uid) async {
    final asHost = await _db
        .collection('dday_memberships')
        .where('hostUid', isEqualTo: uid)
        .get();
    final asGuest = await _db
        .collection('dday_memberships')
        .where('guestUids', arrayContains: uid)
        .get();
    final map = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in asHost.docs) {
      map[d.id] = d;
    }
    for (final d in asGuest.docs) {
      map[d.id] = d;
    }
    return map.values.toList();
  }
}
