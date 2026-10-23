import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gallery photo used as a Together widget background. Stored on this device only.
class WidgetAlbumBackground {
  static const _prefsKey = 'widget_album_backgrounds';
  static final Map<String, String> _paths = {};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _paths.clear();
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    decoded.forEach((key, value) {
      if (key is String && value is String && value.isNotEmpty) {
        _paths[key] = value;
      }
    });
  }

  static String? pathFor(String roomId) {
    final path = _paths[roomId];
    if (path == null || path.isEmpty) return null;
    if (!File(path).existsSync()) return null;
    return path;
  }

  /// Asset path for a bundled theme, or the saved album file for [roomId].
  static String? resolvedAsset({
    required String themeId,
    required String roomId,
  }) {
    if (themeId == TogetherBgTheme.albumId) return pathFor(roomId);
    final theme = TogetherBgTheme.byId(themeId);
    return theme.isNone ? null : theme.assetPath;
  }

  static Future<String?> save(String roomId, XFile source) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/widget_backgrounds');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final safe = roomId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = File('${folder.path}/${safe}_$stamp.jpg');
    await dest.writeAsBytes(await source.readAsBytes(), flush: true);
    final previous = _paths[roomId];
    _paths[roomId] = dest.path;
    if (previous != null && previous != dest.path) {
      try {
        final old = File(previous);
        if (old.existsSync()) old.deleteSync();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_paths));
    return dest.path;
  }
}
