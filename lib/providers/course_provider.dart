import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../services/course_service.dart';

final coursesProvider = StreamProvider<List<Course>>((ref) {
  return CourseService.getCoursesStream();
});

final freeCoursesProvider = Provider<List<Course>>((ref) {
  final courses = ref.watch(coursesProvider).valueOrNull ?? [];
  return courses.where((c) => c.isFree).toList();
});

final paidCoursesProvider = Provider<List<Course>>((ref) {
  final courses = ref.watch(coursesProvider).valueOrNull ?? [];
  return courses.where((c) => !c.isFree).toList();
});

final courseDetailProvider = FutureProvider.family<Course?, String>((ref, courseId) async {
  return CourseService.getCourseById(courseId);
});

final isEnrolledProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  return CourseService.isEnrolled(courseId);
});
