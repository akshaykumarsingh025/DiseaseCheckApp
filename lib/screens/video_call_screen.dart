import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/video_call_service.dart';
import '../utils/doctor_info.dart';

class VideoCallScreen extends StatefulWidget {
  final Appointment appointment;
  const VideoCallScreen({super.key, required this.appointment});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _hasJoined = false;
  bool _isStarting = false;
  bool _hasError = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  bool get _isDoctor => VideoCallService.isDoctor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appointment = widget.appointment;
    final meetingUrl = VideoCallService.getMeetingUrl(appointment.meetingId);

    return Scaffold(
      appBar: AppBar(title: Text(_isDoctor ? 'Doctor Console' : 'Video Consultation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDoctorCard(isDark),
            const SizedBox(height: 24),
            _buildAppointmentInfo(appointment, isDark),
            const SizedBox(height: 24),
            if (appointment.isActive) ...[
              if (_hasError) _buildErrorCard(isDark),
              if (_isDoctor)
                _buildDoctorControlCard(isDark)
              else
                _buildPatientJoinCard(isDark),
            ] else if (appointment.isUpcoming) ...[
              _buildWaitingCard(appointment, isDark),
            ] else ...[
              _buildEndedCard(isDark),
            ],
            const SizedBox(height: 24),
            _buildMeetingInfoCard(meetingUrl, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(bool isDark) {
    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.pink.shade100,
              child: Icon(Icons.local_hospital, size: 36, color: Colors.pink.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDoctor
                        ? 'Patient: ${widget.appointment.patientName}'
                        : DoctorInfo.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (!_isDoctor)
                    Text(DoctorInfo.qualification, style: TextStyle(fontSize: 13, color: Colors.pink.shade700)),
                  const SizedBox(height: 4),
                  Text('20-Minute Video Consultation', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentInfo(Appointment appointment, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _buildInfoRow(Icons.calendar_today, 'Date', DateFormat('dd MMM yyyy').format(appointment.date)),
            _buildInfoRow(Icons.access_time, 'Time', '${appointment.startTime} - ${appointment.endTime}'),
            _buildInfoRow(Icons.timer, 'Duration', '20 minutes'),
            _buildInfoRow(Icons.videocam, 'Meeting ID', appointment.meetingId.length > 12 ? appointment.meetingId.substring(0, 12) : appointment.meetingId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // DOCTOR VIEW — Start / End Consultation
  // ──────────────────────────────────────────────

  Widget _buildDoctorControlCard(bool isDark) {
    return Card(
      color: isDark ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.blue.shade600),
            const SizedBox(height: 16),
            Text(
              'Patient: ${widget.appointment.patientName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the consultation to create the meeting room. The patient will be able to join once you start.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isStarting ? null : () => _doctorStartMeeting(),
                icon: _isStarting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.video_call, size: 28),
                label: Text(
                  _isStarting ? 'Starting...' : 'Start Consultation',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_hasJoined) ...[
              const SizedBox(height: 16),
              Text(
                'Meeting room is live. Waiting for patient to join...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Show a live status indicator
              StreamBuilder<String>(
                stream: VideoCallService.watchCallStatus(widget.appointment.meetingId),
                builder: (context, snapshot) {
                  final status = snapshot.data ?? 'none';
                  final patientJoined = status == 'joined';
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        patientJoined ? Icons.person : Icons.person_outline,
                        color: patientJoined ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        patientJoined ? 'Patient has joined' : 'Patient not yet joined',
                        style: TextStyle(
                          color: patientJoined ? Colors.green : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _doctorEndMeeting(),
                icon: const Icon(Icons.call_end, color: Colors.red),
                label: const Text('End Consultation', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _doctorStartMeeting() async {
    setState(() {
      _isStarting = true;
      _hasError = false;
      _errorMessage = null;
    });
    try {
      await VideoCallService.startMeeting(
        widget.appointment.meetingId,
        patientId: widget.appointment.patientId,
      );
      if (mounted) setState(() { _hasJoined = true; _isStarting = false; _retryCount = 0; });
    } catch (e) {
      _retryCount++;
      if (mounted) {
        setState(() {
          _isStarting = false;
          _hasError = true;
          _errorMessage = 'Could not start meeting: $e';
        });
        if (_retryCount < _maxRetries) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start. Retrying... ($_retryCount/$_maxRetries)'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _doctorStartMeeting(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _doctorEndMeeting() async {
    try {
      await VideoCallService.endMeeting(widget.appointment.meetingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation ended'), backgroundColor: Colors.orange),
        );
        setState(() => _hasJoined = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ending meeting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ──────────────────────────────────────────────
  // PATIENT VIEW — Wait for doctor, then join
  // ──────────────────────────────────────────────

  Widget _buildPatientJoinCard(bool isDark) {
    return StreamBuilder<String>(
      stream: VideoCallService.watchCallStatus(widget.appointment.meetingId),
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'none';
        final doctorStarted = status == 'started' || status == 'joined';

        if (doctorStarted) {
          return _buildPatientReadyCard(isDark);
        } else {
          return _buildPatientWaitingForDoctorCard(isDark);
        }
      },
    );
  }

  Widget _buildPatientWaitingForDoctorCard(bool isDark) {
    return Card(
      color: isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Waiting for Dr. Deepika to start...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The doctor will create the meeting room. You will be able to join as soon as she starts the consultation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange.shade700),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Text('Listening for doctor...', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientReadyCard(bool isDark) {
    return Card(
      color: isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.green.shade600),
            const SizedBox(height: 16),
            const Text(
              'Dr. Deepika is ready!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              'The doctor has started the consultation. Tap below to join the video call now.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await VideoCallService.joinMeeting(
                      widget.appointment.meetingId,
                      displayName: widget.appointment.patientName,
                    );
                    if (mounted) setState(() => _hasJoined = true);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not join video call: $e'),
                          backgroundColor: Colors.red,
                          action: SnackBarAction(
                            label: 'Retry',
                            textColor: Colors.white,
                            onPressed: () {
                              // Re-trigger by setting state
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.video_call, size: 28),
                label: const Text('Join Video Call', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_hasJoined) ...[
              const SizedBox(height: 12),
              Text(
                'Call opened in browser. You can return here after the call.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SHARED — Waiting / Ended / Info cards
  // ──────────────────────────────────────────────

  Widget _buildWaitingCard(Appointment appointment, bool isDark) {
    final startParts = appointment.startTime.split(':');
    final startDateTime = DateTime(
      appointment.date.year, appointment.date.month, appointment.date.day,
      int.parse(startParts[0]), int.parse(startParts[1]),
    );
    final bufferStart = startDateTime.subtract(const Duration(minutes: 5));
    final now = DateTime.now();
    final canJoinEarly = now.isAfter(bufferStart);

    return Card(
      color: isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.orange.shade600),
            const SizedBox(height: 12),
            Text(
              'Your consultation starts at ${appointment.startTime}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isDoctor
                  ? (canJoinEarly ? 'You can start the consultation now.' : 'The consultation will begin at the scheduled time.')
                  : (canJoinEarly
                      ? 'Waiting for the doctor to start the meeting...'
                      : 'The video call link will activate 5 minutes before your scheduled time.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange.shade700),
            ),
            const SizedBox(height: 16),
            if (canJoinEarly && _isDoctor)
              ElevatedButton.icon(
                onPressed: _isStarting ? null : () => _doctorStartMeeting(),
                icon: const Icon(Icons.video_call),
                label: Text(_isStarting ? 'Starting...' : 'Start Early'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndedCard(bool isDark) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.call_end, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text('This appointment has ended', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Need another consultation? Book a new appointment.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/online-opd'),
              child: const Text('Book New Appointment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Card(
      color: isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade600),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _hasError = false; _errorMessage = null; });
                if (_isDoctor) {
                  _doctorStartMeeting();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingInfoCard(String meetingUrl, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Direct Meeting Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SelectableText(
              meetingUrl,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              _isDoctor
                  ? 'This is the Jitsi meeting link for this consultation.'
                  : 'Share this link with Dr. Deepika if needed. Works in any browser.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
