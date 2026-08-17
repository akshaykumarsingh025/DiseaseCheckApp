import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../utils/doctor_info.dart';
import 'notification_service.dart';

/// Keeps each device's OPD alarms in step with its own appointment list.
///
/// Both sides run this against the same stream: the patient's phone schedules
/// "Your consultation with Dr Deepika Singh", the doctor's schedules
/// "Consultation with <patient>". Neither previously got anything — the
/// reminders that existed were scheduled inside `createAppointment`, which only
/// ever runs on the patient's device, so the doctor was never told a slot was
/// about to start.
///
/// These are local alarms, not push. That is enough because the start time is
/// known the moment the slot is booked and never moves — but it does mean a
/// device only picks up a new booking once the app has been opened while
/// signed in. A booking made 10 minutes before its slot on a phone that is
/// then never opened will not alert.
class OpdReminderService {
  const OpdReminderService._();

  /// appointmentId -> the state we last scheduled for it. Rescheduling on every
  /// stream tick would otherwise cancel and re-arm every alarm several times a
  /// second while the console is open.
  static final Map<String, String> _scheduled = {};

  /// Re-arms alarms so they match [appointments] exactly.
  ///
  /// Cancelled, completed, rescheduled and past appointments lose their alarms;
  /// everything still ahead gains them.
  static Future<void> sync(
    List<Appointment> appointments, {
    required bool asDoctor,
  }) async {
    final now = DateTime.now();

    final wanted = <String, Appointment>{};
    for (final appointment in appointments) {
      if (appointment.status == 'cancelled' ||
          appointment.status == 'completed') {
        continue;
      }
      final start = _startOf(appointment);
      if (start == null || !start.isAfter(now)) continue;
      wanted[appointment.appointmentId] = appointment;
    }

    for (final id in _scheduled.keys.toList()) {
      final appointment = wanted[id];
      if (appointment != null && _signature(appointment) == _scheduled[id]) {
        continue;
      }
      await NotificationService.cancelOpdAlerts(_baseId(id));
      _scheduled.remove(id);
    }

    for (final appointment in wanted.values) {
      final signature = _signature(appointment);
      if (_scheduled[appointment.appointmentId] == signature) continue;

      final start = _startOf(appointment)!;
      final who = asDoctor
          ? (appointment.patientName.trim().isEmpty
              ? 'your patient'
              : appointment.patientName.trim())
          : DoctorInfo.name;

      await NotificationService.scheduleOpdAlerts(
        baseId: _baseId(appointment.appointmentId),
        title: asDoctor ? 'OPD consultation' : 'Your OPD consultation',
        body: (minutesBefore) => _body(
          minutesBefore: minutesBefore,
          who: who,
          startTime: appointment.startTime,
          asDoctor: asDoctor,
        ),
        startsAt: start,
      );

      _scheduled[appointment.appointmentId] = signature;
    }
  }

  /// Drops every alarm this service armed. Used on sign-out so the next account
  /// on the device is not alerted about someone else's consultation.
  static Future<void> clear() async {
    for (final id in _scheduled.keys.toList()) {
      await NotificationService.cancelOpdAlerts(_baseId(id));
    }
    _scheduled.clear();
  }

  static String _body({
    required int minutesBefore,
    required String who,
    required String startTime,
    required bool asDoctor,
  }) {
    final subject = 'Consultation with $who';
    switch (minutesBefore) {
      case 0:
        return asDoctor
            ? '$subject starts now. Open the console to join.'
            : '$subject is starting now. Tap to join the video call.';
      case 5:
        return '$subject starts in 5 minutes ($startTime). Get ready to join.';
      case 60:
        return '$subject starts in 1 hour, at $startTime.';
      default:
        return '$subject starts in $minutesBefore minutes, at $startTime.';
    }
  }

  /// Everything that would change when an alarm should fire, or whether it
  /// should fire at all.
  static String _signature(Appointment a) =>
      '${a.date.toIso8601String()}|${a.startTime}|${a.status}|${a.patientName}';

  static int _baseId(String appointmentId) =>
      appointmentId.hashCode & 0x7FFFFFFF;

  /// The appointment's wall-clock start, or null if `startTime` is malformed —
  /// a bad value must not take down the whole sync.
  static DateTime? _startOf(Appointment appointment) {
    try {
      final parts = appointment.startTime.split(':');
      return DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      debugPrint(
        'OpdReminderService: bad startTime "${appointment.startTime}" '
        'on ${appointment.appointmentId}: $e',
      );
      return null;
    }
  }
}
