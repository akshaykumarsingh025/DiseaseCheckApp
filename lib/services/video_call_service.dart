import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/doctor_account_service.dart';

class VideoCallTokenException implements Exception {
  const VideoCallTokenException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoCallService {
  static bool get isDoctor {
    return DoctorAccountService.isCurrentUserDoctor;
  }

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

    try {
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getLiveKitToken')
          .call({
        'roomName': roomName,
        'participantName': participantName,
        'participantIdentity': participantIdentity,
        'isModerator': isModerator,
      });

      final data = result.data;
      final token = data is Map ? data['token'] as String? : null;
      if (token != null && token.isNotEmpty) {
        return token;
      }

      throw const VideoCallTokenException(
        'Unable to create a video call token. Please try again.',
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('VideoCallService: Cloud function failed (${e.code}): $e');
      throw VideoCallTokenException(_tokenErrorMessage(e));
    } on VideoCallTokenException {
      rethrow;
    } catch (e) {
      debugPrint('VideoCallService: Cloud function error: $e');
      throw const VideoCallTokenException(
        'Unable to create a video call token. Please check your internet connection and try again.',
      );
    }
  }

  static String _tokenErrorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Please sign in again before joining the video call.';
      case 'permission-denied':
        return 'You do not have permission to join this video call.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'The video call service is temporarily unavailable. Please try again.';
      case 'not-found':
      case 'unimplemented':
        return 'The video call token service is not deployed. Please deploy the Firebase function and try again.';
      default:
        final message = error.message;
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
        return 'Unable to create a video call token. Please try again.';
    }
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
