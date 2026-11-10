import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotation/data/together_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// People the user blocked on this device, plus what is hidden because of that.
class BlockedUsersController extends ChangeNotifier {
  static const _uidKey = 'blocked_user_uids';
  static const _cheerKey = 'blocked_cheer_texts';
  static const _bubbleKeyName = 'hidden_bubble_keys';

  final Set<String> _hiddenBubbles = {};
  final Set<String> _uids = {};
  final Map<String, String> _hiddenCheers = {};
  bool _ready = false;

  bool get ready => _ready;

  bool isBlocked(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    return _uids.contains(uid);
  }

  bool hidesCheer({
    required String roomId,
    String? text,
    String? authorUid,
  }) {
    if (isBlocked(authorUid)) return true;
    final saved = _hiddenCheers[roomId];
    final trimmed = text?.trim() ?? '';
    return saved != null && saved.isNotEmpty && saved == trimmed;
  }

  /// Empty when the cheer should stay off this device.
  String visibleCheer(String roomId, String? text, {String? authorUid}) {
    final trimmed = text?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    if (hidesCheer(roomId: roomId, text: trimmed, authorUid: authorUid)) {
      return '';
    }
    return trimmed;
  }

  static String _bubbleKey(String roomId, TogetherBubble bubble) =>
      '$roomId|${bubble.id}|${bubble.text}';

  /// Bubbles to draw on this device. They stay in the shared layout, so
  /// hiding one here never removes it for the rest of the room.
  List<TogetherBubble> visibleBubbles(
    String roomId,
    List<TogetherBubble> bubbles,
  ) {
    return [
      for (final bubble in bubbles)
        if (!isBlocked(bubble.authorUid) &&
            !_hiddenBubbles.contains(_bubbleKey(roomId, bubble)))
          bubble,
    ];
  }

  Future<void> hideBubble(String roomId, TogetherBubble bubble) async {
    _hiddenBubbles.add(_bubbleKey(roomId, bubble));
    await _save();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _uids
      ..clear()
      ..addAll(prefs.getStringList(_uidKey) ?? const []);
    _hiddenBubbles
      ..clear()
      ..addAll(prefs.getStringList(_bubbleKeyName) ?? const []);
    _hiddenCheers.clear();
    final raw = prefs.getString(_cheerKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final text = entry.value?.toString() ?? '';
            if (text.isNotEmpty) {
              _hiddenCheers[entry.key.toString()] = text;
            }
          }
        }
      } catch (_) {}
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> block({
    required String uid,
    String? roomId,
    String? cheerText,
    String? cheerAuthorUid,
  }) async {
    if (uid.isEmpty) return;
    _uids.add(uid);
    final text = cheerText?.trim() ?? '';
    if (roomId != null &&
        roomId.isNotEmpty &&
        text.isNotEmpty &&
        (cheerAuthorUid == null || cheerAuthorUid.isEmpty || cheerAuthorUid == uid)) {
      _hiddenCheers[roomId] = text;
    }
    await _save();
    notifyListeners();
  }

  Future<void> hideCheer({
    required String roomId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (roomId.isEmpty || trimmed.isEmpty) return;
    _hiddenCheers[roomId] = trimmed;
    await _save();
    notifyListeners();
  }

  Future<void> unblock(String uid) async {
    if (uid.isEmpty) return;
    _uids.remove(uid);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_uidKey, _uids.toList());
    await prefs.setStringList(_bubbleKeyName, _hiddenBubbles.toList());
    await prefs.setString(_cheerKey, jsonEncode(_hiddenCheers));
  }
}

final blockedUsersController = BlockedUsersController();
