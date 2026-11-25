import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/home_widget_sync.dart';

/// Saves a room's widget picture in Firestore (`widget_cards/{random id}`)
/// when someone edits the widget. The push carries the id; friends' iPhones
/// fetch the picture in the notification service extension and redraw the
/// widget without the app having to run. The Cloud Function removes the
/// room's previous card.
abstract final class WidgetCardUpload {
  /// Firestore allows up to 1 MiB per document.
  static const _maxBytes = 900000;

  /// The new card's id, or null when it could not be drawn or saved (the
  /// edit itself still goes through).
  static Future<String?> upload(String roomId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final png = await HomeWidgetSync.renderRoomCardPng(roomId);
      if (png == null || png.isEmpty || png.length > _maxBytes) return null;
      final id = _randomId();
      await FirebaseFirestore.instance
          .collection('widget_cards')
          .doc(id)
          .set({
            'roomId': roomId,
            'by': uid,
            'card': Blob(png),
            'at': FieldValue.serverTimestamp(),
            // Firestore TTL removes the card after about a week; the iPhone
            // fetches it within seconds of the notice.
            'expireAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 7)),
            ),
          })
          .timeout(const Duration(seconds: 10));
      return id;
    } catch (e) {
      debugPrint('widget card upload: $e');
      return null;
    }
  }

  /// 40 hex characters: not guessable, so a get by id can stay open.
  static String _randomId() {
    final rnd = Random.secure();
    return List.generate(
      20,
      (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
