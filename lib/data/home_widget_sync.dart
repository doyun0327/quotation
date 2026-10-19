import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';

/// Mirrors the home-screen speech-bubble quote + theme onto the Android widget.
abstract final class HomeWidgetSync {
  static const androidProviderName = 'DailyWordWidgetProvider';
  static const androidDdayProviderName = 'DdayWidgetProvider';

  static const keyQuoteId = 'quoteId';
  static const keyQuoteText = 'quoteText';
  static const keyAuthor = 'author';
  static const keyCategoryId = 'categoryId';
  static const keyCategoryTitle = 'categoryTitle';
  static const keyQuotePool = 'quotePool';
  static const keyThemeAccent = 'themeAccent';
  static const keyThemeBorder = 'themeBorder';
  static const keyThemeWindowBar = 'themeWindowBar';
  static const keyDdayTitle = 'ddayTitle';
  static const keyDdayLabel = 'ddayLabel';
  static const keyDdayDate = 'ddayDate';
  static const keyDdayIconId = 'ddayIconId';
  static const keyDdayCharMe = 'ddayCharMe';
  static const keyDdayCharFriend = 'ddayCharFriend';
  static const keyDdayDuoPose = 'ddayDuoPose';
  static const keyDdayMeOffsetX = 'ddayMeOffsetX';
  static const keyDdayMeOffsetY = 'ddayMeOffsetY';
  static const keyDdayFriendOffsetX = 'ddayFriendOffsetX';
  static const keyDdayFriendOffsetY = 'ddayFriendOffsetY';
  static const keyVisualStyle = 'visualStyle';
  static const keyCharacterId = 'characterId';

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
      await syncDday();
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
      await _saveCharacter();
      await HomeWidget.updateWidget(
        name: androidProviderName,
        androidName: androidProviderName,
      );
    } catch (_) {
      // Ignore when widget is unavailable.
    }
  }

  static Future<void> syncCharacter() async {
    if (!_isAndroid) return;
    try {
      await _saveCharacter();
      await HomeWidget.updateWidget(
        name: androidProviderName,
        androidName: androidProviderName,
      );
      // D-Day widget also shows my character.
      await syncDday();
    } catch (_) {}
  }

  static Future<void> _saveCharacter() async {
    await HomeWidget.saveWidgetData<String>(
      keyCharacterId,
      characterController.character.id,
    );
  }

  static Future<void> syncDday() async {
    if (!_isAndroid) return;
    try {
      // Pick up offsets changed from the home-widget ⚙ screen.
      await ddayController.reloadOffsetsFromPrefs();
      await _saveDday();
      await HomeWidget.updateWidget(
        name: androidDdayProviderName,
        androidName: androidDdayProviderName,
      );
    } catch (_) {}
  }

  static Future<void> _saveDday() async {
    final item = ddayController.widgetDday;
    final meId = characterController.character.id;
    await HomeWidget.saveWidgetData<String>(
      keyVisualStyle,
      visualStyleController.style.id,
    );
    await HomeWidget.saveWidgetData<int>(
      keyDdayMeOffsetX,
      ddayController.duoMeOffsetX,
    );
    await HomeWidget.saveWidgetData<int>(
      keyDdayMeOffsetY,
      ddayController.duoMeOffsetY,
    );
    await HomeWidget.saveWidgetData<int>(
      keyDdayFriendOffsetX,
      ddayController.duoFriendOffsetX,
    );
    await HomeWidget.saveWidgetData<int>(
      keyDdayFriendOffsetY,
      ddayController.duoFriendOffsetY,
    );
    if (item == null) {
      await HomeWidget.saveWidgetData<String>(keyDdayTitle, '');
      await HomeWidget.saveWidgetData<String>(keyDdayLabel, '');
      await HomeWidget.saveWidgetData<String>(keyDdayDate, '');
      await HomeWidget.saveWidgetData<String>(keyDdayIconId, '');
      await HomeWidget.saveWidgetData<String>(keyDdayCharMe, meId);
      await HomeWidget.saveWidgetData<String>(keyDdayCharFriend, '');
      await HomeWidget.saveWidgetData<String>(keyDdayDuoPose, 'handhold');
      return;
    }
    final cheer = item.latestCheer?.trim();
    final label = (cheer != null && cheer.isNotEmpty)
        ? cheer
        : (localeController.isKorean ? '같이' : 'Together');
    final subtitle = item.hasFriend
        ? (localeController.isKorean
            ? '친구 ${item.friendCount}명과 함께'
            : 'With ${item.friendCount} friends')
        : (localeController.isKorean ? '친구를 초대해 보세요' : 'Invite a friend');
    await HomeWidget.saveWidgetData<String>(keyDdayTitle, item.title);
    await HomeWidget.saveWidgetData<String>(keyDdayLabel, label);
    await HomeWidget.saveWidgetData<String>(keyDdayDate, subtitle);
    await HomeWidget.saveWidgetData<String>(keyDdayIconId, item.iconId);
    await HomeWidget.saveWidgetData<String>(keyDdayCharMe, meId);
    await HomeWidget.saveWidgetData<String>(
      keyDdayCharFriend,
      item.hasFriend ? (item.friendCharacterId ?? '').trim() : '',
    );
    await HomeWidget.saveWidgetData<String>(keyDdayDuoPose, 'handhold');
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
