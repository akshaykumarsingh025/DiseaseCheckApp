import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/feature_flags.dart';

class VideoCallService {
  static const String _jitsiBaseUrl = 'https://meet.jit.si';

  /// Check if the current user is the doctor.
  static bool get isDoctor {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == FeatureFlags.doctorUserId;
  }

  static String getMeetingUrl(String meetingId) {
    return '$_jitsiBaseUrl/$meetingId';
  }

  static Future<void> openVideoCall(String meetingId, {String displayName = ''}) async {
    final encodedName = Uri.encodeComponent(displayName);
    final url = '$_jitsiBaseUrl/$meetingId#config.prejoinPageEnabled=false&config.startWithAudioMuted=false&config.startWithVideoMuted=false&userInfo.displayName=$encodedName';
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallbackLaunched = await launchUrl(uri);
        if (!fallbackLaunched) {
          throw Exception('Could not launch video call URL');
        }
      }
    } catch (e) {
      try {
        final fallbackLaunched = await launchUrl(uri);
        if (!fallbackLaunched) {
          throw Exception('Could not open video call. Please check your browser settings.');
        }
      } catch (_) {
        throw Exception('Could not open video call. Please open this URL manually: ${getMeetingUrl(meetingId)}');
      }
    }
  }

  /// Doctor starts the meeting — creates the Jitsi room and marks it as 'started' in Firestore.
  static Future<void> startMeeting(String meetingId, {required String patientId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('video_calls').doc(meetingId).set({
      'meetingId': meetingId,
      'patientId': patientId,
      'doctorId': user.uid,
      'status': 'started',
      'startedBy': user.uid,
      'meetingUrl': getMeetingUrl(meetingId),
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await openVideoCall(meetingId, displayName: 'Dr. Deepika Singh');
  }

  /// Patient joins an already-started meeting.
  static Future<void> joinMeeting(String meetingId, {required String displayName}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('video_calls').doc(meetingId).set({
      'meetingId': meetingId,
      'status': 'joined',
      'joinedBy': user.uid,
      'joinedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await openVideoCall(meetingId, displayName: displayName);
  }

  /// Doctor ends the meeting.
  static Future<void> endMeeting(String meetingId) async {
    await FirebaseFirestore.instance.collection('video_calls').doc(meetingId).set({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update call status (generic).
  static Future<void> updateCallStatus(String meetingId, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('video_calls').doc(meetingId).set({
      'meetingId': meetingId,
      'status': status,
      'meetingUrl': getMeetingUrl(meetingId),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Watch the meeting status in real-time.
  static Stream<String> watchCallStatus(String meetingId) {
    return FirebaseFirestore.instance
        .collection('video_calls')
        .doc(meetingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 'none';
      return doc.data()?['status'] as String? ?? 'none';
    });
  }
}
