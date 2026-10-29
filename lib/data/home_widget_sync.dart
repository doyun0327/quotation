import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/together_crowd_layout.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:quotation/data/widget_album_background.dart';
import 'package:quotation/data/together_cheer_layout.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';

/// Mirrors the home-screen character, date, and quote onto the Android widget.
abstract final class HomeWidgetSync {
  static const androidProviderName = 'DailyWordWidgetProvider';
  static const androidProviderQualified =
      'com.quotation.quotation.DailyWordWidgetProvider';
  static const androidDdayProviderQualified =
      'com.quotation.quotation.DdayWidgetProvider';

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
  static const keySubCategoryId = 'subCategoryId';
  static const keyCategoryTitle = 'categoryTitle';
  static const keyQuotePool = 'quotePool';
  static const keyThemeAccent = 'themeAccent';
  static const keyThemeBorder = 'themeBorder';
  static const keyThemeWindowBar = 'themeWindowBar';
  static const keyDdayRoomId = 'ddayRoomId';
  static const keyDdayRoomsJson = 'ddayRoomsJson';
  static const keyDdayWidgetBindings = 'ddayWidgetBindings';
  static const keyDdayPendingRoomId = 'ddayPendingRoomId';
  static const keyDdayKnownWidgetIds = 'ddayKnownWidgetIds';
  static const keyDdayLegacyRoomId = 'ddayLegacyRoomId';
  static const keyDdayHostByRoom = 'ddayHostByRoom';
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
      loadHostPreviewSize({String? roomId}) async {
    if (!_isAndroid) return null;
    try {
      if (roomId != null && roomId.isNotEmpty) {
        final forRoom = await _hostForRoom(roomId);
        if (forRoom != null) return forRoom;
      }
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
        Quote(
          id: 'greeting_today',
          text: AppStrings.current.homeGreeting,
        );
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
      await HomeWidget.saveWidgetData<String>(
        keySubCategoryId,
        selectionController.subCategoryId ?? '',
      );
      await HomeWidget.saveWidgetData<String>(keyCategoryTitle, categoryTitle);
      await HomeWidget.saveWidgetData<String>(
        keyQuotePool,
        jsonEncode(poolTexts),
      );
      await _saveTheme(palette);
      await _saveCharacter();
      await _pushCharacterWidget();
    } catch (_) {
      // Ignore when widget is unavailable.
    }
  }

  static Future<void> syncCharacter() async {
    if (!_isAndroid) return;
    try {
      await _saveCharacter();
      await _pushCharacterWidget();
      // Together widget also shows my character.
      await syncDday();
    } catch (_) {}
  }

  /// The widget class lives in `com.quotation.quotation`, not the application id.
  static Future<void> _pushCharacterWidget() async {
    try {
      await _pinChannel.invokeMethod<bool>('refreshCharacterWidget');
      return;
    } catch (e) {
      debugPrint('refreshCharacterWidget: $e');
    }
    try {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidProviderQualified,
      );
    } catch (e) {
      debugPrint('update character widget: $e');
    }
  }

  static Future<void> _pushTogetherWidget() async {
    try {
      await _pinChannel.invokeMethod<bool>('refreshTogetherWidget');
      return;
    } catch (e) {
      debugPrint('refreshTogetherWidget: $e');
    }
    try {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidDdayProviderQualified,
      );
    } catch (e) {
      debugPrint('update together widget: $e');
    }
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
      await _pushTogetherWidget();
    } catch (_) {}
  }

  /// Saves every room, then updates only the home widget for [roomId].
  /// A room that is not on the home screen yet gets its own widget.
  /// Widgets already on the home screen stay on their room.
  ///
  /// Returns `true` when the add-to-home sheet was shown.
  static Future<bool> syncAndOfferPinTogetherWidget({
    String? roomId,
    String? previousRoomId,
  }) async {
    if (!_isAndroid) return false;
    try {
      final id = roomId ?? ddayController.widgetDday?.id ?? '';
      final savedRoom =
          await HomeWidget.getWidgetData<String>(keyDdayRoomId) ?? '';
      final previous = previousRoomId?.trim() ?? '';
      final legacyRoom = savedRoom.isNotEmpty ? savedRoom : previous;
      final state = await _togetherWidgetState();
      final installed = state.ids;
      final bindings = state.bindings;
      final hasThisRoom =
          installed.any((widgetId) => bindings['$widgetId'] == id);
      if (id.isNotEmpty && !hasThisRoom) {
        _lockExistingWidgets(
          roomId: id,
          legacyRoom: legacyRoom,
          installed: installed,
          bindings: bindings,
        );
        await HomeWidget.saveWidgetData<String>(
          keyDdayWidgetBindings,
          jsonEncode(bindings),
        );
      }
      await HomeWidget.saveWidgetData<String>(
        keyDdayKnownWidgetIds,
        jsonEncode({
          for (final widgetId in installed) '$widgetId': true,
        }),
      );
      final kept = legacyRoom == id ? '' : legacyRoom;
      await HomeWidget.saveWidgetData<String>(keyDdayLegacyRoomId, kept);
      await _saveDday();
      if (id.isEmpty || _roomAlreadyPlaced(id, installed, bindings)) {
        await HomeWidget.saveWidgetData<String>(keyDdayPendingRoomId, '');
        await _pushTogetherWidget();
        return false;
      }
      await HomeWidget.saveWidgetData<String>(keyDdayPendingRoomId, id);
      await HomeWidget.saveWidgetData<String>(keyDdayRoomId, id);
      final pinned = await _requestPinTogetherWidgetFast();
      await _pushTogetherWidget();
      return pinned;
    } catch (e) {
      debugPrint('syncAndOfferPinTogetherWidget: $e');
      return false;
    }
  }

  /// Widgets already on the home screen keep the room they were showing.
  static void _lockExistingWidgets({
    required String roomId,
    required String legacyRoom,
    required List<int> installed,
    required Map<String, String> bindings,
  }) {
    final keep = legacyRoom.isNotEmpty && legacyRoom != roomId ? legacyRoom : '';
    if (keep.isEmpty) {
      if (legacyRoom == roomId) {
        final unbound = installed
            .where((widgetId) => (bindings['$widgetId'] ?? '').isEmpty)
            .toList();
        if (unbound.isNotEmpty) bindings['${unbound.first}'] = roomId;
      }
      return;
    }
    for (final widgetId in installed) {
      if ((bindings['$widgetId'] ?? '').isEmpty) {
        bindings['$widgetId'] = keep;
      }
    }
  }

  static Future<({List<int> ids, Map<String, String> bindings})>
      _togetherWidgetState() async {
    try {
      final raw = await _pinChannel.invokeMethod<dynamic>('togetherWidgetState');
      if (raw is Map) {
        final ids = <int>[];
        final idRaw = raw['ids'];
        if (idRaw is List) {
          for (final entry in idRaw) {
            final id = entry is int ? entry : int.tryParse('$entry');
            if (id != null) ids.add(id);
          }
        }
        final bindings = <String, String>{};
        final bindingRaw = raw['bindings'];
        if (bindingRaw is Map) {
          for (final entry in bindingRaw.entries) {
            final room = entry.value?.toString() ?? '';
            if (room.isNotEmpty) bindings['${entry.key}'] = room;
          }
        }
        return (ids: ids, bindings: bindings);
      }
    } catch (e) {
      debugPrint('togetherWidgetState: $e');
    }
    return (ids: await _installedTogetherIds(), bindings: await _readBindings());
  }

  static bool _roomAlreadyPlaced(
    String roomId,
    List<int> installed,
    Map<String, String> bindings,
  ) {
    return installed.any((widgetId) => bindings['$widgetId'] == roomId);
  }

  static bool _isTogetherProvider(String? className) {
    if (className == null || className.isEmpty) return false;
    return _ddayProviders.any(
      (p) =>
          className == p.qualified ||
          className.endsWith('.${p.name}') ||
          className == p.name,
    );
  }

  static Future<Map<String, String>> _readBindings() async {
    final raw =
        await HomeWidget.getWidgetData<String>(keyDdayWidgetBindings) ?? '';
    if (raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<List<int>> _installedTogetherIds() async {
    final installed = await HomeWidget.getInstalledWidgets();
    final ids = <int>[];
    for (final info in installed) {
      if (!_isTogetherProvider(info.androidClassName)) continue;
      final widgetId = info.androidWidgetId;
      if (widgetId != null) ids.add(widgetId);
    }
    return ids;
  }

  static Future<Map<String, Size>> _readHostByRoom() async {
    final raw = await HomeWidget.getWidgetData<String>(keyDdayHostByRoom) ?? '';
    if (raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, Size>{};
      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final w = double.tryParse('${map['w']}') ?? 0;
        final h = double.tryParse('${map['h']}') ?? 0;
        if (w < 40 || h < 40) continue;
        out[entry.key.toString()] = Size(w, h);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<({Size size, TogetherWidgetSize forSize, double cornerDp})?>
      _hostForRoom(String roomId) async {
    final raw = await HomeWidget.getWidgetData<String>(keyDdayHostByRoom) ?? '';
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final value = decoded[roomId];
      if (value is! Map) return null;
      final map = Map<String, dynamic>.from(value);
      final w = double.tryParse('${map['w']}') ?? 0;
      final h = double.tryParse('${map['h']}') ?? 0;
      if (w < 40 || h < 40) return null;
      final screen = _screenWidthDp().toDouble();
      if (w > screen * 1.25 || h > screen * 1.5) return null;
      final corner = (map['corner'] as num?)?.toDouble() ??
          TogetherWidgetSize.defaultCornerDp;
      return (
        size: Size(w, h),
        forSize: TogetherWidgetSize.byId(map['sizeId'] as String?),
        cornerDp: corner.clamp(12.0, 40.0),
      );
    } catch (_) {
      return null;
    }
  }

  /// Opens the system sheet to place the home character and speech bubble.
  static Future<bool> pinCharacterWidget() async {
    if (!_isAndroid) return false;
    try {
      await syncFromHome();
      final ok = await _pinChannel.invokeMethod<bool>('pinCharacterWidget');
      if (ok == true) return true;
    } catch (e) {
      debugPrint('pinCharacterWidget channel: $e');
    }
    try {
      final supported =
          await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) return false;
      await HomeWidget.requestPinWidget(
        name: androidProviderName,
        androidName: androidProviderName,
        qualifiedAndroidName: 'com.quotation.quotation.$androidProviderName',
      );
      return true;
    } catch (e) {
      debugPrint('pinCharacterWidget: $e');
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

  static Future<void> _saveAllRooms(String meId) async {
    final hosts = await _readHostByRoom();
    final rooms = <String, Map<String, Object>>{};
    for (final item in ddayController.items) {
      final textScale = ddayController.textScaleForRoom(item.id);
      final cheer = blockedUsersController.visibleCheer(
        item.id,
        item.latestCheer,
      );
      final box = hosts[item.id] ??
          TogetherWidgetSize.s42.homeSize(_screenWidthDp().toDouble());
      final inner = TogetherCheerLayout.innerSize(
        box.width,
        box.height,
        TogetherWidgetSize.defaultCornerDp,
      );
      var label = cheer;
      try {
        label = TogetherCheerLayout.wrap(
          text: cheer,
          maxWidth: inner.width,
          isPixel: visualStyleController.isPixel,
          textScale: textScale.toDouble(),
        );
      } catch (e) {
        debugPrint('cheer wrap: $e');
      }
      final themeId = ddayController.bgThemeForRoom(item.id);
      final placed = TogetherCrowdLayout.withUserScale(
        placed: TogetherCrowdLayout.resolve(
          people: TogetherCrowdLayout.roster(
            myUid: authController.viewerUid,
            myCharacterId: meId,
            hostUid: item.cloudOwnerUid,
            friends: item.friends,
          ),
          canvasW: box.width,
          canvasH: box.height,
          charFactor: TogetherWidgetSize.s42.charFactor,
          saved: ddayController.crowdForRoom(item.id),
        ),
        myUid: authController.viewerUid,
        meScale: ddayController.charScaleForRoom(item.id),
        friendScale: ddayController.friendScaleForRoom(item.id),
      );
      rooms[item.id] = {
        'label': label,
        'me': meId,
        'friend': item.hasFriend ? (item.friendCharacterId ?? '').trim() : '',
        'meX': ddayController.meOffsetXForRoom(item.id),
        'meY': ddayController.meOffsetYForRoom(item.id),
        'friendX': ddayController.friendOffsetXForRoom(item.id),
        'friendY': ddayController.friendOffsetYForRoom(item.id),
        'textX': ddayController.textOffsetXForRoom(item.id),
        'textY': ddayController.textOffsetYForRoom(item.id),
        'charScale': ddayController.charScaleForRoom(item.id),
        'friendScale': ddayController.friendScaleForRoom(item.id),
        'textScale': textScale,
        'bgAsset': WidgetAlbumBackground.resolvedAsset(
              themeId: themeId,
              roomId: item.id,
            ) ??
            '',
        'textColor': _hex(Color(ddayController.textColorForRoom(item.id))),
        'chars': TogetherCrowdLayout.widgetChars(placed),
      };
    }
    await HomeWidget.saveWidgetData<String>(
      keyDdayRoomsJson,
      jsonEncode(rooms),
    );
  }

  static Future<void> _saveDday() async {
    final item = ddayController.widgetDday;
    final meId = characterController.character.id;
    await _saveAllRooms(meId);
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
    final bgAsset = roomId == null
        ? TogetherBgTheme.byId(bgThemeId).assetPath
        : (WidgetAlbumBackground.resolvedAsset(
              themeId: bgThemeId,
              roomId: roomId,
            ) ??
            '');
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
    final meOffsetX =
        roomId == null ? 0 : ddayController.meOffsetXForRoom(roomId);
    final meOffsetY =
        roomId == null ? 0 : ddayController.meOffsetYForRoom(roomId);
    final friendOffsetX =
        roomId == null ? 0 : ddayController.friendOffsetXForRoom(roomId);
    final friendOffsetY =
        roomId == null ? 0 : ddayController.friendOffsetYForRoom(roomId);
    await HomeWidget.saveWidgetData<int>(keyDdayMeOffsetX, meOffsetX);
    await HomeWidget.saveWidgetData<int>(keyDdayMeOffsetY, meOffsetY);
    await HomeWidget.saveWidgetData<int>(keyDdayFriendOffsetX, friendOffsetX);
    await HomeWidget.saveWidgetData<int>(
      keyDdayFriendOffsetY,
      friendOffsetY,
    );
    await HomeWidget.saveWidgetData<int>(keyDdayTextOffsetX, textOffsetX);
    await HomeWidget.saveWidgetData<int>(keyDdayTextOffsetY, textOffsetY);
    await HomeWidget.saveWidgetData<int>(keyDdayCharScale, charScale);
    await HomeWidget.saveWidgetData<int>(keyDdayFriendCharScale, friendScale);
    await HomeWidget.saveWidgetData<int>(keyDdayTextScale, textScale);
    await HomeWidget.saveWidgetData<String>(keyDdayBgTheme, bgThemeId);
    await HomeWidget.saveWidgetData<String>(
      keyDdayBgAsset,
      bgAsset,
    );
    await HomeWidget.saveWidgetData<String>(
      keyDdayTextColor,
      _hex(Color(textColor)),
    );
    await HomeWidget.saveWidgetData<String>(keyDdayShape, shape.id);
    await HomeWidget.saveWidgetData<String>(keyDdayWidgetSize, widgetSize.id);
    await HomeWidget.saveWidgetData<String>(keyDdayRoomId, roomId ?? '');
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
    final rawLabel = blockedUsersController.visibleCheer(
      item.id,
      item.latestCheer,
    );
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
      await _pushCharacterWidget();
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
    await HomeWidget.saveWidgetData<String>(
      keyVisualStyle,
      visualStyleController.style.id,
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
