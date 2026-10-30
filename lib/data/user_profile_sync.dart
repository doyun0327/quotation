import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/cloud_consent.dart';
import 'package:quotation/data/character_controller.dart';

/// Mirrors local profile into `users/{uid}` for invite/membership.
class UserProfileSync {
  UserProfileSync._();

  static final _db = FirebaseFirestore.instance;

  static Future<void> upsertCurrentUser({String? displayName}) async {
    if (!CloudConsent.accepted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name = (displayName ?? user.displayName)?.trim();
    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'characterId': characterController.character.id,
          'displayName': (name == null || name.isEmpty) ? user.displayName : name,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('UserProfileSync.upsert: $e');
    }
  }

  /// Writes the nickname onto this user's membership rows so friends see it.
  static Future<void> syncDisplayName(String name) async {
    if (!CloudConsent.accepted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await upsertCurrentUser(displayName: trimmed);
    try {
      final asHost = await _db
          .collection('dday_memberships')
          .where('hostUid', isEqualTo: user.uid)
          .get();
      for (final doc in asHost.docs) {
        if (doc.data()['hostDisplayName'] != trimmed) {
          await doc.reference.set(
            {'hostDisplayName': trimmed},
            SetOptions(merge: true),
          );
        }
      }
      final asGuest = await _db
          .collection('dday_memberships')
          .where('guestUids', arrayContains: user.uid)
          .get();
      for (final doc in asGuest.docs) {
        final members = (doc.data()['members'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        var changed = false;
        for (final member in members) {
          if (member['uid'] == user.uid && member['displayName'] != trimmed) {
            member['displayName'] = trimmed;
            changed = true;
          }
        }
        if (changed) {
          await doc.reference.set(
            {'members': members},
            SetOptions(merge: true),
          );
        }
      }
    } catch (e) {
      debugPrint('UserProfileSync.syncDisplayName: $e');
    }
  }

  static Future<void> syncCharacter() async {
    if (!CloudConsent.accepted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'characterId': characterController.character.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      // Update membership docs where this user appears.
      await _refreshMembershipCharacters(user.uid);
    } catch (e) {
      debugPrint('UserProfileSync.syncCharacter: $e');
    }
  }

  static Future<void> _refreshMembershipCharacters(String uid) async {
    final charId = characterController.character.id;
    final asHost = await _db
        .collection('dday_memberships')
        .where('hostUid', isEqualTo: uid)
        .get();
    for (final doc in asHost.docs) {
      await doc.reference.set(
        {
          'hostCharacterId': charId,
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    final asGuest = await _db
        .collection('dday_memberships')
        .where('guestUids', arrayContains: uid)
        .get();
    for (final doc in asGuest.docs) {
      final data = doc.data();
      final members = (data['members'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      var changed = false;
      for (final m in members) {
        if (m['uid'] == uid && m['characterId'] != charId) {
          m['characterId'] = charId;
          changed = true;
        }
      }
      if (changed) {
        await doc.reference.set(
          {
            'members': members,
            'updatedBy': uid,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }
  }

  static Future<Map<String, dynamic>?> fetchUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }

  /// Removes this account's profile, hosted rooms, invites, and guest membership.
  /// Each step is isolated so a rules miss still lets the auth user be deleted.
  static Future<void> deleteRemoteAccount(String uid) async {
    if (uid.isEmpty) return;
    final db = _db;

    Future<void> step(String name, Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        debugPrint('deleteRemoteAccount $name: $e');
      }
    }

    await step('ddays', () async {
      final hostedDays = await db
          .collection('ddays')
          .where('ownerUid', isEqualTo: uid)
          .get();
      for (final doc in hostedDays.docs) {
        await doc.reference.delete();
      }
    });

    await step('hosted rooms', () async {
      final hostedRooms = await db
          .collection('dday_memberships')
          .where('hostUid', isEqualTo: uid)
          .get();
      for (final doc in hostedRooms.docs) {
        await doc.reference.delete();
      }
    });

    await step('guest rooms', () async {
      final guestRooms = await db
          .collection('dday_memberships')
          .where('guestUids', arrayContains: uid)
          .get();
      for (final doc in guestRooms.docs) {
        final data = doc.data();
        final guests = (data['guestUids'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((id) => id != uid)
            .toList();
        final members = (data['members'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((member) => member['uid'] != uid)
            .toList();
        await doc.reference.set(
          {
            'guestUids': guests,
            'members': members,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    await step('invites', () async {
      final invites = await db
          .collection('dday_invites')
          .where('hostUid', isEqualTo: uid)
          .get();
      for (final doc in invites.docs) {
        await doc.reference.delete();
      }
    });

    await step('profile', () async {
      await db.collection('users').doc(uid).delete();
    });
  }
}
