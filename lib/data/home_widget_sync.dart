import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:quotation/data/together_cheer_layout.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';
/// Mirrors the home-screen speech-bubble quote + theme onto the Android widget.
abstract final class HomeWidgetSync {
  static const androidProviderName = 'DailyWordWidgetProvider';
  static const androidDdayProviderName = 'DdayWidgetProvider';

  /// Chip id → Android provider (3×3 / 4×2 / 4×3 / 3×2).
  static const _ddayProviders = <({String key, String name, String qualified})>[
    (
      key: 's33',
      name: 'DdayWidgetProviderSq',
      qualified: 'com.quotation.quotation.DdayWidgetProviderSq',
    ),
    (
      key: 's42',
      name: 'DdayWidgetProvider',
      qualified: 'com.quotation.quotation.DdayWidgetProvider',
    ),
    (
      key: 's43',
      name: 'DdayWidgetProviderXl',
      qualified: 'com.quotation.quotation.DdayWidgetProviderXl',
    ),
    (
      key: 's32',
      name: 'DdayWidgetProviderM',
      qualified: 'com.quotation.quotation.DdayWidgetProviderM',
    ),
    // Legacy receivers — still refresh if left on the home screen.
    (
      key: 'legacy_s',
      name: 'DdayWidgetProviderS',
      qualified: 'com.quotation.quotation.DdayWidgetProviderS',
    ),
    (
      key: 'legacy_tall',
      name: 'DdayWidgetProviderTall',
      qualified: 'com.quotation.quotation.DdayWidgetProviderTall',
    ),
  ];

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
  static const keyDdayTextOffsetX = 'ddayTextOffsetX';
  static const keyDdayTextOffsetY = 'ddayTextOffsetY';
  static const keyDdayCharScale = 'ddayCharScale';
  static const keyDdayFriendCharScale = 'ddayFriendCharScale';
  static const keyDdayTextScale = 'ddayTextScale';
  static const keyDdayBgColor = 'ddayBgColor';
  static const keyDdayBgOpacity = 'ddayBgOpacity';
  static const keyDdayBgTheme = 'ddayBgTheme';
  static const keyDdayBgAsset = 'ddayBgAsset';
  static const keyDdayTextColor = 'ddayTextColor';
  static const keyDdayShape = 'ddayShape';
  static const keyDdayWidgetSize = 'ddayWidgetSize';
  static const keyDdayScreenWidthDp = 'ddayScreenWidthDp';
  static const keyDdayHostWidthDp = 'ddayHostWidthDp';
  static const keyDdayHostHeightDp = 'ddayHostHeightDp';
  static const keyDdayHostWidthExact = 'ddayHostWidthExact';
  static const keyDdayHostHeightExact = 'ddayHostHeightExact';
  static const keyDdayHostSizeId = 'ddayHostSizeId';
  static const keyDdayHostCornerDp = 'ddayHostCornerDp';
  static const keyVisualStyle = 'visualStyle';
  static const keyCharacterId = 'characterId';
  static const _pinChannel = MethodChannel('com.quotation.quotation/widget_pin');

  /// Pin provider = size chip (default 3×2).
  static ({String key, String name, String qualified}) _providerForSize(
    TogetherWidgetSize size,
  ) {
    return _ddayProviders.firstWhere(
      (p) => p.key == size.id,
      orElse: () => _ddayProviders.firstWhere((p) => p.key == 's42'),
    );
  }

  static TogetherWidgetSize _currentWidgetSize() {
    return TogetherWidgetSize.s42;
  }

  static int _screenWidthDp() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 360;
    final view = views.first;
    final w = view.physicalSize.width / view.devicePixelRatio;
    if (w.isFinite && w > 0) return w.round();
    return 360;
  }

  /// Measured home-widget host size + corner (written by Android provider).
  static Future<({Size size, TogetherWidgetSize forSize, double cornerDp})?>
      loadHostPreviewSize() async {
    if (!_isAndroid) return null;
    try {
      final exactW = double.tryParse(
        await HomeWidget.getWidgetData<String>(keyDdayHostWidthExact) ?? '',
      );
      final exactH = double.tryParse(
        await HomeWidget.getWidgetData<String>(keyDdayHostHeightExact) ?? '',
      );
      final w = exactW ??
          (await HomeWidget.getWidgetData<int>(keyDdayHostWidthDp))?.toDouble();
      final h = exactH ??
          (await HomeWidget.getWidgetData<int>(keyDdayHostHeightDp))?.toDouble();
      final id = await HomeWidget.getWidgetData<String>(keyDdayHostSizeId);
      final corner = await HomeWidget.getWidgetData<int>(keyDdayHostCornerDp);
      if (w == null || h == null || w < 40 || h < 40) return null;
      final forSize = TogetherWidgetSize.byId(id);
      final screen = _screenWidthDp().toDouble();
      // Trust the launcher cell. A Pixel grid is not the Samsung 4×2 ratio.
      if (w > screen * 1.25 || h > screen * 1.5) return null;
      return (
        size: Size(w, h),
        forSize: forSize,
        cornerDp: (corner ?? TogetherWidgetSize.defaultCornerDp.toInt())
            .toDouble()
            .clamp(12.0, 40.0)
            .toDouble(),
      );
    } catch (e) {
      debugPrint('loadHostPreviewSize: $e');
      return null;
    }
  }

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

  static Future<void> syncDday({bool reloadFromPrefs = true}) async {
    if (!_isAndroid) return;
    try {
      // Pick up offsets changed from the home-widget ⚙ screen.
      if (reloadFromPrefs) {
        await ddayController.reloadOffsetsFromPrefs();
      }
      await _saveDday();
      await _updateAllDdayWidgets();
    } catch (_) {}
  }

  static Future<void> _updateAllDdayWidgets() async {
    for (final p in _ddayProviders) {
      try {
        await HomeWidget.updateWidget(
          name: p.name,
          androidName: p.name,
          qualifiedAndroidName: p.qualified,
        );
      } catch (_) {}
    }
  }

  /// Sync data to existing Together widgets. Only asks to pin when none are installed.
  /// Returns `true` when a pin request was shown; `false` when an existing widget was updated
  /// (or pin is unsupported).
  ///
  /// Pin dialog is shown ASAP (light preview). Heavy widget redraw runs in the background
  /// so "홈에 적용" no longer waits several seconds before the add sheet appears.
  static Future<bool> syncAndOfferPinTogetherWidget() async {
    if (!_isAndroid) return false;
    try {
      // Persist prefs first (fast) so a newly pinned widget has data.
      await _saveDday();

      final alreadyInstalled = await _hasTogetherWidgetInstalled();
      if (alreadyInstalled) {
        unawaited(syncDday(reloadFromPrefs: false));
        return false;
      }

      // Show add sheet immediately — do not wait for bitmap/font widget rebuild.
      final pinned = await _requestPinTogetherWidgetFast();
      unawaited(syncDday(reloadFromPrefs: false));
      return pinned;
    } catch (e) {
      debugPrint('syncAndOfferPinTogetherWidget: $e');
      return false;
    }
  }

  static Future<bool> _requestPinTogetherWidgetFast() async {
    final size = _currentWidgetSize();
    final provider = _providerForSize(size);
    try {
      final ok = await _pinChannel.invokeMethod<bool>(
        'pinTogetherWidget',
        <String, dynamic>{'size': size.id},
      );
      if (ok == true) return true;
    } catch (e) {
      debugPrint('pinTogetherWidget channel: $e');
    }
    try {
      final supported =
          await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) return false;
      await HomeWidget.requestPinWidget(
        name: provider.name,
        androidName: provider.name,
        qualifiedAndroidName: provider.qualified,
      );
      return true;
    } catch (e) {
      debugPrint('requestPinWidget: $e');
      return false;
    }
  }

  static Future<bool> _hasTogetherWidgetInstalled() async {
    final size = _currentWidgetSize();
    final provider = _providerForSize(size);
    final wanted = provider.qualified;
    final shortName = provider.name;
    try {
      final installed = await HomeWidget.getInstalledWidgets();
      for (final info in installed) {
        final className = info.androidClassName ?? '';
        if (className == wanted ||
            className.endsWith('.$shortName') ||
            className == shortName) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('getInstalledWidgets: $e');
    }
    return false;
  }

  static Future<void> _saveDday() async {
    final item = ddayController.widgetDday;
    final meId = characterController.character.id;
    final roomId = item?.id;
    final charScale =
        roomId == null ? 100 : ddayController.charScaleForRoom(roomId);
    final friendScale =
        roomId == null ? 100 : ddayController.friendScaleForRoom(roomId);
    final textScale =
        roomId == null ? 100 : ddayController.textScaleForRoom(roomId);
    final bgThemeId = roomId == null
        ? 'widget_background'
        : ddayController.bgThemeForRoom(roomId);
    final bgTheme = TogetherBgTheme.byId(bgThemeId);
    final textColor =
        roomId == null ? 0xFFF26B8A : ddayController.textColorForRoom(roomId);
    const shape = TogetherWidgetShape.square;
    final widgetSize = TogetherWidgetSize.s42;
    final textOffsetX =
        roomId == null ? 0 : ddayController.textOffsetXForRoom(roomId);
    final textOffsetY =
        roomId == null ? 0 : ddayController.textOffsetYForRoom(roomId);
    // Same screen width the app preview uses → identical cellDp on the home widget.
    await HomeWidget.saveWidgetData<int>(
      keyDdayScreenWidthDp,
      _screenWidthDp(),
    );
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
    await HomeWidget.saveWidgetData<int>(keyDdayTextOffsetX, textOffsetX);
    await HomeWidget.saveWidgetData<int>(keyDdayTextOffsetY, textOffsetY);
    await HomeWidget.saveWidgetData<int>(keyDdayCharScale, charScale);
    await HomeWidget.saveWidgetData<int>(keyDdayFriendCharScale, friendScale);
    await HomeWidget.saveWidgetData<int>(keyDdayTextScale, textScale);
    await HomeWidget.saveWidgetData<String>(keyDdayBgTheme, bgTheme.id);
    await HomeWidget.saveWidgetData<String>(
      keyDdayBgAsset,
      bgTheme.assetPath,
    );
    await HomeWidget.saveWidgetData<String>(
      keyDdayTextColor,
      _hex(Color(textColor)),
    );
    await HomeWidget.saveWidgetData<String>(keyDdayShape, shape.id);
    await HomeWidget.saveWidgetData<String>(keyDdayWidgetSize, widgetSize.id);
    if (item == null) {
      // Title/date kept empty — widget shows cheer text only.
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
    final rawLabel = (cheer != null && cheer.isNotEmpty) ? cheer : '';
    final host = await loadHostPreviewSize();
    final box = host?.size ?? widgetSize.homeSize(_screenWidthDp().toDouble());
    final corner = host?.cornerDp ?? TogetherWidgetSize.defaultCornerDp;
    final inner = TogetherCheerLayout.innerSize(box.width, box.height, corner);
    var label = rawLabel;
    try {
      label = TogetherCheerLayout.wrap(
        text: rawLabel,
        maxWidth: inner.width,
        isPixel: visualStyleController.isPixel,
        textScale: textScale.toDouble(),
      );
    } catch (e) {
      debugPrint('cheer wrap: $e');
      label = rawLabel;
    }
    await HomeWidget.saveWidgetData<String>(keyDdayTitle, '');
    await HomeWidget.saveWidgetData<String>(keyDdayLabel, label);
    await HomeWidget.saveWidgetData<String>(keyDdayDate, '');
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
