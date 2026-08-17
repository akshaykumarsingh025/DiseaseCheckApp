import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../config/feature_flags.dart';
import '../models/appointment.dart';
import 'notification_service.dart';

class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String get _doctorId => FeatureFlags.doctorUserId;
  static const int _slotDurationMinutes = 20;
  static const int _startHour = 10;
  static const int _endHour = 20;
  static const int _opdFee = 111;
  static const Set<String> _activeBookingStatuses = {
    'booked',
    'confirmed',
    'pending_payment',
  };

  static Future<List<DateTime>> getAvailableDates({int daysAhead = 14}) async {
    final dates = <DateTime>[];
    final now = DateTime.now();
    for (int i = 0; i < daysAhead; i++) {
      final date =
          DateTime(now.year, now.month, now.day).add(Duration(days: i));
      if (date.weekday != DateTime.sunday || i == 0) {
        dates.add(date);
      }
    }
    return dates;
  }

  static Future<List<TimeSlot>> getAvailableSlots(DateTime date) async {
    try {
      final slots = _generateSlotsForDate(date);
      final bookedSlots = await _getBookedSlots(date);
      return slots.where((slot) {
        return !bookedSlots.any((booked) =>
            booked.startTime == slot.startTime &&
            booked.endTime == slot.endTime);
      }).toList();
    } catch (_) {
      return _generateSlotsForDate(date);
    }
  }

  static List<TimeSlot> _generateSlotsForDate(DateTime date) {
    final slots = <TimeSlot>[];
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final endHour = date.weekday == DateTime.sunday ? 18 : _endHour;

    for (int hour = _startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += _slotDurationMinutes) {
        final slotStart =
            DateTime(date.year, date.month, date.day, hour, minute);
        final slotEnd =
            slotStart.add(const Duration(minutes: _slotDurationMinutes));

        if (isToday && slotStart.isBefore(now.add(const Duration(hours: 1)))) {
          continue;
        }

        if (slotEnd
            .isAfter(DateTime(date.year, date.month, date.day, endHour))) {
          continue;
        }

        final startStr =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final endMinute = minute + _slotDurationMinutes;
        final endHourCalc = hour + (endMinute ~/ 60);
        final endMinuteCalc = endMinute % 60;
        final endStr =
            '${endHourCalc.toString().padLeft(2, '0')}:${endMinuteCalc.toString().padLeft(2, '0')}';

        slots.add(TimeSlot(
          startTime: startStr,
          endTime: endStr,
          startDateTime: slotStart,
          endDateTime: slotEnd,
        ));
      }
    }

    return slots;
  }

  static Future<List<Appointment>> _getBookedSlots(DateTime date) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId)
          .where('status',
              whereIn: ['booked', 'confirmed', 'pending_payment']).get();

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      return snapshot.docs
          .map((doc) => Appointment.fromJson(doc.data()))
          .where((apt) {
        try {
          return apt.date.toIso8601String().startsWith(dateStr);
        } catch (_) {
          return false;
        }
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> hasActiveBookingAtTime({
    required DateTime date,
    required String startTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('status',
              whereIn: ['booked', 'confirmed', 'pending_payment']).get();

      for (final doc in snapshot.docs) {
        final apt = Appointment.fromJson(doc.data());
        try {
          final aptDateStr =
              '${apt.date.year}-${apt.date.month.toString().padLeft(2, '0')}-${apt.date.day.toString().padLeft(2, '0')}';
          if (aptDateStr == dateStr && apt.startTime == startTime) {
            return true;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  static Future<List<Appointment>> getUserAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final fieldName = user.uid == _doctorId ? 'doctorId' : 'patientId';
      final snapshot = await _firestore
          .collection('appointments')
          .where(fieldName, isEqualTo: user.uid)
          .get();

      return snapshot.docs.map((doc) => Appointment.fromJson(doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  static Stream<List<Appointment>> getUserAppointmentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    final fieldName = user.uid == _doctorId ? 'doctorId' : 'patientId';

    return _firestore
        .collection('appointments')
        .where(fieldName, isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Appointment.fromJson(doc.data());
                } catch (_) {
                  return null;
                }
              })
              .whereType<Appointment>()
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        })
        .handleError((error) {
          // Log but still return an empty list to avoid crashing the UI
          debugPrint('AppointmentService: Error fetching appointments: $error');
          return <Appointment>[];
        });
  }

  static Future<Appointment> createAppointment({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String patientName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final alreadyBooked = await hasActiveBookingAtTime(
      date: date,
      startTime: startTime,
    );
    if (alreadyBooked) {
      throw Exception(
        'You already have an appointment at this time. Please choose another slot.',
      );
    }

    final appointmentId = _appointmentIdFor(date, startTime);
    final meetingId = 'meet_${const Uuid().v4().substring(0, 8)}';

    final appointment = Appointment(
      appointmentId: appointmentId,
      patientId: user.uid,
      patientName: patientName,
      doctorId: _doctorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: 'pending_payment',
      amount: _opdFee,
      meetingId: meetingId,
    );

    await _saveAppointmentIfSlotAvailable(appointment);

    _notifyDoctorOnBooking(appointment).catchError((_) {});

    return appointment;
  }

  static Future<void> confirmPayment(String appointmentId,
      {String? paymentId, String? orderId}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'booked',
          'paymentId': paymentId,
          'orderId': orderId,
        });
        return;
      } catch (e) {
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        debugPrint('AppointmentService: confirmPayment failed after retries: $e');
      }
    }
  }

  static Future<Appointment> createEmergencyAppointment({
    required String patientName,
  }) async {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final end = now.add(const Duration(minutes: _slotDurationMinutes));
    final startTime = _timeString(now);
    final endTime = _timeString(end);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final alreadyBooked = await hasActiveBookingAtTime(
      date: date,
      startTime: startTime,
    );
    if (alreadyBooked) {
      throw Exception(
        'You already have an appointment at this time.',
      );
    }

    final appointmentId = _appointmentIdFor(date, startTime);
    final appointment = Appointment(
      appointmentId: appointmentId,
      patientId: user.uid,
      patientName: patientName,
      doctorId: _doctorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: 'booked',
      amount: _opdFee,
      meetingId: 'meet_${const Uuid().v4().substring(0, 8)}',
    );

    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .set(appointment.toJson());

    _notifyDoctorOnBooking(appointment).catchError((_) {});

    return appointment;
  }

  static Future<void> _saveAppointmentIfSlotAvailable(
    Appointment appointment,
  ) async {
    final appointmentRef =
        _firestore.collection('appointments').doc(appointment.appointmentId);

    try {
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(appointmentRef);
        if (existing.exists) {
          final existingAppointment = Appointment.fromJson(existing.data()!);
          if (_activeBookingStatuses.contains(existingAppointment.status)) {
            throw Exception(
              'This OPD slot is already booked. Please choose another time.',
            );
          }
        }

        transaction.set(appointmentRef, appointment.toJson());
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Unable to confirm slot availability. Please try again.',
        );
      }
      rethrow;
    }
  }

  static String _appointmentIdFor(DateTime date, String startTime) {
    final dateKey =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final timeKey = startTime.replaceAll(':', '');
    return '${_doctorId}_${dateKey}_$timeKey';
  }

  static String _timeString(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'cancelled',
    });
    final id = appointmentId.hashCode & 0x7FFFFFFF;
    await NotificationService.cancelReminder(id);
    // OpdReminderService drops these on its next sync anyway, but doing it here
    // means the alerts are gone before the user leaves the screen.
    await NotificationService.cancelOpdAlerts(id);
  }

  static Future<void> completeAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'completed',
    });
  }

  static int get opdFee => _opdFee;
  static String get doctorId => _doctorId;

  static Future<void> _notifyDoctorOnBooking(Appointment appointment) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'new_booking',
        'doctorId': _doctorId,
        'patientId': appointment.patientId,
        'patientName': appointment.patientName,
        'appointmentId': appointment.appointmentId,
        'date': appointment.date.toIso8601String(),
        'startTime': appointment.startTime,
        'endTime': appointment.endTime,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('AppointmentService: Failed to notify doctor: $e');
    }
  }

  // Reminder scheduling deliberately does NOT happen here any more.
  //
  // It used to, which meant reminders only ever existed on the device that ran
  // createAppointment — the patient's. The doctor was never alerted that a slot
  // was about to start. OpdReminderService now arms them from the appointment
  // stream instead, so both sides get the same ladder of alerts, and a
  // cancelled or rescheduled slot re-arms correctly rather than leaving a stale
  // alarm behind. See lib/services/opd_reminder_service.dart.
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.startDateTime,
    required this.endDateTime,
  });

  String get displayTime {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startHour = int.parse(startParts[0]);
    final startMin = startParts[1];
    final endHour = int.parse(endParts[0]);
    final endMin = endParts[1];
    final startAmPm = startHour >= 12 ? 'PM' : 'AM';
    final endAmPm = endHour >= 12 ? 'PM' : 'AM';
    final startDisplay =
        '${startHour > 12 ? startHour - 12 : startHour}:$startMin $startAmPm';
    final endDisplay =
        '${endHour > 12 ? endHour - 12 : endHour}:$endMin $endAmPm';
    return '$startDisplay - $endDisplay';
  }
}
