import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/character_controller.dart';

/// Mirrors local profile into `users/{uid}` for invite/membership.
class UserProfileSync {
  UserProfileSync._();

  static final _db = FirebaseFirestore.instance;

  static Future<void> upsertCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'characterId': characterController.character.id,
          'displayName': user.displayName,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('UserProfileSync.upsert: $e');
    }
  }

  static Future<void> syncCharacter() async {
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
        {'hostCharacterId': charId, 'updatedAt': FieldValue.serverTimestamp()},
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
}
