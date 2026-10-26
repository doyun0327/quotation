import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:quotation/data/encouragement_message_loader.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Fortune at 08:00. One afternoon cheer: lunch at 12:00 or evening at 19:00.
abstract final class EncouragementNotificationScheduler {
  static const _prefsEnabledKey = 'encouragement_notifications_enabled';
  static const _channelId = 'daily_encouragement';
  static const _channelName = 'Daily encouragement';
  static const _scheduleDays = 14;
  static const _debugEveningId = 6399;
  static const _fortuneBase = 6400;
  static const _lunchBase = 6500;
  static const _eveningBase = 6600;
  static const _legacyBases = [6100, 6200, 6300];
  static const _fortuneHour = 8;
  static const _lunchHour = 12;
  static const _eveningHour = 19;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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
        description: 'Fortune at 8:00 and one afternoon encouragement',
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
    final lunch = await EncouragementMessageLoader.load(
      EncouragementSlot.lunch,
      languageId: lang,
    );
    final evening = await EncouragementMessageLoader.load(
      EncouragementSlot.evening,
      languageId: lang,
    );
    final fortunes = QuoteRepository.fortuneQuotesForLocale();
    final fortuneTitle = AppStrings.current.todaysFortune;
    final fortuneFallback = AppStrings.current.fortuneFallbackLine;

    for (var i = 0; i < _scheduleDays; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      await _scheduleAt(
        id: _fortuneBase + i,
        day: day,
        hour: _fortuneHour,
        now: now,
        title: fortuneTitle,
        body: _fortuneBody(day, fortunes, fortuneFallback),
        payload: 'fortune:$i',
      );
      final lunchToday = _afternoonIsLunch(day);
      final slot = lunchToday ? EncouragementSlot.lunch : EncouragementSlot.evening;
      final pool = lunchToday ? lunch : evening;
      final fallback = lunchToday ? evening : lunch;
      final messages = pool.isNotEmpty ? pool : fallback;
      await _scheduleCheer(
        id: (lunchToday ? _lunchBase : _eveningBase) + i,
        day: day,
        hour: lunchToday ? _lunchHour : _eveningHour,
        now: now,
        slot: slot,
        messages: messages,
      );
    }
  }

  /// Same calendar day always picks the same side, and never both.
  static bool _afternoonIsLunch(DateTime day) {
    final key =
        '${day.year.toString().padLeft(4, '0')}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}:afternoon';
    return (key.hashCode & 1) == 0;
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
        channelDescription: 'Fortune at 8:00 and one afternoon encouragement',
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
