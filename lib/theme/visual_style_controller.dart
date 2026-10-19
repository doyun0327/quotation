import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VisualStyle {
  pixel(id: 'pixel'),
  clean(id: 'clean');

  const VisualStyle({required this.id});

  final String id;

  static VisualStyle byId(String id) {
    return VisualStyle.values.firstWhere(
      (style) => style.id == id,
      orElse: () => VisualStyle.pixel,
    );
  }
}

class VisualStyleController extends ChangeNotifier {
  VisualStyleController({VisualStyle? initial})
      : _style = initial ?? VisualStyle.pixel;

  static const _prefsKey = 'visual_style';

  VisualStyle _style;

  VisualStyle get style => _style;
  bool get isPixel => _style == VisualStyle.pixel;
  bool get isClean => _style == VisualStyle.clean;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return;
    final next = VisualStyle.byId(saved);
    if (next == _style) return;
    _style = next;
    notifyListeners();
  }

  Future<void> setStyle(VisualStyle style) async {
    if (_style == style) return;
    _style = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, style.id);
  }
}

final visualStyleController = VisualStyleController();
