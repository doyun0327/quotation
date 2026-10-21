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

  static const none = TogetherBgTheme(id: 'none', assetPath: '');

  /// Themes from [assets/images/widgetbackground/].
  static const all = <TogetherBgTheme>[
    none,
    TogetherBgTheme(
      id: 'widget_background',
      assetPath: 'assets/images/widgetbackground/widget_background.png',
    ),
    TogetherBgTheme(
      id: 'widget_background2',
      assetPath: 'assets/images/widgetbackground/widget_background2.png',
    ),
  ];

  static TogetherBgTheme byId(String? id) {
    if (id == null || id.isEmpty) return none;
    for (final t in all) {
      if (t.id == id) return t;
    }
    // Legacy: treat unknown as none.
    return none;
  }
}
