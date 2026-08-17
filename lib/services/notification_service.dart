import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final androidPlugin = _android;
      await androidPlugin?.requestNotificationsPermission();
      _exactAlarmsAllowed =
          await androidPlugin?.canScheduleExactNotifications() ?? true;
    }
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Clears the silent 60/30/10-minute reminders an older build of the app
  /// scheduled for an appointment.
  ///
  /// Nothing schedules those any more — OPD alerts replaced them, see
  /// [scheduleOpdAlerts] — but an alarm armed by a previous version survives
  /// the update, so cancelling one must still remove them or the user gets both
  /// sets of notifications for a slot they already cancelled.
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
  // OPD consultation alerts
  // ---------------------------------------------------------------------------
  //
  // These are the alerts both sides of a video consultation get before it
  // starts. They are deliberately separate from the generic appointment
  // reminders above: those are quiet, inexact, best-effort nudges, whereas
  // missing an OPD slot wastes a paid 20-minute booking and the doctor's time.
  // So this channel makes a sound, vibrates, and is scheduled EXACTLY.

  static const String _opdChannelId = 'opd_alerts';
  static const String _opdChannelName = 'OPD Consultation Alerts';
  static const String _opdChannelDesc =
      'Sound and vibration alerts before your video consultation starts';

  /// Minutes before the slot at which each alert fires. `0` is the slot itself.
  ///
  /// An Android channel's importance and sound are fixed when the channel is
  /// first created and cannot be changed by a later app update, so this channel
  /// id must never be reused with different settings.
  static const List<int> opdAlertOffsets = [60, 30, 10, 5, 0];

  /// Whether Android will honour an exact alarm. Android 12+ gates this behind
  /// a separate user grant; without it `zonedSchedule` still delivers, but the
  /// system is free to defer it — which for a "starts in 5 minutes" alert can
  /// mean arriving after the consultation is over.
  static bool _exactAlarmsAllowed = true;

  static bool get exactAlarmsAllowed => _exactAlarmsAllowed;

  static final Int64List _opdVibration =
      Int64List.fromList([0, 600, 300, 600, 300, 900]);

  static NotificationDetails get _opdDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          _opdChannelId,
          _opdChannelName,
          channelDescription: _opdChannelDesc,
          // Importance.max, not high: several OEM skins only raise a heads-up
          // banner with sound at max, and a silent banner defeats the point.
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _opdVibration,
          enableLights: true,
          ledColor: const Color(0xFF0F3460),
          ledOnMs: 1000,
          ledOffMs: 500,
          ticker: 'OPD consultation',
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // Breaks through Focus modes, which is the iOS equivalent of the
          // heads-up banner above.
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  /// Notification id for one rung of one consultation's alert ladder.
  ///
  /// Derived purely from [baseId] so [cancelOpdAlerts] can remove exactly this
  /// consultation's alerts without tracking the ids anywhere.
  static int _opdAlertId(int baseId, int index) =>
      ((baseId & 0x03FFFFFF) * opdAlertOffsets.length + index) & 0x7FFFFFFF;

  /// Schedules the whole ladder of alerts for one consultation, replacing any
  /// previously scheduled for the same [baseId].
  ///
  /// [body] is called with the minutes remaining so the caller can word each
  /// rung differently ("in 1 hour" vs "starting now").
  static Future<void> scheduleOpdAlerts({
    required int baseId,
    required String title,
    required String Function(int minutesBefore) body,
    required DateTime startsAt,
  }) async {
    await cancelOpdAlerts(baseId);

    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < opdAlertOffsets.length; i++) {
      final minutesBefore = opdAlertOffsets[i];
      final when = tz.TZDateTime.from(
        startsAt.subtract(Duration(minutes: minutesBefore)),
        tz.local,
      );
      // Rungs already in the past are skipped rather than fired late — booking
      // a slot 20 minutes out should not immediately raise the 60- and
      // 30-minute warnings.
      if (!when.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        _opdAlertId(baseId, i),
        title,
        body(minutesBefore),
        when,
        _opdDetails,
        androidScheduleMode: _exactAlarmsAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'opd_alert',
      );
    }
  }

  static Future<void> cancelOpdAlerts(int baseId) async {
    for (var i = 0; i < opdAlertOffsets.length; i++) {
      await _plugin.cancel(_opdAlertId(baseId, i));
    }
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  static const String _exactAlarmAskedKey = 'opd_exact_alarm_prompted';

  /// Asks for everything the OPD alerts need, at most once for the exact-alarm
  /// grant.
  ///
  /// Notification permission is a normal runtime prompt and is safe to request
  /// repeatedly — Android only shows it while the answer is undecided. The
  /// exact-alarm grant is not a prompt at all: on Android 12+ it throws the
  /// user out to a system settings page, so it is asked for once and then left
  /// alone. If they decline, alerts still arrive, just not guaranteed on time.
  static Future<void> ensureOpdAlertPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }
    if (!Platform.isAndroid) return;

    final android = _android;
    if (android == null) return;

    await android.requestNotificationsPermission();

    _exactAlarmsAllowed = await android.canScheduleExactNotifications() ?? true;
    if (_exactAlarmsAllowed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_exactAlarmAskedKey) ?? false) return;
      await prefs.setBool(_exactAlarmAskedKey, true);
    } catch (_) {
      // Without prefs we cannot tell whether we already asked; asking once per
      // launch is still better than never asking.
    }

    await android.requestExactAlarmsPermission();
    _exactAlarmsAllowed = await android.canScheduleExactNotifications() ?? false;
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
