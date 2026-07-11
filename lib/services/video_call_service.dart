import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/livekit_config.dart';
import '../services/doctor_account_service.dart';

class VideoCallService {
  static bool get isDoctor {
    return DoctorAccountService.isCurrentUserDoctor;
  }

  /// Generates a LiveKit access token.
  ///
  /// NOTE: This currently signs the JWT on the client using the API secret in
  /// [LiveKitConfig]. That secret ships inside the app, which is a security
  /// trade-off made to stay on the Firebase Spark (free) plan. A server-side
  /// implementation that keeps the secret private already exists in
  /// `functions/index.js` (the `getLiveKitToken` callable) — switch to it once
  /// the project is on the Blaze plan by calling that function here instead.
  static Future<String> generateToken({
    required String roomName,
    required String participantName,
    required String participantIdentity,
    bool isModerator = false,
  }) async {
    try {
      return _createAccessToken(
        apiKey: LiveKitConfig.apiKey,
        apiSecret: LiveKitConfig.apiSecret,
        roomName: roomName,
        participantIdentity: participantIdentity,
        participantName: participantName,
        isModerator: isModerator,
      );
    } catch (e) {
      debugPrint('VideoCallService: Token generation error: $e');
      rethrow;
    }
  }

  static String _createAccessToken({
    required String apiKey,
    required String apiSecret,
    required String roomName,
    required String participantIdentity,
    required String participantName,
    required bool isModerator,
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
      'iss': apiKey,
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
    final key = utf8.encode(apiSecret);
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
