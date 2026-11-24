import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What happened to each Together push on this phone, kept in app storage so
/// it can be read later without a cable: Settings → long-press the title.
/// No entries after a friend's edit means iOS never woke the app for it.
abstract final class PushTrace {
  static const _key = 'push_trace_log';
  static const _max = 80;

  /// Writes run one after another: callers do not await, and two
  /// read-append-write rounds at once would drop a line.
  static Future<void> _queue = Future.value();

  static Future<void> add(String text) {
    debugPrint('DEARLY_PUSH $text');
    final stamp = DateTime.now();
    return _queue = _queue.then((_) => _append(text, stamp));
  }

  static Future<void> _append(String text, DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final lines = prefs.getStringList(_key) ?? <String>[];
      String two(int v) => v.toString().padLeft(2, '0');
      lines.add(
        '${two(now.month)}/${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)} $text',
      );
      if (lines.length > _max) lines.removeRange(0, lines.length - _max);
      await prefs.setStringList(_key, lines);
    } catch (_) {}
  }

  static Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getStringList(_key) ?? const <String>[];
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
