import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/auth_controller.dart';

/// Reasons a reviewer or member can choose when reporting a Together cheer.
abstract final class SafetyReportReason {
  static const harassment = 'harassment';
  static const sexual = 'sexual';
  static const spam = 'spam';
  static const other = 'other';

  static const values = [harassment, sexual, spam, other];
}

class SafetyReportResult {
  const SafetyReportResult({required this.ok, this.errorCode});

  final bool ok;
  final String? errorCode;
}

/// Stores a report the operator can read in the Firebase console.
abstract final class SafetyReportRepository {
  static final _db = FirebaseFirestore.instance;

  static Future<SafetyReportResult> submit({
    required String roomId,
    required String reason,
    String? targetUid,
    String? targetName,
    String? contentText,
    String? note,
    required bool blockUser,
  }) async {
    if (!SafetyReportReason.values.contains(reason)) {
      return const SafetyReportResult(ok: false, errorCode: 'invalid');
    }
    final signedIn = await authController.ensureFirebaseSession();
    final user = FirebaseAuth.instance.currentUser;
    if (!signedIn || user == null) {
      return const SafetyReportResult(ok: false, errorCode: 'not_signed_in');
    }

    final text = (contentText ?? '').trim();
    final extra = (note ?? '').trim();
    try {
      await _db.collection('content_reports').add({
        'reporterUid': user.uid,
        'roomId': roomId,
        'reason': reason,
        'targetUid': (targetUid ?? '').trim(),
        'targetName': (targetName ?? '').trim(),
        'contentText': text.length > 500 ? text.substring(0, 500) : text,
        'note': extra.length > 300 ? extra.substring(0, 300) : extra,
        'blockRequested': blockUser,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const SafetyReportResult(ok: true);
    } catch (e) {
      debugPrint('SafetyReportRepository.submit: $e');
      return const SafetyReportResult(ok: false, errorCode: 'failed');
    }
  }
}
