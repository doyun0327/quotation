import 'package:flutter/foundation.dart';
import 'package:quotation/theme/app_palette.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({AppPalette? initial}) : _palette = initial ?? AppPalette.sky;

  AppPalette _palette;

  AppPalette get palette => _palette;

  void setPalette(AppPalette palette) {
    if (_palette.id == palette.id) return;
    _palette = palette;
    notifyListeners();
  }

  void setById(String id) => setPalette(AppPalette.byId(id));
}

final themeController = ThemeController();

