import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
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

  /// Ensures the host has a membership doc so cheers/layout sync work before
  /// any friend joins.
  static Future<void> ensureHostMembership(String ddayId) async {
    final uid = _uid;
    if (uid == null) throw StateError('not_signed_in');
    final ref = _db.collection('dday_memberships').doc(ddayId);

    try {
      final snap = await ref.get();
      if (snap.exists) {
        final hostUid = snap.data()?['hostUid'] as String? ?? '';
        final guestUids = (snap.data()?['guestUids'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        if (hostUid == uid || guestUids.contains(uid)) return;
        throw StateError('not_member');
      }
    } catch (e) {
      // Missing-doc get used to fail under old rules — fall through to create.
      if (e is StateError) rethrow;
      debugPrint('ensureHostMembership get: $e');
    }

    final ddaySnap = await _db.collection('ddays').doc(ddayId).get();
    final ownerUid = ddaySnap.data()?['ownerUid'] as String?;
    if (ownerUid != null && ownerUid != uid) {
      throw StateError('not_host');
    }

    await UserProfileSync.upsertCurrentUser();
    final hostName = await UserProfileSync.savedNickname();
    await ref.set({
      'hostUid': uid,
      'hostCharacterId': characterController.character.id,
      if (hostName != null && hostName.isNotEmpty) 'hostDisplayName': hostName,
      'members': <Map<String, dynamic>>[],
      'guestUids': <String>[],
      'maxGuests': DdayInviteLimits.maxFriends,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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

    // A friend already in the room invites too. The code names the room's
    // real host (joining is checked against it) and records who made it in
    // createdBy; the rules allow that (friendInvites). The room's D-day doc
    // and invite switch stay the host's.
    final room = await _db.collection('dday_memberships').doc(ddayId).get();
    final roomHost = room.data()?['hostUid'] as String? ?? '';
    final roomGuests = (room.data()?['guestUids'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    if (room.exists && roomHost.isNotEmpty && roomHost != uid) {
      if (!roomGuests.contains(uid)) throw StateError('not_member');
      return _friendInvite(ddayId: ddayId, hostUid: roomHost, uid: uid);
    }

    await ensureHostMembership(ddayId);
    await _db.collection('dday_memberships').doc(ddayId).set({
      'inviteOpen': true,
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final ddayRef = _db.collection('ddays').doc(ddayId);
    await ddayRef.set({
      'ownerUid': uid,
      'title': title,
      'targetDate': Timestamp.fromDate(
        DateTime(targetDate.year, targetDate.month, targetDate.day),
      ),
      'iconId': iconId,
      'repeatYearly': repeatYearly,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Single-field query so this works before a composite index is built.
    final existing = await _db
        .collection('dday_invites')
        .where('hostUid', isEqualTo: uid)
        .limit(40)
        .get();
    for (final doc in existing.docs) {
      final data = doc.data();
      if (data['ddayId'] != ddayId || !isLiveStatus(data['status'])) continue;
      final code = data['code'] as String?;
      if (code == null || code.isEmpty) continue;
      // Codes last as long as the room. One that the old 7-day limit
      // expired (or that still carries a date older apps would expire)
      // is opened again as it was, so a code already shared keeps working.
      if (data['status'] != 'pending' || data.containsKey('expiresAt')) {
        await _keepForever(doc.reference);
      }
      return DdayInviteResult(
        code: code,
        inviteId: doc.id,
        shareUrl: DdayInviteLimits.shareUrl(code),
      );
    }

    // No expiresAt: a code lasts as long as the room.
    final code = await _uniqueCode();
    final inviteRef = _db.collection('dday_invites').doc();
    await inviteRef.set({
      'ddayId': ddayId,
      'hostUid': uid,
      'code': code,
      'status': 'pending',
      'maxGuests': DdayInviteLimits.maxFriends,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return DdayInviteResult(
      code: code,
      inviteId: inviteRef.id,
      shareUrl: DdayInviteLimits.shareUrl(code),
    );
  }

  /// Invite made by a friend (not the host) of [ddayId].
  static Future<DdayInviteResult> _friendInvite({
    required String ddayId,
    required String hostUid,
    required String uid,
  }) async {
    // Joining needs the room open; a member may switch it on.
    try {
      await _db.collection('dday_memberships').doc(ddayId).set({
        'inviteOpen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('friend invite inviteOpen: $e');
    }
    // One code per room: reuse any open code naming this room's host,
    // whoever made it (the host's own lookup finds friends' codes the same
    // way), so everyone in the room sees the same code.
    // Narrowed to this room: a friend may only run small invite queries.
    final existing = await _db
        .collection('dday_invites')
        .where('hostUid', isEqualTo: hostUid)
        .where('ddayId', isEqualTo: ddayId)
        .limit(5)
        .get();
    for (final doc in existing.docs) {
      final data = doc.data();
      if (data['ddayId'] != ddayId || !isLiveStatus(data['status'])) continue;
      if (data['hostUid'] != hostUid) continue;
      final code = data['code'] as String?;
      if (code == null || code.isEmpty) continue;
      // Only the host may reopen an expired one; a pending one loses its
      // old date here so older apps never expire it.
      if (data['status'] == 'pending' && data.containsKey('expiresAt')) {
        await _keepForever(doc.reference);
      }
      return DdayInviteResult(
        code: code,
        inviteId: doc.id,
        shareUrl: DdayInviteLimits.shareUrl(code),
      );
    }

    final code = await _uniqueCode();
    final inviteRef = _db.collection('dday_invites').doc();
    await inviteRef.set({
      'ddayId': ddayId,
      'hostUid': hostUid,
      'createdBy': uid,
      'code': code,
      'status': 'pending',
      'maxGuests': DdayInviteLimits.maxFriends,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return DdayInviteResult(
      code: code,
      inviteId: inviteRef.id,
      shareUrl: DdayInviteLimits.shareUrl(code),
    );
  }

  /// Room id → its invite code, kept on this phone so the invite screen can
  /// show it at once (codes last as long as the room).
  static const _codeCacheKey = 'dday_invite_code_cache_v1';

  static Future<Map<String, String>> _readCodeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_codeCacheKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if ('${e.value}'.isNotEmpty) '${e.key}': '${e.value}',
      };
    } catch (_) {
      return {};
    }
  }

  static Future<String?> cachedCode(String roomId) async =>
      (await _readCodeCache())[roomId];

  static Future<void> cacheCode(String roomId, String code) async {
    try {
      final map = await _readCodeCache();
      if (map[roomId] == code) return;
      map[roomId] = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_codeCacheKey, jsonEncode(map));
    } catch (_) {}
  }

  static Future<void> forgetCachedCode(String roomId) async {
    try {
      final map = await _readCodeCache();
      if (map.remove(roomId) == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_codeCacheKey, jsonEncode(map));
    } catch (_) {}
  }

  /// A code that still lets people join: pending, or expired only by the
  /// old 7-day limit (codes now last as long as the room). Revoked stays off.
  static bool isLiveStatus(Object? status) =>
      status == 'pending' || status == 'expired';

  /// Reopens [ref] for good: pending, with no date to expire on.
  static Future<void> _keepForever(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      await ref.update({
        'status': 'pending',
        'expiresAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('invite keepForever: $e');
    }
  }

  static Future<String> _uniqueCode() async {
    for (var i = 0; i < 12; i++) {
      final code = _randomCode();
      final hit = await _db
          .collection('dday_invites')
          .where('code', isEqualTo: code)
          .limit(3)
          .get();
      final taken = hit.docs.any((doc) => isLiveStatus(doc.data()['status']));
      if (!taken) return code;
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

  /// Accept invite by 6-char code.
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
        .limit(5)
        .get();
    // Expired only by the old 7-day limit still counts: codes last as long
    // as the room. A pending one is preferred (its stats can be updated).
    final live =
        invites.docs.where((doc) => isLiveStatus(doc.data()['status'])).toList()
          ..sort(
            (a, b) => (a.data()['status'] == 'pending' ? 0 : 1).compareTo(
              b.data()['status'] == 'pending' ? 0 : 1,
            ),
          );
    if (live.isEmpty) throw StateError('invite_not_found');

    final inviteDoc = live.first;
    final invitePending = inviteDoc.data()['status'] == 'pending';
    final invite = inviteDoc.data();
    final hostUid = invite['hostUid'] as String? ?? '';
    final ddayId = invite['ddayId'] as String? ?? '';
    if (hostUid.isEmpty || ddayId.isEmpty) throw StateError('invite_invalid');
    // The host named on the code may have left since: who the host is now
    // (and whether this is my own room) is decided from the room below.

    final membershipRef = _db.collection('dday_memberships').doc(ddayId);
    final ddayRef = _db.collection('ddays').doc(ddayId);
    final guestProfile = await UserProfileSync.fetchUser(uid);
    final guestChar =
        guestProfile?['characterId'] as String? ??
        characterController.character.id;
    final guestName =
        (guestProfile?['displayName'] as String?)?.trim().isNotEmpty == true
        ? guestProfile!['displayName'] as String
        : await UserProfileSync.savedNickname();
    final hostProfile = await UserProfileSync.fetchUser(hostUid);
    final hostName = (hostProfile?['displayName'] as String?)?.trim();
    final hostCharacterId = hostProfile?['characterId'] as String? ?? 'basic';

    await _db.runTransaction((tx) async {
      final memSnap = await tx.get(membershipRef);
      final ddaySnap = await tx.get(ddayRef);
      // The room went away (its last person left): nothing to join. A
      // guest cannot create a room, so this used to fail as "sign in".
      if (!ddaySnap.exists || !memSnap.exists) throw StateError('room_gone');

      final data = memSnap.data()!;
      final members = (data['members'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final currentHost = data['hostUid'] as String? ?? hostUid;
      if (currentHost == uid) throw StateError('cannot_join_own');
      final resolvedHostChar =
          data['hostCharacterId'] as String? ?? hostCharacterId;
      final resolvedHostName = currentHost == hostUid
          ? hostName
          : (data['hostDisplayName'] as String?)?.trim();
      final guestUids = (data['guestUids'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      if (guestUids.contains(uid) || members.any((m) => m['uid'] == uid)) {
        return; // already joined
      }

      if (members.length >= DdayInviteLimits.maxFriends) {
        throw StateError('friends_full');
      }

      members.add({
        'uid': uid,
        'characterId': guestChar,
        'displayName': ?guestName,
        'joinedAt': Timestamp.now(),
      });
      final newGuestUids = members.map((m) => m['uid'] as String).toList();

      // hostUid stays whoever the room has now (the rules only let a joiner
      // keep it as it is).
      tx.set(membershipRef, {
        'hostUid': currentHost,
        'hostCharacterId': resolvedHostChar,
        if (resolvedHostName != null && resolvedHostName.isNotEmpty)
          'hostDisplayName': resolvedHostName,
        'members': members,
        'guestUids': newGuestUids,
        'maxGuests': DdayInviteLimits.maxFriends,
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(ddayRef, {
        'status': 'paired',
        'memberCount': members.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Keep the code pending so more people can join, up to 10 including the host.
      // An old-expired code cannot be written by a joiner (rules): skip
      // its stats, the join itself does not need them.
      if (invitePending) {
        tx.set(inviteDoc.reference, {
          'lastAcceptedBy': uid,
          'acceptedCount': newGuestUids.length,
          'expiresAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    // Rejoining a room I once left on this phone.
    await ddayController.forgetLeft(ddayId);
    return ddayId;
  }

  static Future<void> revokeInvitesForDday(String ddayId) async {
    final uid = _uid;
    if (uid == null) return;
    final snaps = await _db
        .collection('dday_invites')
        .where('hostUid', isEqualTo: uid)
        .limit(40)
        .get();
    for (final doc in snaps.docs) {
      final data = doc.data();
      if (data['ddayId'] != ddayId || data['status'] != 'pending') continue;
      await doc.reference.update({'status': 'revoked'});
    }
    await _db.collection('dday_memberships').doc(ddayId).set({
      'inviteOpen': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
