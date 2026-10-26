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

  /// Photo picked from the device album. The file path is stored separately.
  static const albumId = 'album';

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
    TogetherBgTheme(
      id: 'widget_background3',
      assetPath: 'assets/images/widgetbackground/widget_background3.png',
    ),
    TogetherBgTheme(
      id: 'widget_background4',
      assetPath: 'assets/images/widgetbackground/widget_backgournd4.png',
    ),
  ];

  /// Picker shows transparent and the first photo only.
  static List<TogetherBgTheme> get choices => [all[0], all[1]];

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
