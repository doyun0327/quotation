import 'package:flutter/material.dart';

/// Background themes for the Together home widget (image assets).
class TogetherBgTheme {
  const TogetherBgTheme({
    required this.id,
    required this.assetPath,
  });

  final String id;

  /// Empty = transparent / no image.
  final String assetPath;

  bool get isNone => assetPath.isEmpty;

  /// iPhone “투명” stand-in: frosted glass fill baked into the widget PNG
  /// (wallpaper cannot show through; Color.clear becomes a white plate).
  static const iosGlassFill = Color(0x72EEF1F5);

  /// Light edge highlight for the glass fill.
  static const iosGlassHighlight = Color(0x55FFFFFF);

  /// Cool shade so the glass reads as translucent, not paper white.
  static const iosGlassShade = Color(0x2894A0B0);

  /// iPhone, no home-screenshot registered: the pastel PNGs are mostly
  /// see-through, so a glass plate behind them looked white. The widget draws
  /// this soft base color instead. Null for every other theme.
  static const _iosPastelTints = <String, String>{
    'pastel_1': 'E3EBF3',
    'pastel_2': 'F6D9E4',
    'pastel_3': 'FCE6E6',
    'pastel_4': 'EFEEEE',
    'pastel_5': 'EBF4FD',
    'pastel_6': 'F0F8FD',
    'pastel_7': 'D7E5D1',
    'pastel_8': 'F1EFF3',
    'pastel_9': 'F4EED6',
    'pastel_10': 'DFE9D6',
  };

  static String? iosPastelTint(String? themeId) => _iosPastelTints[themeId];

  /// Photo picked from the device album. The file path is stored separately.
  static const albumId = 'album';

  static const none = TogetherBgTheme(id: 'none', assetPath: '');

  /// Themes from [assets/images/widgetbackground/].
  static final all = <TogetherBgTheme>[
    none,
    // Pastel first, right after the sticker tiles (see TogetherSticker).
    // Airplane (pastel_1) sits right after the four-leaf clover (pastel_7).
    // Picker: 1 transparent, 2 bubble, 3-5 stickers, then pastel_2 (6th)
    // and pastel_3 (7th); the rest follow.
    for (final i in const [2, 3, 4, 5, 6, 7, 1, 8, 9, 10])
      TogetherBgTheme(
        id: 'pastel_$i',
        assetPath: 'assets/images/widgetbackground/widget_pastel_$i.png',
      ),
    TogetherBgTheme(
      id: 'widget_background',
      assetPath: 'assets/images/widgetbackground/widget_background.png',
    ),
    TogetherBgTheme(
      id: 'widget_background2',
      assetPath: 'assets/images/widgetbackground/widget_background2.png',
    ),
    TogetherBgTheme(
      id: 'widget_background6',
      assetPath: 'assets/images/widgetbackground/background6.png',
    ),
    TogetherBgTheme(
      id: 'widget_background7',
      assetPath: 'assets/images/widgetbackground/background7.png',
    ),
    TogetherBgTheme(
      id: 'widget_background8',
      assetPath: 'assets/images/widgetbackground/background8.png',
    ),
    TogetherBgTheme(
      id: 'widget_background10',
      assetPath: 'assets/images/widgetbackground/widget_background10.png',
    ),
    TogetherBgTheme(
      id: 'background11',
      assetPath: 'assets/images/widgetbackground/background11.png',
    ),
    TogetherBgTheme(
      id: 'background13',
      assetPath: 'assets/images/widgetbackground/backgroudn13.png',
    ),
    TogetherBgTheme(
      id: 'back_gr',
      assetPath: 'assets/images/widgetbackground/back_gr.png',
    ),
    for (var i = 1; i <= 9; i++)
      TogetherBgTheme(
        id: 'background_final_$i',
        assetPath: 'assets/images/widgetbackground/background_final ($i).png',
      ),
    const TogetherBgTheme(
      id: 'background_final_10',
      assetPath: 'assets/images/widgetbackground/background_final(10).png',
    ),
  ];

  /// Picker shows transparent plus every bundled photo.
  static List<TogetherBgTheme> get choices => all;

  /// Picker order: transparent first, then either the paid pastel set before
  /// the free backgrounds ([pastelFirst]: subscribers and the free trial) or
  /// after them (everyone else, so the free ones come first). Each group
  /// keeps its own order.
  static List<TogetherBgTheme> ordered({required bool pastelFirst}) {
    final pastel = [
      for (final t in all)
        if (!t.isNone && requiresPremium(t)) t,
    ];
    final free = [
      for (final t in all)
        if (!t.isNone && !requiresPremium(t)) t,
    ];
    return [none, ...(pastelFirst ? [...pastel, ...free] : [...free, ...pastel])];
  }

  /// Only the pastel set is paid: airplane (pastel_1), the four hearts
  /// (2-5), cloud (6), four-leaf clover (7), rainbow (8) and the two buses
  /// (9, 10). Every other background is free for good, also once the free
  /// trial is over. By id, so reordering the picker never changes what is
  /// locked.
  static bool requiresPremium(TogetherBgTheme theme) =>
      theme.id.startsWith('pastel_');

  static TogetherBgTheme byId(String? id) {
    if (id == null || id.isEmpty) return none;
    if (id == albumId) return const TogetherBgTheme(id: albumId, assetPath: '');
    for (final t in all) {
      if (t.id == id) return t;
    }
    // Legacy: treat unknown as none.
    return none;
  }
}
