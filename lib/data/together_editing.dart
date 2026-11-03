import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/cloud_consent.dart';

/// Who has a room's widget decorator open right now.
///
/// Kept as `editing.{uid}` timestamps on the room's membership document,
/// which every member already listens to, so showing it costs no extra
/// listener or query: one write on open, one on close, and a heartbeat while
/// the screen stays open. A stamp older than [ttl] counts as gone, which
/// covers an app that was killed before it could clear its own.
class TogetherEditingPresence extends ChangeNotifier {
  static const ttl = Duration(seconds: 90);
  static const heartbeat = Duration(seconds: 60);

  final Map<String, Map<String, DateTime>> _byRoom = {};
  Timer? _expiry;

  /// Never true for me — only friends' editing is shown.
  bool isEditing(String roomId, String uid) {
    if (uid == FirebaseAuth.instance.currentUser?.uid) return false;
    final at = _byRoom[roomId]?[uid];
    return at != null && _fresh(at);
  }

  static bool _fresh(DateTime at) => DateTime.now().difference(at) < ttl;

  /// Called by the room watch with each membership snapshot.
  void applyDoc(String roomId, Map<String, dynamic> data) {
    final next = <String, DateTime>{};
    final raw = data['editing'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is Timestamp) next[entry.key.toString()] = value.toDate();
      }
    }
    if (mapEquals(_byRoom[roomId], next)) return;
    _byRoom[roomId] = next;
    _scheduleExpiry();
    notifyListeners();
  }

  /// Redraw when the oldest live stamp runs out, so stale dots clear.
  void _scheduleExpiry() {
    _expiry?.cancel();
    DateTime? soonest;
    for (final room in _byRoom.values) {
      for (final at in room.values) {
        if (!_fresh(at)) continue;
        final end = at.add(ttl);
        if (soonest == null || end.isBefore(soonest)) soonest = end;
      }
    }
    if (soonest == null) return;
    _expiry = Timer(
      soonest.difference(DateTime.now()) + const Duration(seconds: 1),
      () {
        _scheduleExpiry();
        notifyListeners();
      },
    );
  }

  /// Marks me as editing [roomId] (or clears it). Best effort: a failed
  /// write only means friends do not see the dots.
  static Future<void> write(String roomId, {required bool editing}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !CloudConsent.accepted) return;
    try {
      await FirebaseFirestore.instance
          .collection('dday_memberships')
          .doc(roomId)
          .update({
        'editing.$uid':
            editing ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('TogetherEditingPresence.write: $e');
    }
  }
}

final togetherEditing = TogetherEditingPresence();
