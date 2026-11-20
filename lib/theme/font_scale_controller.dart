import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontScaleOption {
  small(id: 'small', name: '작게', scale: 0.9, sampleSize: 12),
  medium(id: 'medium', name: '보통', scale: 1.0, sampleSize: 14),
  large(id: 'large', name: '크게', scale: 1.15, sampleSize: 16),
  xLarge(id: 'xlarge', name: '더 크게', scale: 1.3, sampleSize: 18);

  const FontScaleOption({
    required this.id,
    required this.name,
    required this.scale,
    required this.sampleSize,
  });

  final String id;
  final String name;
  final double scale;
  final double sampleSize;

  static FontScaleOption byId(String id) {
    return FontScaleOption.values.firstWhere(
      (option) => option.id == id,
      orElse: () => FontScaleOption.small,
    );
  }
}

class FontScaleController extends ChangeNotifier {
  FontScaleController({FontScaleOption? initial})
      : _option = initial ?? FontScaleOption.small;

  static const _prefsKey = 'font_scale_option';

  FontScaleOption _option;

  FontScaleOption get option => _option;
  double get scale => _option.scale;

  /// The size picked in Settings, kept across app restarts.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == null) return;
      final next = FontScaleOption.byId(saved);
      if (next == _option) return;
      _option = next;
      notifyListeners();
    } catch (_) {
      // Unreadable prefs: keep the default size.
    }
  }

  void setOption(FontScaleOption option) {
    if (_option == option) return;
    _option = option;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_prefsKey, option.id))
        .catchError((Object _) => false);
  }

  void setById(String id) => setOption(FontScaleOption.byId(id));
}

final fontScaleController = FontScaleController();
