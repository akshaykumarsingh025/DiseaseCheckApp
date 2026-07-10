import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../services/doctor_account_service.dart';

class VideoCallService {
  static const String _jitsiServerUrl = 'https://meet.jit.si';

  static bool get isDoctor {
    return DoctorAccountService.isCurrentUserDoctor;
  }

  static String getMeetingUrl(String meetingId) {
    return '$_jitsiServerUrl/$meetingId';
  }

  static JitsiMeetConferenceOptions getDoctorOptions(String meetingId, {String displayName = ''}) {
    return JitsiMeetConferenceOptions(
      serverURL: _jitsiServerUrl,
      room: meetingId,
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
      ),
      featureFlags: const {
        'prejoinpage.enabled': false,
        'lobby-mode.enabled': false,
        'welcomepage.enabled': false,
        'invite.enabled': false,
        'unsaferoomwarning.enabled': false,
        'security-options.enabled': false,
        'chat.enabled': true,
        'tile-view.enabled': true,
        'deeplinking.enabled': false,
        'live-streaming.enabled': false,
        'recording.enabled': false,
        'toolbox.enabled': true,
        'filmstrip.enabled': true,
        'fullscreen.enabled': true,
        'close-page.enabled': false,
      },
      configOverrides: const {
        'startWithAudioMuted': false,
        'startWithVideoMuted': false,
        'requireDisplayName': false,
        'disableModeratorIndicator': true,
        'prejoinPageEnabled': false,
        'lobby.enabled': false,
        'requirePassword': false,
      },
    );
  }

  static JitsiMeetConferenceOptions getPatientOptions(String meetingId, {String displayName = ''}) {
    return JitsiMeetConferenceOptions(
      serverURL: _jitsiServerUrl,
      room: meetingId,
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
      ),
      featureFlags: const {
        'prejoinpage.enabled': false,
        'lobby-mode.enabled': false,
        'welcomepage.enabled': false,
        'invite.enabled': false,
        'unsaferoomwarning.enabled': false,
        'security-options.enabled': false,
        'chat.enabled': true,
        'tile-view.enabled': true,
        'deeplinking.enabled': false,
        'live-streaming.enabled': false,
        'recording.enabled': false,
        'toolbox.enabled': true,
        'filmstrip.enabled': true,
        'fullscreen.enabled': true,
        'close-page.enabled': false,
      },
      configOverrides: const {
        'startWithAudioMuted': false,
        'startWithVideoMuted': false,
        'requireDisplayName': false,
        'prejoinPageEnabled': false,
        'lobby.enabled': false,
      },
    );
  }

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
  }

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
  }

  static Future<void> endMeeting(String meetingId) async {
    await FirebaseFirestore.instance.collection('video_calls').doc(meetingId).set({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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
