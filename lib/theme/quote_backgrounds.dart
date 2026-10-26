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

  static String assetFor() {
    final picked = selected.value;
    if (picked != null && clean.contains(picked)) return picked;
    return defaultAsset;
  }
}
