import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/prescription.dart';
import '../providers/appointment_provider.dart';
import '../providers/prescription_provider.dart';
import '../services/prescription_service.dart';

/// The doctor's record of who they have seen and what they prescribed.
///
/// Until this existed the console showed only the live queue and the last ten
/// completed slots, and [PrescriptionService.getDoctorPrescriptions] was never
/// called from anywhere — so a prescription became unreachable the moment its
/// appointment scrolled out of that window.
class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() =>
      _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(doctorPrescriptionsProvider);
    ref.invalidate(userAppointmentsProvider);
  }

  bool _matches(String text) =>
      _query.isEmpty || text.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  // The field sits on the navy AppBar, so its colours are
                  // pinned rather than inherited — the dark theme would
                  // otherwise paint white text on this white fill.
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search patient or diagnosis',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon:
                        Icon(Icons.search, size: 20, color: Colors.grey.shade700),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.clear,
                        size: 18, color: Colors.grey.shade700),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabs,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Patients'),
                  Tab(text: 'Prescriptions'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildPatientsTab(),
          _buildPrescriptionsTab(),
        ],
      ),
    );
  }

  // ── Patients ───────────────────────────────────────────────────────────

  Widget _buildPatientsTab() {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return patientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildError('Could not load patients', e),
      data: (patients) {
        final visible =
            patients.where((p) => _matches(p.patientName)).toList();

        if (visible.isEmpty) {
          return _buildEmpty(
            Icons.people_outline,
            patients.isEmpty ? 'No patients yet' : 'No matching patients',
            patients.isEmpty
                ? 'Anyone who books a consultation will appear here, with their full visit history.'
                : 'Try a different name.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            itemBuilder: (context, i) => _buildPatientCard(visible[i]),
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(PatientRecord patient) {
    final consults = patient.consultations.length;
    final rxCount = patient.prescriptions.length;
    final last = patient.lastVisit;
    final next = patient.nextVisit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _PatientHistoryScreen(patientId: patient.patientId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  _initials(patient.patientName),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$consults consultation${consults == 1 ? '' : 's'}'
                      '  •  $rxCount prescription${rxCount == 1 ? '' : 's'}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next != null
                          ? 'Next: ${DateFormat('dd MMM').format(next.date)} at ${next.startTime}'
                          : last != null
                              ? 'Last seen ${DateFormat('dd MMM yyyy').format(last)}'
                              : 'No completed visits yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: next != null
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        fontWeight:
                            next != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ── Prescriptions ──────────────────────────────────────────────────────

  Widget _buildPrescriptionsTab() {
    final prescriptionsAsync = ref.watch(doctorPrescriptionsProvider);
    final appointments =
        ref.watch(userAppointmentsProvider).valueOrNull ?? const <Appointment>[];

    return prescriptionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildError('Could not load prescriptions', e),
      data: (prescriptions) {
        final visible = prescriptions
            .where((rx) => _matches('${rx.patientName} ${rx.diagnosis}'))
            .toList();

        if (visible.isEmpty) {
          return _buildEmpty(
            Icons.description_outlined,
            prescriptions.isEmpty
                ? 'No prescriptions written yet'
                : 'No matching prescriptions',
            prescriptions.isEmpty
                ? 'Prescriptions you write during or after a consultation are kept here permanently.'
                : 'Try a different patient name or diagnosis.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            itemBuilder: (context, i) => PrescriptionCard(
              prescription: visible[i],
              appointment: _appointmentFor(appointments, visible[i]),
              showPatientName: true,
            ),
          ),
        );
      },
    );
  }

  /// The appointment a prescription was written against, if its document still
  /// exists — editing needs it, because the form is keyed on the appointment.
  static Appointment? _appointmentFor(
    List<Appointment> appointments,
    Prescription rx,
  ) {
    for (final a in appointments) {
      if (a.appointmentId == rx.appointmentId) return a;
    }
    return null;
  }

  // ── Shared ─────────────────────────────────────────────────────────────

  Widget _buildEmpty(IconData icon, String title, String body) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Center(
          child: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildError(String title, Object error) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
        const SizedBox(height: 16),
        Center(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text('$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// One patient's full history
// ─────────────────────────────────────────────────────────────────────────

/// Written out rather than using `firstWhereOrNull`, which lives in
/// package:collection and is not a declared dependency here.
PatientRecord? _findPatient(List<PatientRecord>? patients, String patientId) {
  if (patients == null) return null;
  for (final p in patients) {
    if (p.patientId == patientId) return p;
  }
  return null;
}

class _PatientHistoryScreen extends ConsumerWidget {
  const _PatientHistoryScreen({required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _findPatient(patientsAsync.valueOrNull, patientId)?.patientName ??
              'Patient',
        ),
      ),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (patients) {
          final patient = _findPatient(patients, patientId);
          if (patient == null) {
            return const Center(child: Text('This patient has no records.'));
          }

          final consults = patient.consultations;
          if (consults.isEmpty && patient.prescriptions.isEmpty) {
            return const Center(child: Text('No visits recorded yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummary(patient),
              const SizedBox(height: 20),
              const Text('Visit history',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...consults.map((a) => _buildVisitCard(context, patient, a)),
              if (consults.isEmpty)
                Text('No appointments on record.',
                    style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              const Text('Prescriptions',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (patient.prescriptions.isEmpty)
                Text('None written yet.',
                    style: TextStyle(color: Colors.grey.shade600))
              else
                ...patient.prescriptions.map(
                  (rx) => PrescriptionCard(
                    prescription: rx,
                    appointment: _DoctorPatientsScreenState._appointmentFor(
                        patient.appointments, rx),
                    showPatientName: false,
                  ),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(PatientRecord patient) {
    final last = patient.lastVisit;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${patient.consultations.length}', 'Consults', Colors.blue),
            _stat('${patient.prescriptions.length}', 'Rx', Colors.green),
            _stat(
              last == null ? '—' : DateFormat('dd MMM').format(last),
              'Last visit',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color colour) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: colour)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildVisitCard(
    BuildContext context,
    PatientRecord patient,
    Appointment appointment,
  ) {
    final rx = patient.prescriptionFor(appointment.appointmentId);
    final done = appointment.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_outline : Icons.schedule,
              color: done ? Colors.grey : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('dd MMM yyyy').format(appointment.date)}'
                    '  •  ${appointment.startTime}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rx == null
                        ? 'No prescription'
                        : rx.diagnosis.isEmpty
                            ? 'Prescription written'
                            : rx.diagnosis,
                    style: TextStyle(
                      fontSize: 12,
                      color: rx == null
                          ? Colors.orange.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push(
                '/write-prescription',
                extra: {'appointment': appointment},
              ),
              child: Text(rx == null ? 'Write Rx' : 'Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Prescription card, shared by both tabs and the patient history page
// ─────────────────────────────────────────────────────────────────────────

class PrescriptionCard extends StatefulWidget {
  const PrescriptionCard({
    super.key,
    required this.prescription,
    required this.appointment,
    required this.showPatientName,
  });

  final Prescription prescription;

  /// Null when the appointment document no longer exists. Editing is disabled
  /// in that case rather than opening a form with nothing to save against.
  final Appointment? appointment;
  final bool showPatientName;

  @override
  State<PrescriptionCard> createState() => _PrescriptionCardState();
}

class _PrescriptionCardState extends State<PrescriptionCard> {
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await PrescriptionService.sharePrescriptionPdf(widget.prescription);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rx = widget.prescription;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.medical_information,
                      color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.showPatientName
                            ? rx.patientName
                            : (rx.diagnosis.isNotEmpty
                                ? rx.diagnosis
                                : 'Prescription'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.showPatientName && rx.diagnosis.isNotEmpty
                            ? '${rx.diagnosis}  •  ${DateFormat('dd MMM yyyy').format(rx.appointmentDate)}'
                            : DateFormat('dd MMM yyyy')
                                .format(rx.appointmentDate),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rx.medicines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...rx.medicines.take(3).map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle,
                                    size: 6, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${m.name}  •  ${m.dosage}, ${m.frequency}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (rx.medicines.length > 3)
                      Text('+ ${rx.medicines.length - 3} more',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: _busy
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.appointment == null
                        ? null
                        : () => context.push(
                              '/write-prescription',
                              extra: {'appointment': widget.appointment},
                            ),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3460),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
