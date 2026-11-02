import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-room prompts: invite, then decorate. Galaxy's first home apply
/// uses a different button label.
class TogetherGuide {
  TogetherGuide._();

  static const _invitedKey = 'together_guide_invited_rooms';
  static const _decoratedKey = 'together_guide_decorated_rooms';
  static const _exportedKey = 'together_galaxy_widget_exported';
  static const _channel = MethodChannel('com.quotation.quotation/widget_pin');

  static bool? _samsung;

  static Future<Set<String>> invitedRooms() => _read(_invitedKey);

  static Future<Set<String>> decoratedRooms() => _read(_decoratedKey);

  static Future<void> markInvited(String roomId) => _add(_invitedKey, roomId);

  static Future<void> markDecorated(String roomId) =>
      _add(_decoratedKey, roomId);

  static Future<bool> hasExportedWidget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_exportedKey) == true;
  }

  static Future<void> markExportedWidget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_exportedKey, true);
  }

  static Future<bool> isSamsung() async {
    final cached = _samsung;
    if (cached != null) return cached;
    if (!Platform.isAndroid) return _samsung = false;
    try {
      final value = await _channel.invokeMethod<bool>('isSamsungDevice');
      return _samsung = value == true;
    } catch (_) {
      return _samsung = false;
    }
  }

  static Future<Set<String>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key)?.toSet() ?? {};
  }

  static Future<void> _add(String key, String roomId) async {
    if (roomId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final next = prefs.getStringList(key)?.toSet() ?? {};
    if (!next.add(roomId)) return;
    await prefs.setStringList(key, next.toList());
  }
}
