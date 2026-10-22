import 'package:flutter/foundation.dart';
import 'package:quotation/theme/visual_style_controller.dart';

/// Background images for the quote reader (3dept), keyed by visual style.
abstract final class QuoteBackgrounds {
  static const List<String> pixel = <String>[
    'assets/images/background/pixel/sky.png',
    'assets/images/background/pixel/noeul.png',
  ];

  static const List<String> clean = <String>[
    'assets/images/background/clean/clean_background.png',
    'assets/images/background/clean/clean_background2.png',
    'assets/images/background/clean/clean_background3.png',
    'assets/images/background/clean/clean_background4.png',
  ];

  static List<String> get current =>
      visualStyleController.isClean ? clean : pixel;

  /// User pick from the reader menu. Null keeps the daily rotation.
  static final ValueNotifier<String?> selected = ValueNotifier<String?>(null);

  /// Picks one asset from the active style set (stable for [seed]).
  static String assetFor({int seed = 0}) {
    final list = current;
    final picked = selected.value;
    if (picked != null && list.contains(picked)) return picked;
    return list[seed.abs() % list.length];
  }
}
