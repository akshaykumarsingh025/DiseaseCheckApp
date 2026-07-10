import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _inMeeting = false;
  bool _wasOnMeetingPage = false;
  bool _redirecting = false;

  InAppWebViewController? _webViewController;
  HeadlessInAppWebView? _headlessWebView;

  bool get _isDoctor => VideoCallService.isDoctor;

  String get _meetingUrl {
    final meetingId = widget.appointment.meetingId;
    return 'https://meet.jit.si/$meetingId'
        '#config.prejoinPageEnabled=false'
        '&config.requireDisplayName=false'
        '&config.startWithAudioMuted=false'
        '&config.startWithVideoMuted=false'
        '&config.disableModeratorIndicator=true'
        '&config.lobby.enabled=false'
        '&interfaceConfig.DISABLE_VIDEO_BACKGROUND=true'
        '&config.chimneyEnabled=false';
  }

  String get _displayName {
    return _isDoctor
        ? 'Dr. Deepika Singh'
        : widget.appointment.patientName;
  }

  @override
  void dispose() {
    _headlessWebView?.dispose();
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
          _errorMessage =
              'Camera and microphone access is required for the video call. '
              'Please grant the permissions and try again, or open the meeting in your browser.';
        });
      }
      return;
    }

    try {
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

      if (mounted) {
        setState(() {
          _inMeeting = true;
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
      return true;
    }
  }

  Future<void> _openInBrowser() async {
    final url = VideoCallService.getMeetingUrl(widget.appointment.meetingId);
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open browser. Please copy the meeting link.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _endCall() async {
    if (_isDoctor) {
      await VideoCallService.endMeeting(widget.appointment.meetingId);
    }

    if (mounted) {
      setState(() {
        _inMeeting = false;
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
            label: Text(_isDoctor ? 'End Consultation' : 'Leave Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_inMeeting) {
      return _buildMeetingView();
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

  Widget _buildMeetingView() {
    return WillPopScope(
      onWillPop: () async {
        _confirmEndCall();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(_meetingUrl),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheEnabled: true,
                userAgent: 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
                useHybridComposition: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                builtInZoomControls: false,
                supportZoom: false,
                javaScriptCanOpenWindowsAutomatically: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _injectDisplayName(controller);
              },
              onLoadStop: (controller, url) {
                if (_redirecting) return;
                final currentUrl = url?.toString() ?? '';
                final meetingId = widget.appointment.meetingId;
                final isOnMeetingPage = currentUrl.contains('/$meetingId');

                if (isOnMeetingPage) {
                  _wasOnMeetingPage = true;
                  _injectDisplayName(controller);
                  return;
                }

                // Only redirect from bare homepage AFTER user was already on the
                // meeting page — this means OAuth just completed and Jitsi
                // redirected to its homepage instead of back to the room.
                // Do NOT redirect during the initial login flow or from
                // intermediate OAuth URLs (accounts.google.com etc.).
                final isOnJitsiHome = currentUrl == 'https://meet.jit.si/' ||
                    currentUrl == 'https://meet.jit.si' ||
                    currentUrl == 'https://meet.jit.si/welcome';

                if (isOnJitsiHome && _wasOnMeetingPage && !_redirecting) {
                  _redirecting = true;
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      controller.loadUrl(
                        urlRequest: URLRequest(url: WebUri(_meetingUrl)),
                      );
                    }
                    _redirecting = false;
                  });
                }
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('Jitsi WebView: ${consoleMessage.message}');
              },
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _inCall ? Colors.greenAccent : Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isDoctor
                              ? 'Dr. ${widget.appointment.patientName}'
                              : 'Dr. ${DoctorInfo.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _confirmEndCall,
                        icon: const Icon(Icons.call_end, size: 18),
                        label: Text(
                          _isDoctor ? 'End' : 'Leave',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _injectDisplayName(InAppWebViewController controller) {
    final js = '''
      (function() {
        function trySetName() {
          var inputs = document.querySelectorAll('input');
          inputs.forEach(function(input) {
            if (input.placeholder && (input.placeholder.toLowerCase().includes('name') || input.placeholder.toLowerCase().includes('enter'))) {
              input.value = '$_displayName';
              input.dispatchEvent(new Event('input', {bubbles: true}));
              input.dispatchEvent(new Event('change', {bubbles: true}));
            }
          });
          var buttons = document.querySelectorAll('button');
          buttons.forEach(function(btn) {
            if (btn.textContent.toLowerCase().includes('join') || btn.textContent.toLowerCase().includes('enter')) {
              if (document.querySelector('input[value]')) {
                btn.click();
              }
            }
          });
        }
        setTimeout(trySetName, 500);
        setTimeout(trySetName, 1500);
        setTimeout(trySetName, 3000);
      })();
    ''';
    controller.evaluateJavascript(source: js);
  }

  Widget _buildRoleBanner(bool isDark) {
    if (_isDoctor) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor / Moderator', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('You control the meeting. Only you can start and end the consultation.', style: TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.pink.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.pink.shade100, child: Icon(Icons.local_hospital, size: 24, color: Colors.pink.shade700)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DoctorInfo.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(DoctorInfo.qualification, style: TextStyle(fontSize: 11, color: Colors.pink.shade700)),
                  const SizedBox(height: 2),
                  Text('20-Minute Video Consultation', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
            _buildInfoRow(Icons.phone_android, 'Video', 'In-App Call'),
            _buildInfoRow(_isDoctor ? Icons.admin_panel_settings : Icons.person, 'Role', _isDoctor ? 'Moderator' : 'Participant'),
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
      color: isDark ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.video_call, size: 56, color: Colors.blue.shade600),
            const SizedBox(height: 12),
            Text('Patient: ${widget.appointment.patientName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tap below to start the video consultation. The patient will be able to join once you start.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isStarting ? null : _joinCall,
                icon: _isStarting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.videocam, size: 22),
                label: Text(_isStarting ? 'Connecting...' : 'Start Consultation', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          color: isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.videocam, size: 56, color: Colors.green.shade600),
                const SizedBox(height: 12),
                const Text('Dr. Deepika is ready!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 6),
                const Text('The doctor has started the consultation. Tap below to join.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isStarting ? null : _joinCall,
                    icon: _isStarting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.videocam, size: 22),
                    label: Text(_isStarting ? 'Connecting...' : 'Join Video Call', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      color: isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.orange.shade400)),
            const SizedBox(height: 14),
            const Text('Waiting for Dr. Deepika to start...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Only the doctor can start the video call. You will be able to join once she begins the consultation.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.circle, size: 8, color: Colors.orange.shade400),
              const SizedBox(width: 6),
              Text('Listening for doctor...', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam, size: 56, color: Colors.white),
          const SizedBox(height: 12),
          const Text('Consultation In Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            _isDoctor ? 'Connected with ${widget.appointment.patientName}' : 'Connected with ${DoctorInfo.name}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmEndCall,
              icon: const Icon(Icons.call_end, size: 22),
              label: Text(_isDoctor ? 'End Consultation' : 'Leave Call', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard(Appointment appointment, bool isDark) {
    return Card(
      color: isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.orange.shade600),
            const SizedBox(height: 12),
            Text('Your consultation starts at ${appointment.startTime}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('The video call will be available at the scheduled time. Please come back a few minutes early.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
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
            const Text('This appointment has ended', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Need another consultation? Book a new appointment.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            if (_isDoctor)
              ElevatedButton.icon(
                onPressed: () => context.push('/write-prescription', extra: {'appointment': widget.appointment}),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Write Prescription', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3460),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => context.push('/online-opd'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
                child: const Text('Book New Appointment', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Card(
      color: isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade600),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Something went wrong', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _hasError = false; _errorMessage = null; });
                _joinCall();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Join in Browser instead'),
            ),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open App Settings', style: TextStyle(fontSize: 12)),
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
                const Text('Meeting Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: const Text('In-App', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              VideoCallService.getMeetingUrl(widget.appointment.meetingId),
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            const Text('Video calls run inside the app. Make sure camera and microphone permissions are granted.', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
