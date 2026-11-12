import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/cloud_consent.dart';

/// Who holds a room's widget-decorator edit lock right now.
///
/// Stored as `editLock` on the room membership document. Members already
/// listen to that doc, so showing who is locked costs no extra query. A
/// stamp older than [ttl] counts as gone, which covers an app that was
/// killed before it could clear its own.
class TogetherEditingPresence extends ChangeNotifier {
  static const ttl = Duration(seconds: 90);
  static const heartbeat = Duration(seconds: 60);

  final Map<String, ({String uid, String name, DateTime at})> _locks = {};
  Timer? _expiry;

  /// Someone else holding [roomId]'s edit lock right now, if anyone.
  ({String uid, String name})? lockHolder(String roomId) {
    final lock = _locks[roomId];
    if (lock == null || !_fresh(lock.at)) return null;
    if (lock.uid == FirebaseAuth.instance.currentUser?.uid) return null;
    return (uid: lock.uid, name: lock.name);
  }

  static bool _fresh(DateTime at) => DateTime.now().difference(at) < ttl;

  /// Called by the room watch with each membership snapshot.
  void applyDoc(String roomId, Map<String, dynamic> data) {
    final lock = _parseLock(data['editLock']);
    final prev = _locks[roomId];
    final same = prev?.uid == lock?.uid &&
        prev?.name == lock?.name &&
        prev?.at == lock?.at;
    if (same) return;
    if (lock == null) {
      _locks.remove(roomId);
    } else {
      _locks[roomId] = lock;
    }
    _scheduleExpiry();
    notifyListeners();
  }

  static ({String uid, String name, DateTime at})? _parseLock(Object? raw) {
    if (raw is! Map) return null;
    final uid = raw['uid']?.toString() ?? '';
    if (uid.isEmpty) return null;
    final at = raw['at'];
    return (
      uid: uid,
      name: raw['name']?.toString().trim() ?? '',
      // A just-written lock has no server time yet: it is fresh.
      at: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }

  /// Redraw when the oldest live lock runs out, so stale holders clear.
  void _scheduleExpiry() {
    _expiry?.cancel();
    DateTime? soonest;
    for (final lock in _locks.values) {
      if (!_fresh(lock.at)) continue;
      final end = lock.at.add(ttl);
      if (soonest == null || end.isBefore(soonest)) soonest = end;
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

  /// Takes (or renews) [roomId]'s edit lock so only one person decorates at
  /// a time. Returns who holds it instead when someone else's lock is still
  /// fresh ([ttl]); an expired lock (app killed, phone offline) is taken over.
  ///
  /// The read and the write happen in one transaction, so two friends opening
  /// the decorator together cannot both get it. When the lock cannot be
  /// checked at all (signed out, offline), editing is allowed rather than
  /// stranding the user.
  static Future<({bool ok, String holderName})> claimLock(
    String roomId, {
    required String myName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !CloudConsent.accepted) return (ok: true, holderName: '');
    final ref =
        FirebaseFirestore.instance.collection('dday_memberships').doc(roomId);
    try {
      return await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return (ok: true, holderName: '');
        final lock = _parseLock(snap.data()?['editLock']);
        if (lock != null && lock.uid != uid && _fresh(lock.at)) {
          return (ok: false, holderName: lock.name);
        }
        tx.update(ref, {
          'editLock': {
            'uid': uid,
            'name': myName,
            'at': FieldValue.serverTimestamp(),
          },
        });
        return (ok: true, holderName: '');
      });
    } catch (e) {
      debugPrint('TogetherEditingPresence.claimLock: $e');
      return (ok: true, holderName: '');
    }
  }

  /// Frees [roomId]'s edit lock if it is still mine.
  static Future<void> releaseLock(String roomId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !CloudConsent.accepted) return;
    final ref =
        FirebaseFirestore.instance.collection('dday_memberships').doc(roomId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final lock = _parseLock(snap.data()?['editLock']);
        if (lock?.uid != uid) return;
        tx.update(ref, {'editLock': FieldValue.delete()});
      });
    } catch (e) {
      debugPrint('TogetherEditingPresence.releaseLock: $e');
    }
  }
}

final togetherEditing = TogetherEditingPresence();
