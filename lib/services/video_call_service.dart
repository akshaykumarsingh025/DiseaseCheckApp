import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/livekit_config.dart';
import '../services/doctor_account_service.dart';

class VideoCallService {
  static bool get isDoctor {
    return DoctorAccountService.isCurrentUserDoctor;
  }

  static String generateToken({
    required String roomName,
    required String participantName,
    required String participantIdentity,
    bool isModerator = false,
  }) {
    final header = base64Url
        .encode(utf8.encode(jsonEncode({
          'alg': 'HS256',
          'typ': 'JWT',
        })))
        .replaceAll('=', '');

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = now + 3600;

    final payload = {
      'iss': LiveKitConfig.apiKey,
      'sub': participantIdentity,
      'iat': now,
      'exp': exp,
      'room': roomName,
      'name': participantName,
      'video': {
        'roomJoin': true,
        'room': roomName,
        'canPublish': true,
        'canSubscribe': true,
      },
      'metadata': jsonEncode({
        'name': participantName,
        'isModerator': isModerator,
      }),
    };

    final payloadEncoded = base64Url
        .encode(utf8.encode(jsonEncode(payload)))
        .replaceAll('=', '');

    final signingInput = '$header.$payloadEncoded';
    final key = utf8.encode(LiveKitConfig.apiSecret);
    final hmac = Hmac(sha256, key);
    final signature = hmac.convert(utf8.encode(signingInput));
    final signatureEncoded =
        base64Url.encode(signature.bytes).replaceAll('=', '');

    return '$signingInput.$signatureEncoded';
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
