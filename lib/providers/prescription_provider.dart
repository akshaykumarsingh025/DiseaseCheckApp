import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../models/prescription.dart';
import '../services/prescription_service.dart';
import 'appointment_provider.dart';

/// Every prescription the signed-in doctor has written.
///
/// Deliberately allowed to surface its error: a denied query and a doctor with
/// no prescriptions yet must not render the same way. See
/// [PrescriptionService.getDoctorPrescriptions].
final doctorPrescriptionsProvider =
    FutureProvider<List<Prescription>>((ref) async {
  return PrescriptionService.getDoctorPrescriptions();
});

/// One patient as the doctor sees them: everything they have ever booked, plus
/// every prescription written for them.
class PatientRecord {
  final String patientId;
  final String patientName;
  final List<Appointment> appointments;
  final List<Prescription> prescriptions;

  const PatientRecord({
    required this.patientId,
    required this.patientName,
    required this.appointments,
    required this.prescriptions,
  });

  /// Consultations that actually happened — a cancelled slot is not a visit.
  List<Appointment> get consultations =>
      appointments.where((a) => a.status != 'cancelled').toList();

  DateTime? get lastVisit {
    final past = consultations.where((a) => a.isCompleted).toList();
    if (past.isEmpty) return null;
    return past.map((a) => a.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Appointment? get nextVisit {
    final upcoming = consultations.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Prescription? prescriptionFor(String appointmentId) {
    for (final rx in prescriptions) {
      if (rx.appointmentId == appointmentId) return rx;
    }
    return null;
  }
}

/// The doctor's patient list, built by joining appointments to prescriptions.
///
/// There is no `patients` collection to read — a patient exists, as far as the
/// doctor is concerned, because they booked at least one appointment. Grouping
/// here rather than in Firestore also means no extra index and no extra reads.
final doctorPatientsProvider = Provider<AsyncValue<List<PatientRecord>>>((ref) {
  final appointmentsAsync = ref.watch(userAppointmentsProvider);
  final prescriptionsAsync = ref.watch(doctorPrescriptionsProvider);

  // The appointment stream is the primary source; prescriptions merely enrich
  // it, so a prescription query that is still loading (or that failed) must not
  // hide the patient list.
  return appointmentsAsync.whenData((appointments) {
    final prescriptions = prescriptionsAsync.valueOrNull ?? const <Prescription>[];

    final byPatient = <String, List<Appointment>>{};
    final names = <String, String>{};
    for (final appointment in appointments) {
      byPatient.putIfAbsent(appointment.patientId, () => []).add(appointment);
      if (appointment.patientName.trim().isNotEmpty) {
        names[appointment.patientId] = appointment.patientName.trim();
      }
    }

    // A prescription can exist for a patient whose appointment document has
    // since been removed, so seed from prescriptions too rather than dropping
    // the record.
    final rxByPatient = <String, List<Prescription>>{};
    for (final rx in prescriptions) {
      rxByPatient.putIfAbsent(rx.patientId, () => []).add(rx);
      byPatient.putIfAbsent(rx.patientId, () => []);
      if (!names.containsKey(rx.patientId) && rx.patientName.trim().isNotEmpty) {
        names[rx.patientId] = rx.patientName.trim();
      }
    }

    final records = byPatient.entries.map((entry) {
      final patientAppointments = entry.value
        ..sort((a, b) => b.date.compareTo(a.date));
      final patientRx = (rxByPatient[entry.key] ?? [])
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return PatientRecord(
        patientId: entry.key,
        patientName: names[entry.key] ?? 'Unknown patient',
        appointments: patientAppointments,
        prescriptions: patientRx,
      );
    }).toList();

    // Most recently seen first, so today's patients are at the top.
    records.sort((a, b) {
      final aDate = a.appointments.isEmpty ? null : a.appointments.first.date;
      final bDate = b.appointments.isEmpty ? null : b.appointments.first.date;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return records;
  });
});
