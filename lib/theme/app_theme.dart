import 'package:flutter/material.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/visual_style_controller.dart';

abstract final class AppTheme {
  static ThemeData light(AppPalette palette) {
    final clean = visualStyleController.isClean;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor:
          clean ? const Color(0xFFF5F6F8) : AppColors.background,
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: base.textTheme.apply(
        // Clean: system sans. Pixel: Galmuri bitmap face.
        fontFamily: clean ? null : 'Galmuri',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            clean ? const Color(0xFFF5F6F8) : AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: clean ? 0 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(clean ? 18 : 10),
        ),
      ),
    );
  }

  /// Display/title style.
  static TextStyle get pixel {
    if (visualStyleController.isPixel) {
      return const TextStyle(
        fontFamily: 'PressStart2P',
        color: AppColors.ink,
        height: 1.4,
      );
    }
    return const TextStyle(
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      height: 1.3,
      letterSpacing: -0.3,
    );
  }

  static TextStyle get body {
    if (visualStyleController.isPixel) {
      return const TextStyle(
        fontFamily: 'Galmuri',
        color: AppColors.ink,
        height: 1.45,
      );
    }
    return const TextStyle(
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
      height: 1.5,
      letterSpacing: -0.1,
    );
  }
}
