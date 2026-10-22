import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/firebase_options.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/screens/main_shell.dart';
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

Future<void> _showTogetherNotice(RemoteMessage message) async {
  if (message.data['type'] != 'together_widget') return;
  const channelId = 'together_widget';
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit),
  );
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      channelId,
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
  await plugin.show(
    id: message.hashCode,
    title: title,
    body: body,
    payload: message.data['roomId'],
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Together widget',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
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
    if (uid == null || token == null || token.isEmpty) return;
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

  /// Home-screen together widget tap: `dearly://together?room={id}`.
  static Future<void> openFromHomeWidget(Uri? uri) async {
    if (uri == null || uri.scheme != 'dearly' || uri.host != 'together') {
      return;
    }
    final room = uri.queryParameters['room']?.trim() ?? '';
    if (room.isEmpty) {
      mainShellTab.value = 1;
      return;
    }
    await openRoomFromNotice(room);
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
    await _plugin.show(
      id: 4201,
      title: title,
      body: t.togetherWidgetChangedBodyFor(name),
      payload: notice.roomId,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Together widget',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> _showForeground(RemoteMessage message) async {
    final applied = await _applyTogetherMessage(message);
    if (!applied) return;
    await _showTogetherNotice(message);
  }
}
