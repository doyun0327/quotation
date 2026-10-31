import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Fonts offered for the Together home widget label.
///
/// [id] is stored per room and sent to Android, which loads [asset] from
/// `flutter_assets/` so the home widget draws the same glyphs as the preview.
/// Every bundled font is SIL Open Font License 1.1.
enum WidgetFont {
  /// Current style font: Galmuri for pixel, system bold for clean.
  basic(id: '', family: null, asset: null, license: null),
  jua(
    id: 'jua',
    family: 'Jua',
    asset: 'assets/fonts/Jua-Regular.ttf',
    license: 'assets/fonts/licenses/OFL-jua.txt',
  ),
  singleDay(
    id: 'singleday',
    family: 'SingleDay',
    asset: 'assets/fonts/SingleDay-Regular.ttf',
    license: 'assets/fonts/licenses/OFL-singleday.txt',
  ),
  gaegu(
    id: 'gaegu',
    family: 'Gaegu',
    asset: 'assets/fonts/Gaegu-Bold.ttf',
    license: 'assets/fonts/licenses/OFL-gaegu.txt',
  ),
  nanumPen(
    id: 'nanumpen',
    family: 'NanumPenScript',
    asset: 'assets/fonts/NanumPenScript-Regular.ttf',
    license: 'assets/fonts/licenses/OFL-nanumpenscript.txt',
  ),
  yeonSung(
    id: 'yeonsung',
    family: 'YeonSung',
    asset: 'assets/fonts/YeonSung-Regular.ttf',
    license: 'assets/fonts/licenses/OFL-yeonsung.txt',
  );

  const WidgetFont({
    required this.id,
    required this.family,
    required this.asset,
    required this.license,
  });

  final String id;

  /// Flutter font family from pubspec. Null keeps the style default.
  final String? family;
  final String? asset;
  final String? license;

  static WidgetFont byId(String? id) {
    for (final font in values) {
      if (font.id == id) return font;
    }
    return basic;
  }

  /// Adds the OFL texts to Flutter's license page.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final font in values) {
        final path = font.license;
        final family = font.family;
        if (path == null || family == null) continue;
        final text = await rootBundle.loadString(path);
        yield LicenseEntryWithLineBreaks([family], text);
      }
    });
  }
}
