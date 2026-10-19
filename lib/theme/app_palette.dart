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

  static const mint = AppPalette(
    id: 'mint',
    name: '민트',
    accent: Color(0xFF3CB8A0),
    accentSoft: Color(0xFFD5F3EC),
    border: Color(0xFFA9C7BF),
    windowBar: Color(0xFFB7E5DA),
    settingsLine: Color(0xFF5EBDA8),
    settingsSoft: Color(0xFFE4F7F2),
  );

  static const lavender = AppPalette(
    id: 'lavender',
    name: '라벤더',
    accent: Color(0xFF8B7BD8),
    accentSoft: Color(0xFFE7E2FA),
    border: Color(0xFFB8B0D4),
    windowBar: Color(0xFFD2CBF3),
    settingsLine: Color(0xFF9B8DE0),
    settingsSoft: Color(0xFFF1EDFC),
  );

  static const peach = AppPalette(
    id: 'peach',
    name: '피치',
    accent: Color(0xFFE8916A),
    accentSoft: Color(0xFFFFE4D8),
    border: Color(0xFFD4B3A4),
    windowBar: Color(0xFFF5CDBA),
    settingsLine: Color(0xFFE89A76),
    settingsSoft: Color(0xFFFFF0E9),
  );

  static const rose = AppPalette(
    id: 'rose',
    name: '로즈',
    accent: Color(0xFFD676A0),
    accentSoft: Color(0xFFF9DEE8),
    border: Color(0xFFD0A8B8),
    windowBar: Color(0xFFF0C4D4),
    settingsLine: Color(0xFFD88AAB),
    settingsSoft: Color(0xFFFCECF2),
  );

  static const all = <AppPalette>[sky, mint, lavender, peach, rose];

  static AppPalette byId(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => sky);
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
      Theme.of(this).extension<AppPalette>() ?? AppPalette.sky;
}
