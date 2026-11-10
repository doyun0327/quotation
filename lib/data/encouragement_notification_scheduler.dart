import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:quotation/data/encouragement_message_loader.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Fortune at 08:00. Evening encouragement at 19:00. Lunch is not sent.
abstract final class EncouragementNotificationScheduler {
  static const _prefsEnabledKey = 'encouragement_notifications_enabled';
  static const _prefsEveningKey = 'evening_encouragement_enabled';
  static const _prefsMorningKey = 'morning_fortune_enabled';
  static const _channelId = 'daily_encouragement';
  static const _channelName = 'Daily encouragement';
  static const _scheduleDays = 14;
  static const _debugEveningId = 6399;
  static const _fortuneBase = 6400;
  static const _lunchBase = 6500;
  static const _eveningBase = 6600;
  static const _legacyBases = [6100, 6200, 6300];
  static const _fortuneHour = 8;
  static const _eveningHour = 19;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _morningChannel = MethodChannel(
    'com.quotation.quotation/widget_pin',
  );

  static bool _initialized = false;
  static Future<void> _rescheduleChain = Future<void>.value();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) {
      await reschedule();
      return;
    }

    tz_data.initializeTimeZones();
    await _syncLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Fortune at 8:00 and evening encouragement at 19:00',
        importance: Importance.high,
      ),
    );

    localeController.addListener(() {
      EncouragementMessageLoader.clearCache();
      reschedule();
    });

    _initialized = true;
    await reschedule();
  }

  static Future<void> _syncLocalTimezone() async {
    final deviceOffset = DateTime.now().timeZoneOffset;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final named = tz.getLocation(info.identifier);
      if (tz.TZDateTime.now(named).timeZoneOffset == deviceOffset) {
        tz.setLocalLocation(named);
        return;
      }
    } catch (_) {}

    if (deviceOffset == const Duration(hours: 9)) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      return;
    }
    if (deviceOffset == Duration.zero) {
      tz.setLocalLocation(tz.UTC);
      return;
    }
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(location).timeZoneOffset == deviceOffset) {
        tz.setLocalLocation(location);
        return;
      }
    }
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEnabledKey) ?? true;
  }

  /// Evening cheer (19:00) on/off from Settings; the morning fortune is
  /// unaffected. On by default.
  static Future<bool> isEveningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEveningKey) ?? true;
  }

  static Future<void> setEveningEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEveningKey, enabled);
    await reschedule();
  }

  /// Morning fortune (08:00) on/off from Settings. On by default. Android
  /// rings it from MorningFortuneAlarm; iPhone from a local notification.
  static Future<bool> isMorningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsMorningKey) ?? true;
  }

  static Future<void> setMorningEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsMorningKey, enabled);
    await reschedule();
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabledKey, enabled);
    if (enabled) {
      await reschedule();
    } else {
      await cancelAll();
    }
  }

  static Future<void> cancelAll() async {
    for (final base in [
      ..._legacyBases,
      _fortuneBase,
      _lunchBase,
      _eveningBase,
    ]) {
      for (var i = 0; i < _scheduleDays; i++) {
        await _plugin.cancel(id: base + i);
      }
    }
    await _plugin.cancel(id: _debugEveningId);
    if (!kIsWeb) {
      try {
        await _morningChannel.invokeMethod('cancelMorningFortunes');
      } catch (_) {}
    }
  }

  static Future<void> reschedule() {
    final next = _rescheduleChain.then((_) => _reschedule());
    _rescheduleChain = next.catchError((_) {});
    return next;
  }

  static Future<void> _reschedule() async {
    if (kIsWeb || !_initialized) return;
    await _syncLocalTimezone();

    if (!await isEnabled()) {
      await cancelAll();
      return;
    }

    final allowed = await _requestPermission();
    if (!allowed) return;

    await cancelAll();

    final lang = localeController.language.id;
    final now = tz.TZDateTime.now(tz.local);
    final evening = await EncouragementMessageLoader.load(
      EncouragementSlot.evening,
      languageId: lang,
    );
    final fortunes = QuoteRepository.fortuneQuotesForLocale();
    final fortuneTitle = AppStrings.current.todaysFortune;
    final fortuneFallback = AppStrings.current.fortuneFallbackLine;
    final mornings = <Map<String, Object>>[];
    final wallNow = DateTime.now();
    final eveningOn = await isEveningEnabled();
    final morningOn = await isMorningEnabled();

    for (var i = 0; i < _scheduleDays; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final morningAt = DateTime(day.year, day.month, day.day, _fortuneHour);
      if (morningOn && morningAt.isAfter(wallNow)) {
        final body = _fortuneBody(day, fortunes, fortuneFallback);
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Android rings it from MorningFortuneAlarm (exact, boot-safe).
          mornings.add({
            'at': morningAt.millisecondsSinceEpoch,
            'title': fortuneTitle,
            'body': body,
          });
        } else {
          await _scheduleAt(
            id: _fortuneBase + i,
            day: day,
            hour: _fortuneHour,
            now: now,
            title: fortuneTitle,
            body: body,
            payload: 'fortune:${day.year}-${day.month}-${day.day}',
          );
        }
      }
      if (!eveningOn) continue;
      await _scheduleCheer(
        id: _eveningBase + i,
        day: day,
        hour: _eveningHour,
        now: now,
        slot: EncouragementSlot.evening,
        messages: evening,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _morningChannel.invokeMethod('scheduleMorningFortunes', {
          'items': mornings,
        });
      } catch (_) {}
    }
  }

  static Future<void> _scheduleCheer({
    required int id,
    required DateTime day,
    required int hour,
    required tz.TZDateTime now,
    required EncouragementSlot slot,
    required List<EncouragementMessage> messages,
  }) async {
    final message = EncouragementMessageLoader.pickForDate(day, slot, messages);
    if (message == null) return;
    await _scheduleAt(
      id: id,
      day: day,
      hour: hour,
      now: now,
      title: message.title,
      body: message.body,
      payload: '${slot.name}:${message.day}',
    );
  }

  static String _fortuneBody(
    DateTime day,
    List<dynamic> fortunes,
    String fallback,
  ) {
    if (fortunes.isEmpty) return fallback;
    final key =
        '${day.year.toString().padLeft(4, '0')}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}:fortune';
    final quote = fortunes[(key.hashCode & 0x7fffffff) % fortunes.length];
    final text = quote.text.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static Future<void> _scheduleAt({
    required int id,
    required DateTime day,
    required int hour,
    required tz.TZDateTime now,
    required String title,
    required String body,
    required String payload,
  }) async {
    final when = tz.TZDateTime(
      tz.local,
      day.year,
      day.month,
      day.day,
      hour,
    );
    if (!when.isAfter(now)) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      title: title,
      body: body,
      notificationDetails: _details(body),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Debug helper: show one evening encouragement immediately.
  static Future<void> debugShowEveningOnce() async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    final allowed = await _requestPermission();
    if (!allowed) return;

    final messages = await EncouragementMessageLoader.load(
      EncouragementSlot.evening,
      languageId: localeController.language.id,
    );
    final message = EncouragementMessageLoader.pickRandom(messages);
    if (message == null) return;

    await _plugin.show(
      id: _debugEveningId,
      title: message.title,
      body: message.body,
      notificationDetails: _details(message.body),
      payload: 'evening_debug:${message.day}',
    );
  }

  static NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Fortune at 8:00 and evening encouragement at 19:00',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<bool> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }
}
