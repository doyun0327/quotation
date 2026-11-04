import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/dday_invite_repository.dart';

/// One room the anonymous account left for the next account to take over.
class RoomHandoff {
  const RoomHandoff({required this.roomId, required this.key});

  final String roomId;

  /// Kept in memory only. The room stores just its sha256.
  final String key;
}

/// Moves rooms from one Firebase account to another.
///
/// Signing in with Google or Apple on a phone that was anonymous can land on
/// a Firebase user that already exists (the same account used on another
/// phone). The uid then changes, and the rooms made anonymously still name
/// the old uid, so the rules reject every write from the new one
/// (`not_member`). The anonymous account cannot be signed back into, so the
/// move has to start while it is still the signed-in user.
///
/// Two ways, same result:
/// - [moveRooms]: the new uid is already known (Google: signed in once on a
///   throwaway app instance), so the anonymous user rewrites the rooms.
/// - [leaveHandoffs] then [claimHandoffs]: the new uid is only known after
///   the switch (Apple credentials work once). The anonymous user leaves a
///   hashed key on each room; the new user proves the key and takes over.
///   Needs the `isHandoffClaim` rule in firestore.rules.
abstract final class AccountMigration {
  static final _db = FirebaseFirestore.instance;

  /// Rewrites [fromUid] to [toUid] on every room [fromUid] belongs to.
  /// Best effort per room: one that fails is logged and the rest still move.
  static Future<int> moveRooms({
    required String fromUid,
    required String toUid,
  }) async {
    if (fromUid.isEmpty || toUid.isEmpty || fromUid == toUid) return 0;
    final docs = await DdayInviteRepository.allMembershipsForUser(fromUid);
    var moved = 0;
    for (final doc in docs) {
      try {
        await doc.reference.update(_roomUpdate(doc.data(), fromUid, toUid));
        await _moveOwner(doc.id, doc.data(), fromUid, toUid);
        moved++;
      } catch (e) {
        debugPrint('AccountMigration room ${doc.id}: $e');
      }
    }
    debugPrint('AccountMigration moved $moved/${docs.length} rooms');
    return moved;
  }

  /// Signed in as [fromUid]: marks each of its rooms as handed off.
  static Future<List<RoomHandoff>> leaveHandoffs(String fromUid) async {
    if (fromUid.isEmpty) return const [];
    final docs = await DdayInviteRepository.allMembershipsForUser(fromUid);
    final out = <RoomHandoff>[];
    final random = Random.secure();
    for (final doc in docs) {
      final key = base64Url.encode(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      try {
        await doc.reference.update({
          'handoff': {
            'from': fromUid,
            'keyHash': _hash(key),
            'at': FieldValue.serverTimestamp(),
          },
        });
        out.add(RoomHandoff(roomId: doc.id, key: key));
      } catch (e) {
        debugPrint('AccountMigration handoff ${doc.id}: $e');
      }
    }
    return out;
  }

  /// Signed in as [toUid]: takes over every room in [handoffs].
  static Future<int> claimHandoffs(
    List<RoomHandoff> handoffs,
    String toUid,
  ) async {
    var moved = 0;
    for (final handoff in handoffs) {
      try {
        final ref = _db.collection('dday_memberships').doc(handoff.roomId);
        final data = (await ref.get()).data();
        final ticket = data?['handoff'];
        if (data == null || ticket is! Map) continue;
        final fromUid = ticket['from']?.toString() ?? '';
        if (fromUid.isEmpty || fromUid == toUid) continue;
        await ref.update({
          ..._roomUpdate(data, fromUid, toUid),
          // The rule checks this against keyHash. Spent once handoff is gone.
          'handoffKey': handoff.key,
          'handoff': FieldValue.delete(),
        });
        await _moveOwner(handoff.roomId, data, fromUid, toUid);
        moved++;
      } catch (e) {
        debugPrint('AccountMigration claim ${handoff.roomId}: $e');
      }
    }
    debugPrint('AccountMigration claimed $moved/${handoffs.length} rooms');
    return moved;
  }

  /// Signed in as [fromUid] again because the switch failed: drop the keys.
  static Future<void> dropHandoffs(List<RoomHandoff> handoffs) async {
    for (final handoff in handoffs) {
      try {
        await _db
            .collection('dday_memberships')
            .doc(handoff.roomId)
            .update({'handoff': FieldValue.delete()});
      } catch (_) {}
    }
  }

  static String _hash(String key) =>
      sha256.convert(utf8.encode(key)).toString();

  /// [fromUid] → [toUid] on host, guests and members of one room.
  static Map<String, dynamic> _roomUpdate(
    Map<String, dynamic> data,
    String fromUid,
    String toUid,
  ) {
    final wasHost = data['hostUid'] == fromUid;
    final guests = [
      for (final g in data['guestUids'] as List<dynamic>? ?? const [])
        g.toString(),
    ];
    final members = [
      for (final m in data['members'] as List<dynamic>? ?? const [])
        if (m is Map) Map<String, dynamic>.from(m),
    ];
    String swap(Object? uid) =>
        uid?.toString() == fromUid ? toUid : (uid?.toString() ?? '');

    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      // The old account's typing dots would otherwise linger for their ttl.
      'editing.$fromUid': FieldValue.delete(),
    };
    if (wasHost) {
      update['hostUid'] = toUid;
      // Same person on both sides: never host and guest of one room.
      update['guestUids'] = [for (final g in guests) if (g != toUid) g];
      update['members'] = [for (final m in members) if (m['uid'] != toUid) m];
    } else {
      final seen = <String>{};
      update['guestUids'] = [
        for (final g in guests)
          if (seen.add(swap(g))) swap(g),
      ];
      final seenMembers = <String>{};
      update['members'] = [
        for (final m in members)
          if (seenMembers.add(swap(m['uid'])))
            m['uid'] == fromUid ? {...m, 'uid': toUid} : m,
      ];
    }
    if (data['latestCheerAuthorUid'] == fromUid) {
      update['latestCheerAuthorUid'] = toUid;
    }
    return update;
  }

  /// The room's D-day doc names its owner too.
  static Future<void> _moveOwner(
    String roomId,
    Map<String, dynamic> data,
    String fromUid,
    String toUid,
  ) async {
    if (data['hostUid'] != fromUid) return;
    final dday = _db.collection('ddays').doc(roomId);
    final snap = await dday.get();
    if (snap.data()?['ownerUid'] != fromUid) return;
    await dday.update({
      'ownerUid': toUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
