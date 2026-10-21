import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared room so two phones can test together without Google sign-in.
class TogetherTestRoom extends ChangeNotifier {
  TogetherTestRoom._();

  static const roomId = 'together-test-room';
  static const _enabledKey = 'together_test_room_enabled';
  static const _previousPinKey = 'together_test_room_previous_pin';

  bool _enabled = false;
  bool _busy = false;

  bool get enabled => _enabled;
  bool get busy => _busy;

  AppCharacter get friendCharacter {
    final rooms = ddayController.items.where((e) => e.id == roomId);
    if (rooms.isNotEmpty && rooms.first.friends.isNotEmpty) {
      final id = rooms.first.friends.first.characterId;
      if (id != 'local-friend') return AppCharacter.byId(id);
    }
    return placeholderFriend().characterId == 'bul'
        ? AppCharacter.bul
        : AppCharacter.basic;
  }

  static DdayFriendMember placeholderFriend() {
    final other = characterController.character == AppCharacter.basic
        ? AppCharacter.bul
        : AppCharacter.basic;
    return DdayFriendMember(
      uid: 'local-friend',
      characterId: other.id,
      displayName: '친구',
    );
  }

  Future<void> restoreIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_enabledKey) != true) return;
    await setEnabled(true);
  }

  Future<bool> setEnabled(bool on) async {
    if (_busy) return _enabled;
    _busy = true;
    notifyListeners();
    try {
      final ok = await authController.ensureAnonymous();
      if (!ok) return false;
      if (on) {
        await _join();
      } else {
        _enabled = false;
        await _leave();
      }
      _enabled = on;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, on);
      await HomeWidgetSync.syncDday();
      return true;
    } catch (e) {
      debugPrint('TogetherTestRoom.setEnabled: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _join() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final myChar = characterController.character.id;
    final db = FirebaseFirestore.instance;
    final ddayRef = db.collection('ddays').doc(roomId);
    final memberRef = db.collection('dday_memberships').doc(roomId);

    final ddaySnap = await ddayRef.get();
    if (!ddaySnap.exists) {
      await ddayRef.set({
        'ownerUid': uid,
        'title': 'Together',
        'targetDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'iconId': 'heart',
        'repeatYearly': false,
        'status': 'paired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await db.runTransaction((tx) async {
      final snap = await tx.get(memberRef);
      if (!snap.exists) {
        tx.set(memberRef, {
          'hostUid': uid,
          'hostCharacterId': myChar,
          'members': <Map<String, dynamic>>[],
          'guestUids': <String>[],
          'maxGuests': DdayInviteLimits.maxFriends,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      final data = snap.data() ?? {};
      final hostUid = data['hostUid'] as String? ?? '';
      if (hostUid == uid) {
        tx.set(
          memberRef,
          {
            'hostCharacterId': myChar,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }
      final members = (data['members'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      members.removeWhere((m) => m['uid'] == uid);
      members.add({
        'uid': uid,
        'characterId': myChar,
        'displayName': '친구',
      });
      tx.set(
        memberRef,
        {
          'members': members,
          'guestUids': members.map((m) => m['uid']).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    final prefs = await SharedPreferences.getInstance();
    final current = ddayController.widgetDday?.id;
    if (current != null && current != roomId) {
      await prefs.setString(_previousPinKey, current);
    }

    if (!ddayController.items.any((e) => e.id == roomId)) {
      await ddayController.upsertFromCloud(
        DdayItem(
          id: roomId,
          title: 'Together',
          targetDate: DateTime(2026, 1, 1),
          friends: [placeholderFriend()],
          pinnedForWidget: true,
        ),
      );
    }
    await ddayController.pinForWidget(roomId);
    _enabled = true;
    await DdayCloudSync.start();
  }

  Future<void> _leave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final ref = FirebaseFirestore.instance
          .collection('dday_memberships')
          .doc(roomId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data() ?? {};
        final hostUid = data['hostUid'] as String? ?? '';
        final members = (data['members'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (hostUid == uid) {
          if (members.isEmpty) {
            tx.delete(ref);
            return;
          }
          final next = members.removeAt(0);
          tx.set(ref, {
            'hostUid': next['uid'],
            'hostCharacterId': next['characterId'] ?? 'basic',
            'members': members,
            'guestUids': members.map((m) => m['uid']).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }
        members.removeWhere((m) => m['uid'] == uid);
        tx.set(
          ref,
          {
            'members': members,
            'guestUids': members.map((m) => m['uid']).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    }

    _enabled = false;
    if (ddayController.items.any((e) => e.id == roomId)) {
      await ddayController.remove(roomId);
    }
    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getString(_previousPinKey);
    if (prev != null && ddayController.items.any((e) => e.id == prev)) {
      await ddayController.pinForWidget(prev);
    }
  }
}

final togetherTestRoom = TogetherTestRoom._();
