import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/backend_config.dart';
import '../services/backend_auth.dart';
import '../services/doctor_account_service.dart';

class VideoCallTokenException implements Exception {
  const VideoCallTokenException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoCallService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    // Handle non-2xx ourselves so we can map the Worker's error payload.
    validateStatus: (_) => true,
  ));

  static bool get isDoctor {
    return DoctorAccountService.isCurrentUserDoctor;
  }

  /// Requests a LiveKit access token from the Cloudflare Worker.
  ///
  /// The LiveKit API secret lives in Worker secrets, so it is never present in
  /// the shipped app. See `worker/README.md`.
  static Future<String> generateToken({
    required String roomName,
    required String participantName,
    required String participantIdentity,
    bool isModerator = false,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw const VideoCallTokenException(
        'Please sign in again before joining the video call.',
      );
    }

    if (!BackendConfig.isConfigured) {
      throw const VideoCallTokenException(
        'The video call service is not configured yet. Please deploy the API worker and set its URL.',
      );
    }

    try {
      final response = await _dio.post(
        BackendConfig.liveKitTokenUrl,
        options: Options(headers: await BackendAuth.headers()),
        data: {
          'roomName': roomName,
          'participantName': participantName,
          'participantIdentity': participantIdentity,
          'isModerator': isModerator,
        },
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = response.data;
        final token = data is Map ? data['token'] as String? : null;
        if (token != null && token.isNotEmpty) {
          return token;
        }
        throw const VideoCallTokenException(
          'Unable to create a video call token. Please try again.',
        );
      }

      debugPrint('VideoCallService: token endpoint returned $status');
      throw VideoCallTokenException(_statusErrorMessage(status, response.data));
    } on BackendAuthException catch (e) {
      throw VideoCallTokenException(e.message);
    } on VideoCallTokenException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('VideoCallService: token request failed: $e');
      throw const VideoCallTokenException(
        'Unable to create a video call token. Please check your internet connection and try again.',
      );
    } catch (e) {
      debugPrint('VideoCallService: token error: $e');
      throw const VideoCallTokenException(
        'Unable to create a video call token. Please try again.',
      );
    }
  }

  static String _statusErrorMessage(int status, dynamic body) {
    switch (status) {
      case 401:
        return 'Please sign in again before joining the video call.';
      case 403:
        return 'You do not have permission to join this video call.';
      case 429:
        return 'Too many join attempts. Please wait a moment and try again.';
      case 404:
        return 'The video call token service is not deployed. Please deploy the API worker and try again.';
      case 502:
      case 503:
        return 'The video call service is temporarily unavailable. Please try again.';
      default:
        final message = _extractError(body);
        if (message != null) return message;
        return 'Unable to create a video call token. Please try again.';
    }
  }

  static String? _extractError(dynamic body) {
    try {
      if (body is Map) {
        final err = body['error'];
        if (err is Map && err['message'] is String) {
          final message = (err['message'] as String).trim();
          if (message.isNotEmpty) return message;
        }
      }
    } catch (_) {}
    return null;
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
