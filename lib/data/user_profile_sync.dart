import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/cloud_consent.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors local profile into `users/{uid}` for invite/membership.
class UserProfileSync {
  UserProfileSync._();

  static final _db = FirebaseFirestore.instance;

  /// Nickname saved in the app. Android Google sign-in often has no account
  /// name, so Firebase displayName stays empty while this value is set.
  static Future<String?> savedNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('profile_nickname')?.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    final firebaseName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;
    return null;
  }

  static Future<void> upsertCurrentUser({String? displayName}) async {
    if (!CloudConsent.accepted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final explicit = displayName?.trim();
    final name = (explicit != null && explicit.isNotEmpty)
        ? explicit
        : await savedNickname();
    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'characterId': characterController.character.id,
          'email': user.email,
          // Never write null: that wiped a saved nickname on Android.
          if (name != null && name.isNotEmpty) 'displayName': name,
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
      await _stampNicknameOnKnownRooms(user.uid, trimmed);
      final asHost = await _db
          .collection('dday_memberships')
          .where('hostUid', isEqualTo: user.uid)
          .get();
      for (final doc in asHost.docs) {
        if (doc.data()['hostDisplayName'] != trimmed) {
          await doc.reference.set(
            {
              'hostDisplayName': trimmed,
              'widgetRefreshAt': FieldValue.serverTimestamp(),
            },
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
            {
              'members': members,
              'widgetRefreshAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }
    } catch (e) {
      debugPrint('UserProfileSync.syncDisplayName: $e');
    }
  }

  /// Writes [name] onto rooms this phone already has, without a collection query.
  static Future<void> _stampNicknameOnKnownRooms(String uid, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dday_items_v1');
    final roomIds = <String>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map && item['id'] is String && (item['id'] as String).isNotEmpty) {
              roomIds.add(item['id'] as String);
            }
          }
        }
      } catch (_) {}
    }
    for (final roomId in roomIds) {
      final ref = _db.collection('dday_memberships').doc(roomId);
      final snap = await ref.get();
      if (!snap.exists) continue;
      final data = snap.data() ?? {};
      final hostUid = data['hostUid'] as String? ?? '';
      if (hostUid == uid) {
        if (data['hostDisplayName'] != name) {
          await ref.set(
            {
              'hostDisplayName': name,
              'widgetRefreshAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        continue;
      }
      final members = (data['members'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      var changed = false;
      for (final member in members) {
        if (member['uid'] == uid && member['displayName'] != name) {
          member['displayName'] = name;
          changed = true;
        }
      }
      if (changed) {
        await ref.set(
          {
            'members': members,
            'widgetRefreshAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
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
      // Rooms keep their own character (picked in the widget decorator);
      // the main-screen character is only the default for new rooms.
    } catch (e) {
      debugPrint('UserProfileSync.syncCharacter: $e');
    }
  }

  /// Writes my character for one room only (host: hostCharacterId, guest:
  /// my members[] entry). Friends get a silent push to redraw widgets.
  static Future<void> syncRoomCharacter(String roomId, String charId) async {
    if (!CloudConsent.accepted || roomId.isEmpty || charId.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ref = _db.collection('dday_memberships').doc(roomId);
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) return;
      final crowd = _layoutCrowdWithCharacter(data['layoutCrowd'], uid, charId);
      if (data['hostUid'] == uid) {
        final hostChanged = data['hostCharacterId'] != charId;
        if (!hostChanged && crowd == null) return;
        await ref.set(
          {
            if (hostChanged) 'hostCharacterId': charId,
            if (crowd != null) 'layoutCrowd': crowd,
            'updatedBy': uid,
            'updatedAt': FieldValue.serverTimestamp(),
            'widgetRefreshAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }
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
      if (!changed && crowd == null) return;
      await ref.set(
        {
          if (changed) 'members': members,
          if (crowd != null) 'layoutCrowd': crowd,
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'widgetRefreshAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('UserProfileSync.syncRoomCharacter: $e');
    }
  }

  static List<Map<String, dynamic>>? _layoutCrowdWithCharacter(
    Object? raw,
    String uid,
    String charId,
  ) {
    if (raw is! List) return null;
    var changed = false;
    final next = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final slot = Map<String, dynamic>.from(entry);
      if (slot['uid']?.toString() == uid &&
          slot['characterId']?.toString() != charId) {
        slot['characterId'] = charId;
        changed = true;
      }
      next.add(slot);
    }
    return changed ? next : null;
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

    // Every step runs, but a failure stops the sign-in being deleted: that
    // would leave this data with no account left to retry the deletion from.
    Object? failure;
    Future<void> step(String name, Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        debugPrint('deleteRemoteAccount $name: $e');
        failure ??= e;
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
        // Words stay for the room (see the privacy policy); who wrote them
        // does not.
        bool removeIfMine(String field) => data[field] == uid;
        await doc.reference.set(
          {
            'guestUids': guests,
            'members': members,
            if (data['layoutCrowd'] is List)
              'layoutCrowd': [
                for (final entry in data['layoutCrowd'] as List<dynamic>)
                  if (entry is! Map || entry['uid'] != uid) entry,
              ],
            if (data['layoutBubbles'] is List)
              'layoutBubbles': [
                for (final entry in data['layoutBubbles'] as List<dynamic>)
                  if (entry is Map && entry['by'] == uid)
                    ({...entry}..remove('by'))
                  else
                    entry,
              ],
            if (removeIfMine('latestCheerAuthorUid')) ...{
              'latestCheerAuthorUid': FieldValue.delete(),
              'latestCheerAuthorName': FieldValue.delete(),
            },
            if (removeIfMine('layoutUpdatedBy')) ...{
              'layoutUpdatedBy': FieldValue.delete(),
              'layoutUpdatedByName': FieldValue.delete(),
            },
            if (removeIfMine('updatedBy')) 'updatedBy': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        // A dotted path only means a nested field in update(), not in set().
        final editing = data['editing'];
        if (editing is Map && editing.containsKey(uid)) {
          await doc.reference.update({'editing.$uid': FieldValue.delete()});
        }
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

    final error = failure;
    if (error != null) throw error;
  }
}
