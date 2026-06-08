import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService();
});

final availableDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  return AppointmentService.getAvailableDates();
});

final availableSlotsProvider = FutureProvider.family<List<TimeSlot>, DateTime>((ref, date) async {
  final selectedDay = DateTime(date.year, date.month, date.day);
  return AppointmentService.getAvailableSlots(selectedDay);
});

final userAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  return AppointmentService.getUserAppointmentsStream();
});

final upcomingAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(userAppointmentsProvider).valueOrNull ?? [];
  return appointments.where((a) => a.isUpcoming && a.status != 'cancelled').toList();
});

final activeAppointmentProvider = Provider<Appointment?>((ref) {
  final appointments = ref.watch(userAppointmentsProvider).valueOrNull ?? [];
  try {
    return appointments.firstWhere((a) => a.isActive && a.status != 'cancelled');
  } catch (_) {
    return null;
  }
});

final pastAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(userAppointmentsProvider).valueOrNull ?? [];
  return appointments.where((a) => a.isCompleted || a.status == 'completed').toList();
});
