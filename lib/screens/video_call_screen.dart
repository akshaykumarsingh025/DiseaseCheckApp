import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/livekit_config.dart';
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
  bool _isStarting = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _inCall = false;
  bool _callEnded = false;

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _micEnabled = true;
  bool _camEnabled = true;

  bool get _isDoctor => VideoCallService.isDoctor;

  String get _displayName {
    return _isDoctor ? 'Dr. Deepika Singh' : widget.appointment.patientName;
  }

  @override
  void dispose() {
    _listener?.dispose();
    _room?.dispose();
    super.dispose();
  }

  Future<void> _joinCall() async {
    setState(() {
      _isStarting = true;
      _hasError = false;
      _errorMessage = null;
    });

    final permissionsOk = await _ensureMediaPermissions();
    if (!permissionsOk) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _hasError = true;
          _errorMessage = 'Camera and microphone access is required.';
        });
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final identity =
          _isDoctor ? 'doctor_${user?.uid ?? 'doc'}' : 'patient_${user?.uid ?? 'pat'}';

      final token = VideoCallService.generateToken(
        roomName: widget.appointment.meetingId,
        participantName: _displayName,
        participantIdentity: identity,
        isModerator: _isDoctor,
      );

      if (_isDoctor) {
        await VideoCallService.startMeeting(
          widget.appointment.meetingId,
          patientId: widget.appointment.patientId,
        );
      } else {
        await VideoCallService.joinMeeting(
          widget.appointment.meetingId,
          displayName: _displayName,
        );
      }

      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );
      _listener = _room!.createListener();

      _listener!.on<RoomDisconnectedEvent>((event) {
        if (mounted) {
          if (_isDoctor) {
            VideoCallService.endMeeting(widget.appointment.meetingId);
          }
          setState(() {
            _inCall = false;
            _callEnded = true;
            _isStarting = false;
          });
        }
      });

      _listener!.on<ParticipantConnectedEvent>((event) {
        if (mounted) setState(() {});
      });

      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (mounted) setState(() {});
      });

      _listener!.on<TrackSubscribedEvent>((event) {
        if (mounted) setState(() {});
      });

      _listener!.on<TrackUnsubscribedEvent>((event) {
        if (mounted) setState(() {});
      });

      await _room!.connect(LiveKitConfig.url, token);

      await _room!.localParticipant!.setCameraEnabled(true);
      await _room!.localParticipant!.setMicrophoneEnabled(true);

      if (mounted) {
        setState(() {
          _inCall = true;
          _isStarting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _hasError = true;
          _errorMessage = 'Could not join video call: $e';
        });
      }
    }
  }

  Future<bool> _ensureMediaPermissions() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      final cameraOk = statuses[Permission.camera]?.isGranted ?? false;
      final micOk = statuses[Permission.microphone]?.isGranted ?? false;
      return cameraOk && micOk;
    } catch (_) {
      return false;
    }
  }

  void _endCall() async {
    await _room?.disconnect();
    _listener?.dispose();
    _listener = null;

    if (_isDoctor) {
      await VideoCallService.endMeeting(widget.appointment.meetingId);
    }

    if (mounted) {
      setState(() {
        _inCall = false;
        _callEnded = true;
      });
    }
  }

  void _confirmEndCall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isDoctor ? 'End Consultation?' : 'Leave Call?'),
        content: Text(_isDoctor
            ? 'This will end the consultation for both you and the patient.'
            : 'Are you sure you want to leave the video call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _endCall();
            },
            icon: const Icon(Icons.call_end, size: 18),
            label: Text(_isDoctor ? 'End' : 'Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMic() async {
    if (_room?.localParticipant == null) return;
    _micEnabled = !_micEnabled;
    await _room!.localParticipant!.setMicrophoneEnabled(_micEnabled);
    if (mounted) setState(() {});
  }

  Future<void> _toggleCam() async {
    if (_room?.localParticipant == null) return;
    _camEnabled = !_camEnabled;
    await _room!.localParticipant!.setCameraEnabled(_camEnabled);
    if (mounted) setState(() {});
  }

  void _switchCamera() async {
    if (_room?.localParticipant == null) return;
    final vidPubs = _room!.localParticipant!.videoTrackPublications;
    if (vidPubs.isEmpty) return;
    final track = vidPubs.first.track;
    if (track is LocalVideoTrack) {
      final options = track.currentOptions;
      if (options is CameraCaptureOptions) {
        await track.restartTrack(
          CameraCaptureOptions(
              cameraPosition: options.cameraPosition.switched()),
        );
      }
    }
  }

  VideoTrack? _getVideoTrack(Participant participant) {
    for (final pub in participant.videoTrackPublications) {
      if (pub.track != null &&
          pub.kind == TrackType.VIDEO &&
          !pub.isScreenShare) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_inCall && _room != null) {
      return _buildCallView();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appointment = widget.appointment;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDoctor ? 'Doctor Console' : 'Video Consultation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRoleBanner(isDark),
              const SizedBox(height: 16),
              _buildAppointmentInfo(appointment, isDark),
              const SizedBox(height: 16),
              if (_callEnded)
                _buildEndedCard(isDark)
              else if (_hasError)
                _buildErrorCard(isDark)
              else if (_inCall)
                _buildInCallCard(isDark)
              else if (appointment.isActive)
                _isDoctor
                    ? _buildDoctorStartCard(isDark)
                    : _buildPatientJoinCard(isDark)
              else if (appointment.isUpcoming)
                _buildWaitingCard(appointment, isDark)
              else
                _buildEndedCard(isDark),
              const SizedBox(height: 16),
              _buildMeetingInfoCard(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Native LiveKit Call View ──────────────────────────────────────────

  Widget _buildCallView() {
    final remoteParticipants = _room!.remoteParticipants.values.toList();
    final localParticipant = _room!.localParticipant;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEndCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildCallHeader(remoteParticipants),
              Expanded(
                child: remoteParticipants.isEmpty
                    ? _buildWaitingForParticipant(localParticipant)
                    : _buildVideoGrid(localParticipant, remoteParticipants),
              ),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallHeader(List<RemoteParticipant> remotes) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _isDoctor
                  ? 'Consultation with ${widget.appointment.patientName}'
                  : 'Consultation with ${DoctorInfo.name}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            remotes.isEmpty
                ? 'Waiting...'
                : '${remotes.length + 1} in call',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForParticipant(LocalParticipant? localParticipant) {
    final localVideo = localParticipant != null
        ? _getVideoTrack(localParticipant)
        : null;

    return Stack(
      children: [
        if (localVideo != null)
          Center(
              child: VideoTrackRenderer(localVideo,
                  mirrorMode: VideoViewMirrorMode.mirror))
        else
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.blue.shade800,
              child: Text(
                _displayName.isNotEmpty
                    ? _displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
          ),
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3)),
                const SizedBox(height: 16),
                Text(
                  _isDoctor
                      ? 'Waiting for patient to join...'
                      : 'Waiting for doctor to join...',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoGrid(
      LocalParticipant? localParticipant, List<RemoteParticipant> remotes) {
    List<Widget> videoWidgets = [];

    for (final remote in remotes) {
      final remoteVideo = _getVideoTrack(remote);

      videoWidgets.add(
        Stack(
          children: [
            if (remoteVideo != null)
              VideoTrackRenderer(remoteVideo)
            else
              Container(
                color: Colors.grey.shade900,
                child: Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue.shade700,
                    child: Text(
                      remote.name.isNotEmpty
                          ? remote.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: Text(remote.name.isEmpty ? 'Remote' : remote.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }

    final localVideo =
        localParticipant != null ? _getVideoTrack(localParticipant) : null;

    return Stack(
      children: [
        GridView.count(
          crossAxisCount: 1,
          children: videoWidgets,
        ),
        Positioned(
          bottom: 12,
          right: 12,
          width: 120,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: localVideo != null
                ? VideoTrackRenderer(localVideo,
                    mirrorMode: VideoViewMirrorMode.mirror)
                : Container(
                    color: Colors.grey.shade800,
                    child: Center(
                      child: Text(_displayName[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28)),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _micEnabled ? Icons.mic : Icons.mic_off,
            label: _micEnabled ? 'Mute' : 'Unmute',
            active: _micEnabled,
            onPressed: _toggleMic,
          ),
          _buildControlButton(
            icon: _camEnabled ? Icons.videocam : Icons.videocam_off,
            label: 'Camera',
            active: _camEnabled,
            onPressed: _toggleCam,
          ),
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            active: true,
            onPressed: _switchCamera,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: _isDoctor ? 'End' : 'Leave',
            active: true,
            onPressed: _confirmEndCall,
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final bgColor = color ?? (active ? Colors.white24 : Colors.white10);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          mini: true,
          backgroundColor: bgColor,
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  // ─── Pre-call UI (same structure as before) ─────────────────────────────

  Widget _buildRoleBanner(bool isDark) {
    if (_isDoctor) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.blue.shade900.withValues(alpha: 0.3)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor / Moderator',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text(
                      'You control the meeting. Only you can start and end the consultation.',
                      style: TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: isDark
          ? Colors.pink.shade900.withValues(alpha: 0.2)
          : Colors.pink.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.pink.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
                radius: 24,
                backgroundColor: Colors.pink.shade100,
                child: Icon(Icons.local_hospital,
                    size: 24, color: Colors.pink.shade700)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DoctorInfo.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(DoctorInfo.qualification,
                      style:
                          TextStyle(fontSize: 11, color: Colors.pink.shade700)),
                  const SizedBox(height: 2),
                  Text('20-Minute Video Consultation',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
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
            const Text('Appointment Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _buildInfoRow(Icons.calendar_today, 'Date',
                DateFormat('dd MMM yyyy').format(appointment.date)),
            _buildInfoRow(
                Icons.access_time, 'Time', '${appointment.startTime} - ${appointment.endTime}'),
            _buildInfoRow(Icons.timer, 'Duration', '20 minutes'),
            _buildInfoRow(Icons.videocam, 'Meeting ID',
                appointment.meetingId.length > 12
                    ? appointment.meetingId.substring(0, 12)
                    : appointment.meetingId),
            _buildInfoRow(Icons.phone_android, 'Video', 'In-App Call'),
            _buildInfoRow(
                _isDoctor ? Icons.admin_panel_settings : Icons.person,
                'Role',
                _isDoctor ? 'Moderator' : 'Participant'),
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

  Widget _buildDoctorStartCard(bool isDark) {
    return Card(
      color: isDark
          ? Colors.blue.shade900.withValues(alpha: 0.2)
          : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.video_call, size: 56, color: Colors.blue.shade600),
            const SizedBox(height: 12),
            Text('Patient: ${widget.appointment.patientName}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'Tap below to start the video consultation. The patient will be able to join once you start.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isStarting ? null : _joinCall,
                icon: _isStarting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.videocam, size: 22),
                label: Text(
                    _isStarting ? 'Connecting...' : 'Start Consultation',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientJoinCard(bool isDark) {
    return StreamBuilder<String>(
      stream: VideoCallService.watchCallStatus(widget.appointment.meetingId),
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'none';
        final doctorStarted = status == 'started' || status == 'joined';

        if (!doctorStarted) {
          return _buildPatientWaitingCard(isDark);
        }

        return Card(
          color: isDark
              ? Colors.green.shade900.withValues(alpha: 0.2)
              : Colors.green.shade50,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.videocam,
                    size: 56, color: Colors.green.shade600),
                const SizedBox(height: 12),
                const Text('Dr. Deepika is ready!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                const SizedBox(height: 6),
                const Text(
                    'The doctor has started the consultation. Tap below to join.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isStarting ? null : _joinCall,
                    icon: _isStarting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.videocam, size: 22),
                    label: Text(
                        _isStarting ? 'Connecting...' : 'Join Video Call',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientWaitingCard(bool isDark) {
    return Card(
      color: isDark
          ? Colors.orange.shade900.withValues(alpha: 0.2)
          : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.orange.shade400)),
            const SizedBox(height: 14),
            const Text('Waiting for Dr. Deepika to start...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'Only the doctor can start the video call. You will be able to join once she begins the consultation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.circle, size: 8, color: Colors.orange.shade400),
              const SizedBox(width: 6),
              Text('Listening for doctor...',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInCallCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam, size: 56, color: Colors.white),
          const SizedBox(height: 12),
          const Text('Consultation In Progress',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmEndCall,
              icon: const Icon(Icons.call_end, size: 22),
              label: Text(
                  _isDoctor ? 'End Consultation' : 'Leave Call',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard(Appointment appointment, bool isDark) {
    return Card(
      color: isDark
          ? Colors.orange.shade900.withValues(alpha: 0.2)
          : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.orange.shade600),
            const SizedBox(height: 12),
            Text('Your consultation starts at ${appointment.startTime}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'The video call will be available at the scheduled time. Please come back a few minutes early.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildEndedCard(bool isDark) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.call_end, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text('This appointment has ended',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Need another consultation? Book a new appointment.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            if (_isDoctor)
              ElevatedButton.icon(
                onPressed: () => context.push('/write-prescription',
                    extra: {'appointment': widget.appointment}),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Write Prescription',
                    style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3460),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => context.push('/online-opd'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20)),
                child: const Text('Book New Appointment',
                    style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Card(
      color: isDark
          ? Colors.red.shade900.withValues(alpha: 0.2)
          : Colors.red.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 56, color: Colors.red.shade600),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _joinCall();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => openAppSettings(),
              child:
                  const Text('Open App Settings', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingInfoCard(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Meeting Info',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('LiveKit',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                'Video calls use LiveKit for encrypted, login-free video. No external app needed.',
                style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
