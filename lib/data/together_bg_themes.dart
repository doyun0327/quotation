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
    TogetherBgTheme(
      id: 'widget_background5',
      assetPath: 'assets/images/widgetbackground/widget_background5.png',
    ),
    TogetherBgTheme(
      id: 'widget_background6',
      assetPath: 'assets/images/widgetbackground/widget_background6.png',
    ),
    TogetherBgTheme(
      id: 'widget_background7',
      assetPath: 'assets/images/widgetbackground/widget_background7.png',
    ),
    TogetherBgTheme(
      id: 'widget_background8',
      assetPath: 'assets/images/widgetbackground/widget_background8.png',
    ),
    TogetherBgTheme(
      id: 'widget_background9',
      assetPath: 'assets/images/widgetbackground/widget_background9.png',
    ),
    TogetherBgTheme(
      id: 'widget_background10',
      assetPath: 'assets/images/widgetbackground/widget_background10.png',
    ),
  ];

  /// Picker shows transparent plus every bundled photo.
  static List<TogetherBgTheme> get choices => all;

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
