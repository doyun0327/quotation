import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/dday_invite_repository.dart';

class TogetherCheer {
  const TogetherCheer({
    required this.id,
    required this.authorUid,
    required this.text,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String authorUid;
  final String text;
  final DateTime createdAt;
  final String? authorName;

  factory TogetherCheer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TogetherCheer(
      id: doc.id,
      authorUid: data['authorUid'] as String? ?? '',
      text: (data['text'] as String? ?? '').trim(),
      authorName: data['authorName'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Cheer messages for a Together room (backed by ddayId membership).
abstract final class TogetherCheerRepository {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _cheers(String roomId) =>
      _db.collection('dday_memberships').doc(roomId).collection('cheers');

  static Stream<List<TogetherCheer>> watch(String roomId) {
    return _cheers(roomId)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(TogetherCheer.fromDoc)
              .where((c) => c.text.isNotEmpty)
              .toList(),
        );
  }

  static Future<bool> post({
    required String roomId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 80) return false;

    try {
      try {
        await DdayInviteRepository.ensureHostMembership(roomId);
      } catch (_) {
        // Guests already have membership; ignore not_host.
      }
      final now = FieldValue.serverTimestamp();
      final authorName = user.displayName?.trim();
      await _cheers(roomId).add({
        'authorUid': user.uid,
        'authorName': (authorName == null || authorName.isEmpty)
            ? null
            : authorName,
        'text': trimmed,
        'createdAt': now,
      });
      await _db.collection('dday_memberships').doc(roomId).set(
        {
          'latestCheer': trimmed,
          'latestCheerAuthorUid': user.uid,
          'latestCheerAuthorName': (authorName == null || authorName.isEmpty)
              ? null
              : authorName,
          'latestCheerAt': now,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('TogetherCheerRepository.post: $e');
      return false;
    }
  }
}
