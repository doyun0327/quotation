import 'package:flutter/material.dart';

/// Swappable accent palette. Neutrals stay in [AppColors].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.name,
    required this.accent,
    required this.accentSoft,
    required this.border,
    required this.windowBar,
    required this.settingsLine,
    required this.settingsSoft,
  });

  final String id;
  final String name;
  final Color accent;
  final Color accentSoft;
  final Color border;
  final Color windowBar;
  final Color settingsLine;
  final Color settingsSoft;

  /// Clean black-and-white — ink on white, no warm tint.
  static const black = AppPalette(
    id: 'black',
    name: '검정',
    accent: Color(0xFF000000),
    accentSoft: Color(0xFFF2F2F2),
    border: Color(0xFFC8C8C8),
    windowBar: Color(0xFFE6E6E6),
    settingsLine: Color(0xFF2A2A2A),
    settingsSoft: Color(0xFFF7F7F7),
  );

  /// The original sky blue (as of 2026-11-10 17:00, commit f8737b2).
  static const sky = AppPalette(
    id: 'sky',
    name: '하늘',
    accent: Color(0xFF5B8DEF),
    accentSoft: Color(0xFFD7E6FF),
    border: Color(0xFFB8C0CE),
    windowBar: Color(0xFFBFD4F5),
    settingsLine: Color(0xFF7EB3E8),
    settingsSoft: Color(0xFFE8F2FC),
  );

  static const green = AppPalette(
    id: 'green',
    name: '연두',
    accent: Color(0xFFB8D9A8),
    accentSoft: Color(0xFFF2F8EC),
    border: Color(0xFFD8E8D0),
    windowBar: Color(0xFFE4F0D8),
    settingsLine: Color(0xFFC0DCB0),
    settingsSoft: Color(0xFFF6FAF2),
  );

  /// Previous rose / pink set (before the 6-color swap).
  static const pink = AppPalette(
    id: 'pink',
    name: '분홍',
    accent: Color(0xFFE8A0C0),
    accentSoft: Color(0xFFFCEEF4),
    border: Color(0xFFE8CCD8),
    windowBar: Color(0xFFF5D8E4),
    settingsLine: Color(0xFFE8A8C4),
    settingsSoft: Color(0xFFFDF4F8),
  );

  static const yellow = AppPalette(
    id: 'yellow',
    name: '노랑',
    accent: Color(0xFFE8D48A),
    accentSoft: Color(0xFFFFF8E4),
    border: Color(0xFFE8DCB8),
    windowBar: Color(0xFFF5EAC0),
    settingsLine: Color(0xFFE8D890),
    settingsSoft: Color(0xFFFFFBF0),
  );

  static const ivory = AppPalette(
    id: 'ivory',
    name: '아이보리',
    accent: Color(0xFFE9DFC6),
    accentSoft: Color(0xFFFFFCF4),
    border: Color(0xFFE8E0CC),
    windowBar: Color(0xFFF4EEDD),
    settingsLine: Color(0xFFDCD0B4),
    settingsSoft: Color(0xFFFFFDF8),
  );

  static const all = <AppPalette>[
    black,
    green,
    pink,
    yellow,
    sky,
    ivory,
  ];

  static AppPalette byId(String id) {
    switch (id) {
      case 'blue':
        return sky;
      case 'navy':
      case 'lavender':
        return black;
      case 'mint':
        return green;
      case 'rose':
        return pink;
      case 'peach':
        return yellow;
    }
    return all.firstWhere((p) => p.id == id, orElse: () => pink);
  }

  @override
  AppPalette copyWith({
    String? id,
    String? name,
    Color? accent,
    Color? accentSoft,
    Color? border,
    Color? windowBar,
    Color? settingsLine,
    Color? settingsSoft,
  }) {
    return AppPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      border: border ?? this.border,
      windowBar: windowBar ?? this.windowBar,
      settingsLine: settingsLine ?? this.settingsLine,
      settingsSoft: settingsSoft ?? this.settingsSoft,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      id: t < 0.5 ? id : other.id,
      name: t < 0.5 ? name : other.name,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      windowBar: Color.lerp(windowBar, other.windowBar, t)!,
      settingsLine: Color.lerp(settingsLine, other.settingsLine, t)!,
      settingsSoft: Color.lerp(settingsSoft, other.settingsSoft, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.pink;
}
