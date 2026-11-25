import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotation/data/app_check.dart';
import 'package:quotation/data/crash_reporting.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/cloud_consent.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/push_trace.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/firebase_options.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/main_shell.dart';
import 'package:quotation/screens/quote_list_screen.dart';
import 'package:quotation/screens/together_room_screen.dart';

@pragma('vm:entry-point')
Future<void> togetherFcmBackground(RemoteMessage message) async {
  final watch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  _pushLog(
    'bg start type=${message.data['type']} '
    'state=${WidgetsBinding.instance.lifecycleState?.name}',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Separate isolate: without its own App Check token, the room sync below
  // would be refused once App Check is enforced.
  await activateAppCheck();
  await CrashReporting.start();
  // This isolate starts with the default language; the notice must follow
  // the language the app uses.
  await localeController.load();
  _pushLog('bg init done ${watch.elapsedMilliseconds}ms');
  final applied = await _applyTogetherMessage(message);
  _pushLog('bg applied=$applied ${watch.elapsedMilliseconds}ms');
  if (!applied || _isSilentRefresh(message)) return;
  // iOS shows the APNs alert itself; a local notice here would duplicate it.
  if (defaultTargetPlatform == TargetPlatform.iOS) return;
  await _showTogetherNotice(message);
}

/// Android + iOS init. Without iOS settings, initialize() throws on iPhone and
/// the FCM token is never saved, so friends' edits never reach the widget.
/// Permission is asked by FirebaseMessaging.requestPermission instead.
const _notificationInit = InitializationSettings(
  android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
  iOS: DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  ),
);

/// Push-to-widget trace. Shows in the device log (Console app, or
/// `flutter logs`) as "DEARLY_PUSH …", also in release builds.
void _pushLog(String text) => unawaited(PushTrace.add(text));

/// A friend changed their character: redraw the widget, no notice.
bool _isSilentRefresh(RemoteMessage message) =>
    message.data['type'] == 'together_refresh';

Future<bool> _applyTogetherMessage(RemoteMessage message) async {
  final type = message.data['type'];
  if (type != 'together_widget' &&
      type != 'together_refresh' &&
      type != 'together_join') {
    return false;
  }
  try {
    // Background isolate: the block list must be loaded before the room sync
    // decides whose edits to apply.
    if (!blockedUsersController.ready) await blockedUsersController.load();
    await ddayController.load();
    // A fresh background isolate has no signed-in user until Firebase Auth
    // restores the session; pullMemberships() silently returns when
    // currentUser is still null, so the widget never changed unless the
    // notification was tapped (which starts the app, and its own sync).
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
    }
    _pushLog('auth uid=${FirebaseAuth.instance.currentUser?.uid != null}');
    if (FirebaseAuth.instance.currentUser == null) return false;
    // pullMemberships() already ends with HomeWidgetSync.syncDday(); a second
    // call only doubled the time of a ~30 s background window.
    await DdayCloudSync.pullMemberships();
    _pushLog('pullMemberships done');
    return true;
  } catch (e) {
    _pushLog('apply failed: $e');
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
    iOS: DarwinNotificationDetails(threadIdentifier: roomId),
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
  final type = message.data['type'];
  if (type != 'together_widget' && type != 'together_join') return;
  // No notice about someone I blocked (the server skips them too once my
  // block list has synced; this covers the time before that).
  if (!blockedUsersController.ready) await blockedUsersController.load();
  if (blockedUsersController.isBlocked(message.data['actorUid']?.toString())) {
    return;
  }
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(settings: _notificationInit);
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
  // Someone joined the room with an invite code.
  final body = type == 'together_join'
      ? t.togetherJoinedBodyFor(name)
      : t.togetherWidgetChangedBodyFor(name);
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
      await _plugin.initialize(
        settings: _notificationInit,
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
      // Listeners first: a token failure below must not skip them.
      // Admin sends to registration tokens. register()/onRegistered exposes a
      // Firebase Installation ID, which is not a send target.
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen(_writeToken);
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) unawaited(_saveToken());
      });
      FirebaseMessaging.onMessage.listen(_showForeground);
      // iOS background fetch (AppDelegate.performFetch): sync the rooms and
      // redraw the widgets, as a push would.
      _deviceIdChannel.setMethodCallHandler((call) async {
        if (call.method != 'backgroundSync') return null;
        _pushLog('bg fetch start');
        final applied = await _applyTogetherMessage(
          const RemoteMessage(data: {'type': 'together_refresh'}),
        );
        _pushLog('bg fetch applied=$applied');
        return applied;
      });
      unawaited(_saveToken());
    } catch (e) {
      debugPrint('TogetherFcm.start: $e');
    }
  }

  /// Saves the FCM token. On iPhone getToken() throws until APNs hands the
  /// device token over (a moment after launch), so wait for it first.
  static Future<void> _saveToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apns;
        for (var attempt = 0; attempt < 10 && apns == null; attempt++) {
          apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns == null) {
            await Future<void>.delayed(const Duration(seconds: 3));
          }
        }
        // No APNs token (e.g. simulator): onTokenRefresh saves it later.
        if (apns == null) return;
      }
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      await _writeToken(token);
    } catch (e) {
      debugPrint('TogetherFcm.saveToken: $e');
    }
  }

  static Future<void> _writeToken(String? token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!CloudConsent.accepted || uid == null || token == null || token.isEmpty) {
      return;
    }
    try {
      final deviceId = await _deviceId();
      if (deviceId == null) return;
      // One token per phone under a stable device id (fcmDevices). The old
      // `fcmTokens` map may still hold other phones of this account that run
      // an older app, so only this phone's own tokens leave it (the current
      // one, and the one it saved last time); the server reads both maps and
      // sends to each token once.
      final prefs = await SharedPreferences.getInstance();
      const lastKey = 'fcm_last_token';
      final previous = prefs.getString(lastKey);
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmDevices': {deviceId: token},
          'fcmTokens': {
            token: FieldValue.delete(),
            if (previous != null && previous.isNotEmpty && previous != token)
              previous: FieldValue.delete(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await prefs.setString(lastKey, token);
    } catch (e) {
      debugPrint('TogetherFcm.token: $e');
    }
  }

  static const _deviceIdChannel = MethodChannel(
    'com.dearly.quoteswidget/widget_reload',
  );

  /// iPhone: Keychain id (survives a reinstall). Android: a reinstall makes
  /// FCM drop the old token anyway, so an id in app storage is enough.
  static Future<String?> _deviceId() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final id = await _deviceIdChannel.invokeMethod<String>('deviceId');
        if (id != null && id.isNotEmpty) return id;
      } catch (e) {
        debugPrint('deviceId: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    const key = 'fcm_device_id';
    var id = prefs.getString(key);
    if (id == null || id.isEmpty) {
      final rnd = Random.secure();
      id = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(key, id);
    }
    return id;
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
    // A widget or notice from before the room was re-keyed has the old id.
    final id = ddayController.currentRoomId(roomId?.trim() ?? '');
    if (id.isEmpty) return;
    // The morning fortune and evening cheer share this notification plugin;
    // their payloads ("fortune:…", "evening:…") are not rooms. Just the app.
    if (id.contains(':')) return;
    final now = DateTime.now();
    if (_lastOpenedRoom == id &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOpenedRoom = id;
    _lastOpenedAt = now;
    // A room already on this device opens at once and refreshes behind the
    // screen. Only a room we have never seen has to wait for the network.
    if (ddayController.items.any((e) => e.id == id)) {
      unawaited(_refreshRoomData(delay: _routeTransition));
    } else {
      await _refreshRoomData();
    }
    final rooms = ddayController.items.where((e) => e.id == id);
    final roomTitle = rooms.isEmpty ? '' : rooms.first.title;
    unawaited(_clearRoomNotices(id, roomTitle: roomTitle));
    mainShellTab.value = 1;
    for (var attempt = 0; attempt < 8; attempt++) {
      final nav = navigatorKey?.currentState;
      if (nav != null) {
        // Each widget/notification tap used to push another room (and the
        // decorator above it) onto the stack, so Back had to be pressed
        // over and over. Return to an open copy of this room, or to the
        // main shell, before opening it.
        final name = TogetherRoomScreen.routeNameFor(id);
        var found = false;
        nav.popUntil((route) {
          if (route.settings.name == name) {
            found = true;
            return true;
          }
          return route.isFirst;
        });
        if (found) return;
        await nav.push(TogetherRoomScreen.route(id));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  /// Widget re-render is heavy; waiting out the push keeps the slide smooth.
  static const _routeTransition = Duration(milliseconds: 450);

  static Future<void> _refreshRoomData({Duration delay = Duration.zero}) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    try {
      await authController.ensureFirebaseSession();
      await ddayController.load();
      await DdayCloudSync.pullMemberships();
      await HomeWidgetSync.syncDday();
    } catch (e) {
      debugPrint('refresh opened room: $e');
    }
  }

  /// The room a widget tap cold-started the app for, if it is on this device,
  /// so it can be the first screen instead of appearing after the main one.
  static Future<String?> widgetLaunchRoom() async {
    if (kIsWeb) return null;
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri == null || uri.scheme != 'dearly' || uri.host != 'together') {
        return null;
      }
      final room = uri.queryParameters['room']?.trim() ?? '';
      return ddayController.items.any((e) => e.id == room) ? room : null;
    } catch (e) {
      debugPrint('widget launch room: $e');
      return null;
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
    _pushLog('foreground message type=${message.data['type']}');
    final applied = await _applyTogetherMessage(message);
    if (!applied || _isSilentRefresh(message)) return;
    await _showTogetherNotice(message);
  }
}
