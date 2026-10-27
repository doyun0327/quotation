import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// People the user blocked on this device, plus cheers hidden because of that.
class BlockedUsersController extends ChangeNotifier {
  static const _uidKey = 'blocked_user_uids';
  static const _cheerKey = 'blocked_cheer_texts';

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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _uids
      ..clear()
      ..addAll(prefs.getStringList(_uidKey) ?? const []);
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
    await prefs.setString(_cheerKey, jsonEncode(_hiddenCheers));
  }
}

final blockedUsersController = BlockedUsersController();
