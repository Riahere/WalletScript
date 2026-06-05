import 'package:flutter/material.dart'; // ← FIX: tambah import ini
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Channel IDs ───────────────────────────────────────────────────────────
  static const _chReminder = AndroidNotificationDetails(
    'walletscript_reminders',
    'Reminders',
    channelDescription: 'Daily reminders to log your transactions',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  static const _chTransaction = AndroidNotificationDetails(
    'walletscript_transactions',
    'Transactions',
    channelDescription: 'Alerts when transactions are recorded',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
    playSound: false,
    enableVibration: false,
  );

  // ← FIX: ubah dari `static const` ke `static final`
  // karena Color(0xFFFF6B6B) bukan compile-time constant tanpa import material
  static final _chBudget = AndroidNotificationDetails(
    'walletscript_budget',
    'Budget Alerts',
    channelDescription: 'Alerts when budget thresholds are reached',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
    color: const Color(0xFFFF6B6B),
  );

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Notification enabled guard ────────────────────────────────────────────
  bool _notificationsEnabled = true;

  void setEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    if (!enabled) cancelAll();
  }

  // ── Daily Reminder ────────────────────────────────────────────────────────
  Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
    String title = 'Daily Finance Reminder',
    String body = "Don't forget to log today's transactions!",
  }) async {
    if (!_notificationsEnabled) return;
    await init();

    await _plugin.cancel(1000);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1000,
      title,
      body,
      scheduled,
      const NotificationDetails(android: _chReminder),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async => _plugin.cancel(1000);

  // ── Budget Alert ──────────────────────────────────────────────────────────
  Future<void> showBudgetAlert({
    required int notifId,
    required String title,
    required String body,
  }) async {
    if (!_notificationsEnabled) return;
    await init();
    await _plugin.show(
      notifId,
      title,
      body,
      NotificationDetails(
          android: _chBudget), // ← non-const karena _chBudget adalah final
    );
  }

  // ── Transaction Alert ─────────────────────────────────────────────────────
  Future<void> showTransactionAlert({
    required int notifId,
    required String title,
    required String body,
  }) async {
    if (!_notificationsEnabled) return;
    await init();
    await _plugin.show(
      notifId,
      title,
      body,
      const NotificationDetails(android: _chTransaction),
    );
  }

  // ── Legacy: generic showNow & scheduleReminder (kept for notes feature) ───
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_notificationsEnabled) return;
    await init();
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: _chReminder),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_notificationsEnabled) return;
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: _chReminder),
    );
  }

  Future<void> cancelReminder(int id) async => _plugin.cancel(id);

  Future<void> cancelAll() async => _plugin.cancelAll();
}
