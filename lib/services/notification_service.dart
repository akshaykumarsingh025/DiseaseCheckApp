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
