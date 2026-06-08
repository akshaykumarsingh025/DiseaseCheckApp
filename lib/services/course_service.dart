import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';

class CourseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Course>> getCourses() async {
    final snapshot = await _firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Course.fromJson(doc.data())).toList();
  }

  static Stream<List<Course>> getCoursesStream() {
    return _firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Course.fromJson(doc.data())).toList());
  }

  static Future<Course?> getCourseById(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (!doc.exists) return null;
    return Course.fromJson(doc.data()!);
  }

  static Future<bool> isEnrolled(String courseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('enrolled_courses')
        .doc(courseId)
        .get();

    return doc.exists;
  }

  static Future<void> enrollFreeCourse(String courseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('enrolled_courses')
        .doc(courseId)
        .set({
      'courseId': courseId,
      'enrolledAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    await _firestore.collection('courses').doc(courseId).update({
      'enrolledCount': FieldValue.increment(1),
    });
  }

  static Future<void> enrollPaidCourse(String courseId, String paymentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('enrolled_courses')
        .doc(courseId)
        .set({
      'courseId': courseId,
      'enrolledAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'paymentId': paymentId,
    });

    await _firestore.collection('courses').doc(courseId).update({
      'enrolledCount': FieldValue.increment(1),
    });
  }

  static Future<List<Course>> getEnrolledCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final enrolledSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('enrolled_courses')
        .where('status', isEqualTo: 'active')
        .get();

    final courseIds = enrolledSnapshot.docs.map((doc) => doc.id).toList();
    if (courseIds.isEmpty) return [];

    final courses = <Course>[];
    for (var id in courseIds) {
      final doc = await _firestore.collection('courses').doc(id).get();
      if (doc.exists) {
        courses.add(Course.fromJson(doc.data()!));
      }
    }
    return courses;
  }
}
