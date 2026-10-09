import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules device-local notifications for schedule blocks marked
/// "remind me." Solid on Android/iOS/Windows/macOS; no web
/// implementation; Linux depends on a D-Bus notification daemon. Every
/// call is wrapped in try/catch so an unsupported platform degrades
/// gracefully (reminder silently doesn't fire) instead of crashing.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
    );
    try {
      await _plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
      _initialized = true;
    } catch (_) {
      // Non-fatal: platform doesn't support local notifications.
    }
  }

  Future<void> scheduleForBlock({required DateTime date, required TimeOfDay time, required String title}) async {
    await init();
    if (!_initialized) return;
    try {
      final scheduled = tz.TZDateTime(tz.local, date.year, date.month, date.day, time.hour, time.minute);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

      const androidDetails = AndroidNotificationDetails(
        'schedule_reminders', 'Schedule reminders',
        channelDescription: 'Reminders for blocks you marked "remind me" on',
        importance: Importance.max, priority: Priority.high, enableVibration: true, playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(presentSound: true);

      await _plugin.zonedSchedule(
        scheduled.millisecondsSinceEpoch ~/ 1000,
        title,
        "It's time — you marked this to remind you.",
        scheduled,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Non-fatal — see class doc comment.
    }
  }
}
