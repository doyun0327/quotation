import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/theme_controller.dart';

/// Mirrors the home-screen speech-bubble quote + theme onto the Android widget.
abstract final class HomeWidgetSync {
  static const androidProviderName = 'DailyWordWidgetProvider';

  static const keyQuoteId = 'quoteId';
  static const keyQuoteText = 'quoteText';
  static const keyAuthor = 'author';
  static const keyCategoryId = 'categoryId';
  static const keyCategoryTitle = 'categoryTitle';
  static const keyQuotePool = 'quotePool';
  static const keyThemeAccent = 'themeAccent';
  static const keyThemeBorder = 'themeBorder';
  static const keyThemeWindowBar = 'themeWindowBar';

  static Future<void> initialize() async {
    if (!_isAndroid) return;

    try {
      final preferred = await HomeWidget.getWidgetData<String>(keyCategoryId);
      if (preferred != null &&
          preferred.isNotEmpty &&
          preferred != 'follow_app' &&
          preferred != selectionController.mainCategoryId) {
        selectionController.selectMainCategory(preferred);
      }
      await syncFromHome();
    } catch (_) {
      // Widget sync is best-effort; never block app start.
    }
  }

  static Future<void> syncFromHome() async {
    if (!_isAndroid) return;

    final quote = selectionController.bubbleQuote ??
        const Quote(id: 'fallback', text: '오늘도 잘하고 있어.');
    final categoryId = selectionController.mainCategoryId;
    final categoryTitle = AppStrings.current.mainCategoryTitle(categoryId);
    final palette = themeController.palette;
    final poolTexts = selectionController.bubblePoolQuotes
        .map((q) => q.text.trim())
        .where((t) => t.isNotEmpty)
        .take(160)
        .toList(growable: false);

    try {
      await HomeWidget.saveWidgetData<String>(keyQuoteId, quote.id);
      await HomeWidget.saveWidgetData<String>(keyQuoteText, quote.text);
      await HomeWidget.saveWidgetData<String>(keyAuthor, quote.author);
      await HomeWidget.saveWidgetData<String>(keyCategoryId, categoryId);
      await HomeWidget.saveWidgetData<String>(keyCategoryTitle, categoryTitle);
      await HomeWidget.saveWidgetData<String>(
        keyQuotePool,
        jsonEncode(poolTexts),
      );
      await _saveTheme(palette);
      await HomeWidget.updateWidget(
        name: androidProviderName,
        androidName: androidProviderName,
      );
    } catch (_) {
      // Ignore when widget is unavailable.
    }
  }

  static Future<void> syncThemeOnly() async {
    if (!_isAndroid) return;
    try {
      await _saveTheme(themeController.palette);
      await HomeWidget.updateWidget(
        name: androidProviderName,
        androidName: androidProviderName,
      );
    } catch (_) {}
  }

  static Future<void> _saveTheme(AppPalette palette) async {
    // Store as hex strings — Android SharedPreferences may widen Dart ints to Long.
    await HomeWidget.saveWidgetData<String>(
      keyThemeAccent,
      _hex(palette.accent),
    );
    await HomeWidget.saveWidgetData<String>(
      keyThemeBorder,
      _hex(palette.border),
    );
    await HomeWidget.saveWidgetData<String>(
      keyThemeWindowBar,
      _hex(palette.windowBar),
    );
  }

  static String _hex(Color color) {
    final a = (color.a * 255.0).round() & 0xff;
    final r = (color.r * 255.0).round() & 0xff;
    final g = (color.g * 255.0).round() & 0xff;
    final b = (color.b * 255.0).round() & 0xff;
    final value = (a << 24) | (r << 16) | (g << 8) | b;
    return value.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
