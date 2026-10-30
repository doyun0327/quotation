import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotation/data/cloud_consent.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/firebase_options.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/screens/main_shell.dart';
import 'package:quotation/screens/quote_list_screen.dart';
import 'package:quotation/screens/together_room_screen.dart';

@pragma('vm:entry-point')
Future<void> togetherFcmBackground(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final applied = await _applyTogetherMessage(message);
  if (!applied) return;
  await _showTogetherNotice(message);
}

Future<bool> _applyTogetherMessage(RemoteMessage message) async {
  if (message.data['type'] != 'together_widget') return false;
  try {
    await ddayController.load();
    await DdayCloudSync.pullMemberships();
    await HomeWidgetSync.syncDday();
    return true;
  } catch (e) {
    debugPrint('together fcm apply: $e');
    return false;
  }
}

Future<bool> _claimTogetherNotice(String roomId, String stamp) async {
  if (roomId.isEmpty) return false;
  final token = stamp.trim().isEmpty ? 'nostamp' : stamp.trim();
  final key = '$roomId|$token';
  final prefs = await SharedPreferences.getInstance();
  const prefKey = 'together_notify_claim';
  final raw = prefs.getString(prefKey) ?? '';
  final now = DateTime.now().millisecondsSinceEpoch;
  final split = raw.lastIndexOf('|');
  if (split > 0) {
    final prevKey = raw.substring(0, split);
    final prevAt = int.tryParse(raw.substring(split + 1)) ?? 0;
    if (prevKey == key && now - prevAt < 20000) return false;
  }
  await prefs.setString(prefKey, '$key|$now');
  return true;
}

const _togetherChannelId = 'together_widget';
const _noticeIdsKey = 'together_room_notice_ids';

int _togetherNoticeId(String roomId, String stamp) {
  var hash = 17;
  for (final unit in '$roomId|$stamp'.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return 100000 + (hash % 800000);
}

NotificationDetails _togetherDetails(String roomId) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      _togetherChannelId,
      'Together widget',
      importance: Importance.high,
      priority: Priority.high,
      tag: roomId,
    ),
  );
}

Map<String, List<int>> _readNoticeIds(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final out = <String, List<int>>{};
    for (final entry in decoded.entries) {
      final roomId = entry.key.toString();
      final value = entry.value;
      if (roomId.isEmpty || value is! List) continue;
      out[roomId] = [
        for (final id in value)
          if (id is num) id.toInt(),
      ];
    }
    return out;
  } catch (_) {
    return {};
  }
}

Future<void> _rememberRoomNotice(String roomId, int id) async {
  if (roomId.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final map = _readNoticeIds(prefs.getString(_noticeIdsKey));
  final ids = map[roomId] ?? <int>[];
  if (!ids.contains(id)) ids.add(id);
  if (ids.length > 30) {
    ids.removeRange(0, ids.length - 30);
  }
  map[roomId] = ids;
  await prefs.setString(_noticeIdsKey, jsonEncode(map));
}

Future<void> _clearRoomNotices(String roomId, {String? roomTitle}) async {
  if (roomId.isEmpty) return;
  final title = roomTitle?.trim() ?? '';
  final ids = <int>{};
  try {
    final prefs = await SharedPreferences.getInstance();
    final map = _readNoticeIds(prefs.getString(_noticeIdsKey));
    ids.addAll(map.remove(roomId) ?? const <int>[]);
    await prefs.setString(_noticeIdsKey, jsonEncode(map));
  } catch (e) {
    debugPrint('together notice ids: $e');
  }
  final plugin = TogetherFcm._plugin;
  try {
    final active = await plugin.getActiveNotifications();
    for (final notice in active) {
      final id = notice.id;
      if (id == null) continue;
      final tagged = notice.tag == roomId;
      final sameTitle = title.isNotEmpty &&
          notice.channelId == _togetherChannelId &&
          notice.title == title;
      if (tagged || sameTitle || ids.contains(id)) ids.add(id);
    }
  } catch (e) {
    debugPrint('together active notices: $e');
  }
  for (final id in ids) {
    try {
      await plugin.cancel(id: id, tag: roomId);
      await plugin.cancel(id: id);
    } catch (e) {
      debugPrint('together cancel notice: $e');
    }
  }
}

Future<void> _showTogetherNotice(RemoteMessage message) async {
  if (message.data['type'] != 'together_widget') return;
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit),
  );
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      _togetherChannelId,
      'Together widget',
      description: 'A friend updated the shared widget',
      importance: Importance.high,
    ),
  );
  final roomId = message.data['roomId']?.toString() ?? '';
  final stamp = message.data['stamp']?.toString() ?? '';
  if (!await _claimTogetherNotice(roomId, stamp)) return;
  final t = AppStrings.current;
  final roomTitle = (message.data['roomTitle'] ?? message.data['title'] ?? '')
      .toString()
      .trim();
  final actorName = (message.data['actorName'] ?? '').toString().trim();
  final name =
      actorName.isEmpty ? t.togetherFriendFallbackName : actorName;
  final title = roomTitle.isEmpty ? name : roomTitle;
  final body = t.togetherWidgetChangedBodyFor(name);
  final noticeId = _togetherNoticeId(roomId, stamp);
  await _rememberRoomNotice(roomId, noticeId);
  await plugin.show(
    id: noticeId,
    title: title,
    body: body,
    payload: roomId,
    notificationDetails: _togetherDetails(roomId),
  );
}

/// Saves this device's FCM token and shows a notice when a friend edits the widget.
abstract final class TogetherFcm {
  static const _channelId = 'together_widget';
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _started = false;
  static GlobalKey<NavigatorState>? navigatorKey;
  static String? _lastOpenedRoom;
  static DateTime? _lastOpenedAt;

  static Future<void> start(GlobalKey<NavigatorState> key) async {
    navigatorKey = key;
    if (kIsWeb || _started) return;
    _started = true;
    HomeWidget.widgetClicked.listen((uri) {
      unawaited(openFromHomeWidget(uri));
    });
    try {
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      unawaited(openFromHomeWidget(initial));
    } catch (e) {
      debugPrint('widget launch: $e');
    }
    try {
      await FirebaseMessaging.instance.requestPermission();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        settings: const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Together widget',
          description: 'A friend updated the shared widget',
          importance: Importance.high,
        ),
      );
      DdayCloudSync.onRemoteWidgetEdit = (notice) {
        unawaited(showAppliedNotice(notice));
      };
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        unawaited(openRoomFromNotice(message.data['roomId']));
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        unawaited(openRoomFromNotice(initial.data['roomId']));
      }
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        unawaited(
          openRoomFromNotice(launch?.notificationResponse?.payload),
        );
      }
      await _saveToken();
      // Admin sends to registration tokens. register()/onRegistered exposes a
      // Firebase Installation ID, which is not a send target.
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen(_writeToken);
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) unawaited(_saveToken());
      });
      FirebaseMessaging.onMessage.listen(_showForeground);
    } catch (e) {
      debugPrint('TogetherFcm.start: $e');
    }
  }

  static Future<void> _saveToken() async {
    // ignore: deprecated_member_use
    final token = await FirebaseMessaging.instance.getToken();
    await _writeToken(token);
  }

  static Future<void> _writeToken(String? token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!CloudConsent.accepted || uid == null || token == null || token.isEmpty) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmTokens': {token: true},
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('TogetherFcm.token: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    unawaited(openRoomFromNotice(response.payload));
  }

  /// Home-screen widget tap.
  /// Character bubble: `dearly://quote?id=&category=&sub=`
  /// Together: `dearly://together?room={id}`.
  static Future<void> openFromHomeWidget(Uri? uri) async {
    if (uri == null || uri.scheme != 'dearly') return;
    if (uri.host == 'quote') {
      await _openQuote(uri);
      return;
    }
    if (uri.host != 'together') return;
    final room = uri.queryParameters['room']?.trim() ?? '';
    if (room.isEmpty) {
      mainShellTab.value = 1;
      return;
    }
    await openRoomFromNotice(room);
  }

  static Future<void> _openQuote(Uri uri) async {
    final id = uri.queryParameters['id']?.trim() ?? '';
    final now = DateTime.now();
    final key = 'quote:$id';
    if (_lastOpenedRoom == key &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOpenedRoom = key;
    _lastOpenedAt = now;
    mainShellTab.value = 0;
    if (id.isEmpty) return;
    final located = QuoteRepository.locateQuote(
      id,
      categoryId: uri.queryParameters['category'],
      subId: uri.queryParameters['sub'],
    );
    if (located == null) return;
    for (var attempt = 0; attempt < 8; attempt++) {
      final nav = navigatorKey?.currentState;
      if (nav != null) {
        await nav.push(
          MaterialPageRoute<void>(
            builder: (_) => QuoteListScreen(
              mainCategory: located.main,
              subCategory: located.sub,
              initialIndex: located.index,
            ),
          ),
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  static Future<void> openRoomFromNotice(String? roomId) async {
    final id = roomId?.trim() ?? '';
    if (id.isEmpty) return;
    final now = DateTime.now();
    if (_lastOpenedRoom == id &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOpenedRoom = id;
    _lastOpenedAt = now;
    try {
      await authController.ensureFirebaseSession();
      await ddayController.load();
      await DdayCloudSync.pullMemberships();
      await HomeWidgetSync.syncDday();
    } catch (e) {
      debugPrint('openRoomFromNotice: $e');
    }
    final rooms = ddayController.items.where((e) => e.id == id);
    final roomTitle = rooms.isEmpty ? '' : rooms.first.title;
    await _clearRoomNotices(id, roomTitle: roomTitle);
    mainShellTab.value = 1;
    for (var attempt = 0; attempt < 8; attempt++) {
      final nav = navigatorKey?.currentState;
      if (nav != null) {
        await nav.push(
          MaterialPageRoute<void>(
            builder: (_) => TogetherRoomScreen(roomId: id),
          ),
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  static Future<void> showAppliedNotice(TogetherLayoutNotice notice) async {
    if (!await _claimTogetherNotice(notice.roomId, notice.stamp)) return;
    final t = AppStrings.current;
    final name = notice.actorName.trim().isEmpty
        ? t.togetherFriendFallbackName
        : notice.actorName.trim();
    final title = notice.roomTitle.trim().isEmpty
        ? t.togetherFriendFallbackName
        : notice.roomTitle.trim();
    final noticeId = _togetherNoticeId(notice.roomId, notice.stamp);
    await _rememberRoomNotice(notice.roomId, noticeId);
    await _plugin.show(
      id: noticeId,
      title: title,
      body: t.togetherWidgetChangedBodyFor(name),
      payload: notice.roomId,
      notificationDetails: _togetherDetails(notice.roomId),
    );
  }

  static Future<void> _showForeground(RemoteMessage message) async {
    final applied = await _applyTogetherMessage(message);
    if (!applied) return;
    await _showTogetherNotice(message);
  }
}
