import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'appointment_reminders';
  static const String _channelName = 'Appointment Reminders';
  static const String _channelDesc =
      'Reminders for upcoming doctor appointments';

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime appointmentTime,
    int reminderMinutesBefore = 30,
  }) async {
    final scheduledTime = tz.TZDateTime.from(
      appointmentTime.subtract(Duration(minutes: reminderMinutesBefore)),
      tz.local,
    );

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id & 0x7FFFFFFF,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'appointment_reminder',
    );
  }

  static Future<void> scheduleMultiReminders({
    required int id,
    required String title,
    required String body,
    required DateTime appointmentTime,
  }) async {
    final reminders = [60, 30, 10];
    for (int i = 0; i < reminders.length; i++) {
      await scheduleAppointmentReminder(
        // Mask to a 32-bit int: `id * 10 + i` can otherwise exceed the
        // platform notification-id limit (2^31 - 1) and crash.
        id: (id * 10 + i) & 0x7FFFFFFF,
        title: title,
        body: reminders[i] == 60
            ? 'Appointment in 1 hour'
            : reminders[i] == 30
                ? 'Appointment in 30 minutes'
                : 'Appointment starting soon!',
        appointmentTime: appointmentTime,
        reminderMinutesBefore: reminders[i],
      );
    }
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id & 0x7FFFFFFF);
    for (int i = 0; i < 3; i++) {
      await _plugin.cancel((id * 10 + i) & 0x7FFFFFFF);
    }
  }

  static Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // Cycle / period reminders
  // ---------------------------------------------------------------------------

  static const String _cycleChannelId = 'cycle_reminders';
  static const String _cycleChannelName = 'Cycle Reminders';
  static const String _cycleChannelDesc =
      'Reminders for your period, fertile window and daily log';

  // Fixed notification ids so reminders can be cancelled/replaced cleanly.
  static const int _idPeriodSoon = 900001;
  static const int _idFertileStart = 900002;
  static const int _idOvulation = 900003;
  static const int _idDailyLog = 900004;

  static NotificationDetails get _cycleDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _cycleChannelId,
          _cycleChannelName,
          channelDescription: _cycleChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );

  static Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    int hour = 9,
    int minute = 0,
    String payload = 'cycle_reminder',
  }) async {
    var scheduled = tz.TZDateTime(
      tz.local,
      when.year,
      when.month,
      when.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id & 0x7FFFFFFF,
      title,
      body,
      scheduled,
      _cycleDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// (Re)schedules cycle reminders. Pass null for any prediction you don't
  /// have yet; existing cycle reminders are always cleared first.
  static Future<void> schedulePeriodReminders({
    DateTime? nextPeriod,
    DateTime? fertileStart,
    DateTime? ovulationDay,
    int daysBeforePeriod = 2,
  }) async {
    await cancelPeriodReminders();

    if (nextPeriod != null) {
      final remindOn = nextPeriod.subtract(Duration(days: daysBeforePeriod));
      await _scheduleAt(
        id: _idPeriodSoon,
        title: 'Period coming up 🩸',
        body: daysBeforePeriod <= 0
            ? 'Your period is expected today. Keep supplies handy.'
            : 'Your period is expected in $daysBeforePeriod days. Keep supplies handy.',
        when: remindOn,
      );
    }

    if (fertileStart != null) {
      await _scheduleAt(
        id: _idFertileStart,
        title: 'Fertile window starting 🌸',
        body:
            'Your fertile window begins today. This is your higher-chance-of-conception phase.',
        when: fertileStart,
      );
    }

    if (ovulationDay != null) {
      await _scheduleAt(
        id: _idOvulation,
        title: 'Ovulation day ✨',
        body: 'Today is your estimated ovulation day — peak fertility.',
        when: ovulationDay,
      );
    }
  }

  /// A daily repeating reminder to log symptoms/flow, at the given time.
  static Future<void> scheduleDailyLogReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_idDailyLog & 0x7FFFFFFF);

    var scheduled = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      hour,
      minute,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idDailyLog & 0x7FFFFFFF,
      'How are you feeling today? 💗',
      'Take a moment to log your flow, symptoms and mood.',
      scheduled,
      _cycleDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'cycle_daily_log',
    );
  }

  static Future<void> cancelDailyLogReminder() async {
    await _plugin.cancel(_idDailyLog & 0x7FFFFFFF);
  }

  static Future<void> cancelPeriodReminders() async {
    await _plugin.cancel(_idPeriodSoon & 0x7FFFFFFF);
    await _plugin.cancel(_idFertileStart & 0x7FFFFFFF);
    await _plugin.cancel(_idOvulation & 0x7FFFFFFF);
  }

  // ---------------------------------------------------------------------------
  // Medication / supplement reminders
  // ---------------------------------------------------------------------------

  static const String _medChannelId = 'medication_reminders';
  static const String _medChannelName = 'Medication Reminders';
  static const String _medChannelDesc =
      'Reminders to take your medicines and supplements';

  /// A daily repeating medication reminder at the given time.
  static Future<void> scheduleDailyMedReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(id & 0x7FFFFFFF);

    var scheduled = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      hour,
      minute,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id & 0x7FFFFFFF,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _medChannelId,
          _medChannelName,
          channelDescription: _medChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medication_reminder',
    );
  }

  static Future<void> cancelById(int id) async {
    await _plugin.cancel(id & 0x7FFFFFFF);
  }

  // ---------------------------------------------------------------------------
  // Daily wellness nudge (personalized daily reminder)
  // ---------------------------------------------------------------------------

  static const int _idWellness = 900010;

  static Future<void> scheduleDailyWellnessReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_idWellness & 0x7FFFFFFF);

    var scheduled = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      hour,
      minute,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idWellness & 0x7FFFFFFF,
      'Your daily wellness check 💧',
      'Log your water, sleep and steps — and see today\'s health tip.',
      scheduled,
      _cycleDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'wellness_reminder',
    );
  }

  static Future<void> cancelDailyWellnessReminder() async {
    await _plugin.cancel(_idWellness & 0x7FFFFFFF);
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id & 0x7FFFFFFF, title, body, details);
  }
}
