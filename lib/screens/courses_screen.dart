import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/course_provider.dart';
import '../models/course.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Courses'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Free'),
              Tab(text: 'Premium'),
            ],
          ),
        ),
        body: coursesAsync.when(
          data: (courses) {
            final freeCourses = courses.where((c) => c.isFree).toList();
            final paidCourses = courses.where((c) => !c.isFree).toList();

            return TabBarView(
              children: [
                _buildCourseList(courses, isDark),
                _buildCourseList(freeCourses, isDark),
                _buildCourseList(paidCourses, isDark),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Failed to load courses'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(coursesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList(List<Course> courses, bool isDark) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No courses available yet', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(context, course, isDark);
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, bool isDark) {
    final totalLessons = course.sections.fold(0, (sum, s) => sum + s.lessons.length);
    final totalDuration = course.sections.fold(0, (sum, s) => sum + s.lessons.fold(0, (ls, l) => ls + l.durationMinutes));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/course-detail', extra: {'courseId': course.courseId}),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: course.isFree
                      ? Colors.green.shade100
                      : const Color(0xFF0F3460).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(course.category),
                  size: 36,
                  color: course.isFree ? Colors.green.shade700 : const Color(0xFF0F3460),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (course.isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('₹${course.price}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${totalDuration} min', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(width: 12),
                        Icon(Icons.menu_book, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('$totalLessons lessons', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const Spacer(),
                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                        Text('${course.rating}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'women\'s health':
        return Icons.female;
      case 'pregnancy':
        return Icons.pregnant_woman;
      case 'menopause':
        return Icons.elderly;
      case 'fertility':
        return Icons.favorite;
      default:
        return Icons.school;
    }
  }
}
