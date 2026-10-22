import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_invite_repository.dart';
import 'package:quotation/data/home_widget_sync.dart';

/// Single cheer text for a Together room (one per room).
class TogetherCheer {
  const TogetherCheer({
    required this.text,
    this.authorUid,
    this.authorName,
    this.updatedAt,
  });

  final String text;
  final String? authorUid;
  final String? authorName;
  final DateTime? updatedAt;

  static TogetherCheer? fromMembership(Map<String, dynamic>? data) {
    if (data == null) return null;
    final text = (data['latestCheer'] as String?)?.trim() ?? '';
    if (text.isEmpty) return null;
    return TogetherCheer(
      text: text,
      authorUid: data['latestCheerAuthorUid'] as String?,
      authorName: data['latestCheerAuthorName'] as String?,
      updatedAt: (data['latestCheerAt'] as Timestamp?)?.toDate(),
    );
  }
}

class TogetherCheerPostResult {
  const TogetherCheerPostResult({required this.ok, this.errorCode});

  final bool ok;
  final String? errorCode;
}

/// One cheer message per room, stored on `dday_memberships/{roomId}`.
abstract final class TogetherCheerRepository {
  static final _db = FirebaseFirestore.instance;

  static Stream<TogetherCheer?> watch(String roomId) {
    return _db.collection('dday_memberships').doc(roomId).snapshots().map(
          (snap) => TogetherCheer.fromMembership(snap.data()),
        );
  }

  /// Replaces the room's single cheer text.
  static Future<TogetherCheerPostResult> save({
    required String roomId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const TogetherCheerPostResult(ok: false, errorCode: 'not_signed_in');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      return const TogetherCheerPostResult(ok: false, errorCode: 'invalid_text');
    }

    try {
      final roomMatches = ddayController.items.where((e) => e.id == roomId);
      final room = roomMatches.isEmpty ? null : roomMatches.first;
      if (room != null) {
        await DdayCloudSync.pushDday(room);
      }
      await DdayInviteRepository.ensureHostMembership(roomId);

      final now = FieldValue.serverTimestamp();
      final authorName = user.displayName?.trim();
      final payload = <String, dynamic>{
        'latestCheer': trimmed,
        'latestCheerAuthorUid': user.uid,
        'latestCheerAt': now,
        'updatedBy': user.uid,
        'updatedAt': now,
      };
      if (authorName != null && authorName.isNotEmpty) {
        payload['latestCheerAuthorName'] = authorName;
      } else {
        payload['latestCheerAuthorName'] = FieldValue.delete();
      }

      await _db.collection('dday_memberships').doc(roomId).set(
            payload,
            SetOptions(merge: true),
          );

      await ddayController.applyFriendsFromCloud(
        ddayId: roomId,
        friends: room?.friends ?? const [],
        cloudOwnerUid: room?.cloudOwnerUid,
        latestCheer: trimmed,
      );
      await HomeWidgetSync.syncDday();

      return const TogetherCheerPostResult(ok: true);
    } catch (e) {
      debugPrint('TogetherCheerRepository.save: $e');
      final msg = e.toString();
      if (msg.contains('permission-denied')) {
        return const TogetherCheerPostResult(
          ok: false,
          errorCode: 'permission',
        );
      }
      if (msg.contains('not_signed_in')) {
        return const TogetherCheerPostResult(
          ok: false,
          errorCode: 'not_signed_in',
        );
      }
      return const TogetherCheerPostResult(ok: false, errorCode: 'failed');
    }
  }
}
