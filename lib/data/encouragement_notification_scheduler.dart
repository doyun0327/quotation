import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:quotation/data/encouragement_message_loader.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local-time morning / lunch / evening encouragement notifications.
abstract final class EncouragementNotificationScheduler {
  static const _prefsEnabledKey = 'encouragement_notifications_enabled';
  static const _channelId = 'daily_encouragement';
  static const _channelName = 'Daily encouragement';
  static const _scheduleDays = 14;
  static const _debugEveningId = 6399;

  static const _baseIds = {
    EncouragementSlot.morning: 6100,
    EncouragementSlot.lunch: 6200,
    EncouragementSlot.evening: 6300,
  };

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

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
        description: 'Morning, lunch, and evening encouragement',
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
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEnabledKey) ?? true;
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
    for (final slot in EncouragementSlot.values) {
      final base = _baseIds[slot]!;
      for (var i = 0; i < _scheduleDays; i++) {
        await _plugin.cancel(id: base + i);
      }
    }
    await _plugin.cancel(id: _debugEveningId);
  }

  static Future<void> reschedule() async {
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

    for (final slot in EncouragementSlot.values) {
      final messages = await EncouragementMessageLoader.load(
        slot,
        languageId: lang,
      );
      if (messages.isEmpty) continue;

      final base = _baseIds[slot]!;
      for (var i = 0; i < _scheduleDays; i++) {
        final day =
            DateTime(now.year, now.month, now.day).add(Duration(days: i));
        final when = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          slot.hour,
          slot.minute,
        );
        if (!when.isAfter(now)) continue;

        final message = EncouragementMessageLoader.pickForDate(
          day,
          slot,
          messages,
        );
        if (message == null) continue;

        await _plugin.zonedSchedule(
          id: base + i,
          scheduledDate: when,
          title: message.title,
          body: message.body,
          notificationDetails: _details(message.body),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '${slot.name}:${message.day}',
        );
      }
    }
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
        channelDescription: 'Morning, lunch, and evening encouragement',
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
