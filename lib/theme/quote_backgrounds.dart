import 'package:flutter/foundation.dart';

/// Quote reader backgrounds. Always the clean set, in either visual style.
abstract final class QuoteBackgrounds {
  static const defaultAsset =
      'assets/images/background/clean/default_background.png';

  static const List<String> clean = <String>[
    defaultAsset,
    'assets/images/background/clean/clean_background.png',
    'assets/images/background/clean/clean_background2.png',
    'assets/images/background/clean/clean_background3.png',
    'assets/images/background/clean/clean_background4.png',
  ];

  static List<String> get current => clean;

  /// User pick from the reader menu. Null uses [defaultAsset].
  static final ValueNotifier<String?> selected = ValueNotifier<String?>(null);

  /// Themes whose recoloured clouds ship in `clean/themed/`. Sky (blue) is
  /// the original drawing.
  static const _themedClouds = {'black', 'green', 'pink', 'yellow', 'ivory'};

  /// The file to draw for [asset]: the cloud background follows the theme
  /// colour; photo backgrounds are shown as they are.
  static String displayAsset(String asset, String paletteId) {
    if (asset != defaultAsset || !_themedClouds.contains(paletteId)) return asset;
    return 'assets/images/background/clean/themed/default_background_$paletteId.png';
  }

  static String assetFor() {
    final picked = selected.value;
    if (picked != null && clean.contains(picked)) return picked;
    return defaultAsset;
  }
}
