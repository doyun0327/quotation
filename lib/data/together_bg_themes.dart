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

  /// Backgrounds free users may pick. By id, so reordering the picker
  /// never locks a background someone already uses.
  static const freeIds = {
    'none',
    // pastel_1 (airplane) and pastel_5 (blue heart) are premium.
    'pastel_2',
    'pastel_3',
    'pastel_4',
    'widget_background',
    'widget_background2',
    'widget_background6',
  };

  static bool requiresPremium(TogetherBgTheme theme) =>
      !freeIds.contains(theme.id);

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
