import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../data/task_model.dart' as model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialise ────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    _initialized = true;
  }

  // ── Notification details ──────────────────────────────────────────────────
  NotificationDetails _getDetails({
    required String channelId,
    required String channelName,
    Priority androidPriority = Priority.defaultPriority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: androidPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ── Schedule deadline reminder ────────────────────────────────────────────
  Future<void> scheduleDeadlineReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
    required model.Priority priority,
  }) async {
    if (!_initialized) await init();

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _notificationId(taskId, 'deadline'),
      _priorityPrefix(priority) + taskTitle,
      'This task is due soon. Tap to open.',
      scheduledDate,
      _getDetails(
        channelId: 'deadlines',
        channelName: 'Task Deadlines',
        androidPriority: _androidPriority(priority),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Schedule daily goal reminder ──────────────────────────────────────────
  Future<void> scheduleDailyGoalReminder({
    required String goalId,
    required String goalTitle,
    required TimeOfDay reminderTime,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year, now.month, now.day,
      reminderTime.hour, reminderTime.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notificationId(goalId, 'goal'),
      '🎯 Daily Goal Reminder',
      goalTitle,
      tz.TZDateTime.from(scheduled, tz.local),
      _getDetails(
        channelId: 'daily_goals',
        channelName: 'Daily Goals',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Schedule overdue alert ────────────────────────────────────────────────
  Future<void> scheduleOverdueAlert({
    required String taskId,
    required String taskTitle,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    final tomorrow9am =
        DateTime(now.year, now.month, now.day + 1, 9, 0);

    await _plugin.zonedSchedule(
      _notificationId(taskId, 'overdue'),
      '⚠️ Overdue Task',
      '$taskTitle is overdue. Tap to review.',
      tz.TZDateTime.from(tomorrow9am, tz.local),
      _getDetails(
        channelId: 'overdue',
        channelName: 'Overdue Alerts',
        androidPriority: Priority.high,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel notifications for a task ──────────────────────────────────────
  Future<void> cancelTaskNotifications(String taskId) async {
    await _plugin.cancel(_notificationId(taskId, 'deadline'));
    await _plugin.cancel(_notificationId(taskId, 'overdue'));
    await _plugin.cancel(_notificationId(taskId, 'goal'));
  }

  // ── Cancel all ────────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int _notificationId(String taskId, String type) {
    return '${taskId}_$type'.hashCode.abs() % 100000;
  }

  String _priorityPrefix(model.Priority priority) {
    switch (priority) {
      case model.Priority.urgent: return '🔴 ';
      case model.Priority.high:   return '🟠 ';
      case model.Priority.medium: return '🔵 ';
      case model.Priority.low:    return '⚫ ';
    }
  }

  Priority _androidPriority(model.Priority priority) {
    switch (priority) {
      case model.Priority.urgent: return Priority.max;
      case model.Priority.high:   return Priority.high;
      case model.Priority.medium: return Priority.defaultPriority;
      case model.Priority.low:    return Priority.low;
    }
  }
}