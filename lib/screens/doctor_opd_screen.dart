import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';

class DoctorOpdScreen extends ConsumerWidget {
  const DoctorOpdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appointmentsAsync = ref.watch(userAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_shared_outlined),
            onPressed: () => context.push('/doctor-patients'),
            tooltip: 'Patient records',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userAppointmentsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: appointmentsAsync.when(
        data: (appointments) => SafeArea(
          child: _buildBody(context, ref, appointments, isDark),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading appointments: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<Appointment> allAppointments, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter out cancelled
    final appointments = allAppointments.where((a) => a.status != 'cancelled').toList();

    final activeAppointments = appointments.where((a) => a.isActive).toList();
    final todayUpcoming = appointments.where((a) {
      final aptDate = DateTime(a.date.year, a.date.month, a.date.day);
      return aptDate.isAtSameMomentAs(today) && a.isUpcoming;
    }).toList();
    final futureAppointments = appointments.where((a) {
      final aptDate = DateTime(a.date.year, a.date.month, a.date.day);
      return aptDate.isAfter(today) && a.isUpcoming;
    }).toList();
    final pastAppointments = appointments.where((a) => a.isCompleted).take(10).toList();

    if (appointments.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(userAppointmentsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsRow(activeAppointments.length, todayUpcoming.length, futureAppointments.length, isDark),
            const SizedBox(height: 12),
            _buildRecordsButton(context),
            const SizedBox(height: 20),

            // Active consultations (LIVE)
            if (activeAppointments.isNotEmpty) ...[
              _buildSectionTitle(context, '🔴 LIVE — Active Consultations', Colors.green),
              const SizedBox(height: 8),
              ...activeAppointments.map((a) => _buildActiveCard(context, a, isDark)),
              const SizedBox(height: 20),
            ],

            // Today's upcoming
            if (todayUpcoming.isNotEmpty) ...[
              _buildSectionTitle(context, "📋 Today's Queue", Colors.blue),
              const SizedBox(height: 8),
              ...todayUpcoming.map((a) => _buildUpcomingCard(context, a, isDark)),
              const SizedBox(height: 20),
            ],

            // Future appointments
            if (futureAppointments.isNotEmpty) ...[
              _buildSectionTitle(context, '📅 Upcoming Days', Colors.purple),
              const SizedBox(height: 8),
              ...futureAppointments.map((a) => _buildUpcomingCard(context, a, isDark)),
              const SizedBox(height: 20),
            ],

            // Past
            if (pastAppointments.isNotEmpty) ...[
              _buildSectionTitle(context, '✅ Recent Completed', Colors.grey),
              const SizedBox(height: 8),
              ...pastAppointments.map((a) => _buildPastCard(context, a, isDark)),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No appointments yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Patient appointments will appear here once booked.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            // Reachable even with an empty queue — past patients and their
            // prescriptions live behind this and do not depend on today.
            _buildRecordsButton(context),
          ],
        ),
      ),
    );
  }

  /// Entry point to the doctor's full patient and prescription history.
  Widget _buildRecordsButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push('/doctor-patients'),
      icon: const Icon(Icons.folder_shared_outlined, size: 18),
      label: const Text('Patient Records & Prescriptions'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F3460),
        side: const BorderSide(color: Color(0xFF0F3460)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatsRow(int active, int todayQueue, int future, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Active', '$active', Colors.green, isDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Today', '$todayQueue', Colors.blue, isDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Upcoming', '$future', Colors.purple, isDark)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Card(
      color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }

  // ── Active appointment card (LIVE) ──

  Widget _buildActiveCard(BuildContext context, Appointment appointment, bool isDark) {
    return Card(
      color: isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.green.shade400, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.videocam, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${appointment.startTime} - ${appointment.endTime}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/video-call', extra: {'appointment': appointment}),
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('Open Consultation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/write-prescription', extra: {'appointment': appointment}),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Rx', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    side: BorderSide(color: Colors.green.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Upcoming appointment card ──

  Widget _buildUpcomingCard(BuildContext context, Appointment appointment, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person, color: Colors.blue.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM').format(appointment.date)} • ${appointment.startTime} - ${appointment.endTime}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Check if within 5 min buffer — allow starting early
            Builder(builder: (context) {
              final startParts = appointment.startTime.split(':');
              final startDt = DateTime(
                appointment.date.year, appointment.date.month, appointment.date.day,
                int.parse(startParts[0]), int.parse(startParts[1]),
              );
              final canStartEarly = DateTime.now().isAfter(startDt.subtract(const Duration(minutes: 5)));

              if (canStartEarly) {
                return ElevatedButton(
                  onPressed: () => context.push('/video-call', extra: {'appointment': appointment}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold)),
                );
              }
              return Text(
                appointment.startTime,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700),
              );
            }),
            IconButton(
              onPressed: () => context.push('/write-prescription', extra: {'appointment': appointment}),
              icon: Icon(Icons.edit_note, color: Colors.blue.shade700),
              tooltip: 'Write Prescription',
            ),
          ],
        ),
      ),
    );
  }

  // ── Past appointment card ──

  Widget _buildPastCard(BuildContext context, Appointment appointment, bool isDark) {
    return Card(
      color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.patientName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(appointment.date)} • ${appointment.startTime}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  appointment.status,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/write-prescription', extra: {'appointment': appointment}),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Write / Edit Prescription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F3460),
                  side: const BorderSide(color: Color(0xFF0F3460)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
