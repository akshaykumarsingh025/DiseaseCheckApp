import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../config/feature_flags.dart';
import '../providers/appointment_provider.dart';
import '../providers/profile_provider.dart';
import '../services/appointment_service.dart';
import '../services/payment_service.dart';
import '../models/appointment.dart';
import '../utils/doctor_info.dart';

class OnlineOpdScreen extends ConsumerStatefulWidget {
  const OnlineOpdScreen({super.key});

  @override
  ConsumerState<OnlineOpdScreen> createState() => _OnlineOpdScreenState();
}

class _OnlineOpdScreenState extends ConsumerState<OnlineOpdScreen> {
  DateTime? _selectedDate;
  TimeSlot? _selectedSlot;
  bool _isBooking = false;
  PaymentService? _paymentService;
  Appointment? _pendingAppointment;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(
      onSuccess: _onPaymentSuccess,
      onFailure: _onPaymentFailure,
    );
  }

  @override
  void dispose() {
    _paymentService?.dispose();
    super.dispose();
  }

  void _onPaymentSuccess(Map<String, dynamic> response) async {
    if (_pendingAppointment != null) {
      await AppointmentService.confirmPayment(
        _pendingAppointment!.appointmentId,
        paymentId: response['paymentId'] as String?,
        orderId: response['orderId'] as String?,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(userAppointmentsProvider);
        setState(() {
          _isBooking = false;
          _pendingAppointment = null;
        });
      }
    }
  }

  void _onPaymentFailure(String error) async {
    final pendingAppointment = _pendingAppointment;
    if (pendingAppointment != null) {
      await AppointmentService.cancelAppointment(
        pendingAppointment.appointmentId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isBooking = false;
        _pendingAppointment = null;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedSlot == null) return;

    final profile = ref.read(profileProvider);
    if (profile == null) return;

    setState(() => _isBooking = true);

    try {
      final appointment = await AppointmentService.createAppointment(
        date: _selectedDate!,
        startTime: _selectedSlot!.startTime,
        endTime: _selectedSlot!.endTime,
        patientName: profile.name,
      );

      _pendingAppointment = appointment;

      _paymentService?.openCheckout(
        amount: AppointmentService.opdFee,
        title: 'Online OPD - ${DoctorInfo.name}',
        description: 'Consultation on ${DateFormat('dd MMM yyyy').format(_selectedDate!)} at ${_selectedSlot!.displayTime}',
        appointmentId: appointment.appointmentId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isBooking = false);
    }
  }

  Future<void> _bookEmergencyAppointment() async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;

    setState(() => _isBooking = true);

    try {
      final appointment = await AppointmentService.createEmergencyAppointment(
        patientName: profile.name,
      );
      ref.invalidate(userAppointmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency OPD started. Opening video call...'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/video-call', extra: {'appointment': appointment});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final datesAsync = ref.watch(availableDatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Online OPD - ₹199')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(isDark),
            if (FeatureFlags.emergencyOpdTestingEnabled) ...[
              const SizedBox(height: 12),
              _buildEmergencyOpdButton(),
            ],
            const SizedBox(height: 20),
            _buildActiveAppointmentCard(),
            const SizedBox(height: 20),
            Text('Select Date', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            datesAsync.when(
              data: (dates) => _buildDateSelector(dates, isDark),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load dates'),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 20),
              Text('Available Slots (20 min each)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildSlotsList(isDark),
            ],
            if (_selectedSlot != null) ...[
              const SizedBox(height: 24),
              _buildBookingSummary(isDark),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isBooking ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3460),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isBooking
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Pay ₹199 & Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 24),
            Text('Upcoming Appointments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildUpcomingAppointments(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.pink.shade100,
                  child: Icon(Icons.local_hospital, size: 28, color: Colors.pink.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DoctorInfo.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(DoctorInfo.qualification, style: TextStyle(fontSize: 12, color: Colors.pink.shade700)),
                      Text('20-min Video Consultation', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('₹199', 'Per Session', Colors.green),
                _buildInfoItem('20 Min', 'Duration', Colors.blue),
                _buildInfoItem('P2P', 'Video Call', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildEmergencyOpdButton() {
    return ElevatedButton.icon(
      onPressed: _isBooking ? null : _bookEmergencyAppointment,
      icon: const Icon(Icons.emergency),
      label: Text(_isBooking ? 'Starting OPD...' : 'Emergency OPD Test'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActiveAppointmentCard() {
    final active = ref.watch(activeAppointmentProvider);
    if (active == null) return const SizedBox.shrink();

    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade300),
      ),
      child: InkWell(
        onTap: () => context.push('/video-call', extra: {'appointment': active}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your consultation is LIVE!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('Tap to join video call with ${DoctorInfo.name}'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(List<DateTime> dates, bool isDark) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _selectedDate?.day == date.day && _selectedDate?.month == date.month;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedDate = date;
              _selectedSlot = null;
            }),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F3460) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? null : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsList(bool isDark) {
    if (_selectedDate == null) return const SizedBox.shrink();
    final slotsAsync = ref.watch(availableSlotsProvider(_selectedDate!));

    return slotsAsync.when(
      data: (slots) {
        if (slots.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('No slots available for this date'),
                ],
              ),
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return ChoiceChip(
              label: Text(slot.displayTime),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedSlot = slot),
              selectedColor: const Color(0xFF0F3460).withValues(alpha: 0.2),
              side: BorderSide(color: isSelected ? const Color(0xFF0F3460) : Colors.grey.shade300),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0F3460) : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Could not load slots'),
    );
  }

  Widget _buildBookingSummary(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _buildSummaryRow('Doctor', DoctorInfo.name),
            _buildSummaryRow('Date', DateFormat('dd MMM yyyy').format(_selectedDate!)),
            _buildSummaryRow('Time', _selectedSlot!.displayTime),
            _buildSummaryRow('Duration', '20 minutes'),
            const Divider(),
            _buildSummaryRow('Consultation Fee', '₹199', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    final upcoming = ref.watch(upcomingAppointmentsProvider);
    if (upcoming.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No upcoming appointments', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return Column(
      children: upcoming.map((apt) {
        final isActive = apt.isActive;
        return Card(
          color: isActive ? Colors.green.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isActive ? BorderSide(color: Colors.green.shade300) : BorderSide.none,
          ),
          child: InkWell(
            onTap: isActive ? () => context.push('/video-call', extra: {'appointment': apt}) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.videocam : Icons.access_time,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(apt.date),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('${apt.startTime} - ${apt.endTime}'),
                      ],
                    ),
                  ),
                  if (isActive)
                    ElevatedButton(
                      onPressed: () => context.push('/video-call', extra: {'appointment': apt}),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Join'),
                    ),
                  if (!isActive)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      onPressed: () => _cancelAppointment(apt.appointmentId),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppointmentService.cancelAppointment(appointmentId);
      ref.invalidate(userAppointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled'), backgroundColor: Colors.orange),
        );
      }
    }
  }
}
