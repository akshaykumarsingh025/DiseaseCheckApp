import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_provider.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../services/payment_service.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  PaymentService? _paymentService;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(
      onSuccess: _onPaymentSuccess,
      onFailure: _onPaymentFailure,
    );
  }

  @override
  void dispose() {
    _paymentService?.dispose();
    super.dispose();
  }

  Future<void> _onPaymentSuccess(Map<String, dynamic> response) async {
    await CourseService.enrollPaidCourse(widget.courseId, response['paymentId'] as String? ?? '');
    ref.invalidate(isEnrolledProvider(widget.courseId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrolled successfully!'), backgroundColor: Colors.green),
      );
    }
    setState(() => _isEnrolling = false);
  }

  void _onPaymentFailure(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $error'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isEnrolling = false);
  }

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    final courseAsync = ref.read(courseDetailProvider(widget.courseId));
    final course = courseAsync.valueOrNull;

    if (course == null) {
      setState(() => _isEnrolling = false);
      return;
    }

    if (course.isFree) {
      await CourseService.enrollFreeCourse(widget.courseId);
      ref.invalidate(isEnrolledProvider(widget.courseId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrolled successfully!'), backgroundColor: Colors.green),
        );
      }
      setState(() => _isEnrolling = false);
    } else {
      _paymentService?.openCheckout(
        amount: course.price,
        title: course.title,
        description: 'Course enrollment',
        appointmentId: widget.courseId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final isEnrolledAsync = ref.watch(isEnrolledProvider(widget.courseId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return courseAsync.when(
      data: (course) {
        if (course == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Course')),
            body: const Center(child: Text('Course not found')),
          );
        }

        final isEnrolled = isEnrolledAsync.valueOrNull ?? false;

        return Scaffold(
          appBar: AppBar(title: Text(course.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(course, isDark),
                const SizedBox(height: 20),
                _buildStatsRow(course),
                const SizedBox(height: 20),
                Text('About This Course', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(course.description, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                const SizedBox(height: 20),
                Text('Instructor', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInstructorCard(isDark),
                const SizedBox(height: 24),
                Text('Course Content', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...course.sections.map((section) => _buildSection(section, isEnrolled, isDark)),
                const SizedBox(height: 24),
                if (!isEnrolled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isEnrolling ? null : _enroll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3460),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isEnrolling
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              course.isFree ? 'Enroll for Free' : 'Enroll - ₹${course.price}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                if (isEnrolled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_circle),
                      label: const Text('Start Learning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Course')),
        body: const Center(child: Text('Failed to load course')),
      ),
    );
  }

  Widget _buildHeader(Course course, bool isDark) {
    return Card(
      color: isDark ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school, size: 32, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(course.category, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (course.isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('FREE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('₹${course.price}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Course course) {
    final totalLessons = course.sections.fold(0, (sum, s) => sum + s.lessons.length);
    final totalDuration = course.sections.fold(0, (sum, s) => sum + s.lessons.fold(0, (ls, l) => ls + l.durationMinutes));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.menu_book, '$totalLessons', 'Lessons'),
        _buildStatItem(Icons.schedule, '$totalDuration', 'Minutes'),
        _buildStatItem(Icons.star, '${course.rating}', 'Rating'),
        _buildStatItem(Icons.people, '${course.enrolledCount}', 'Enrolled'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildInstructorCard(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.pink.shade100,
              child: Icon(Icons.local_hospital, color: Colors.pink.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dr. Deepika Singh', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('MD AIIMS | Senior Consultant', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(CourseSection section, bool isEnrolled, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${section.lessons.length} lessons'),
        children: section.lessons.map((lesson) => ListTile(
          dense: true,
          leading: Icon(
            isEnrolled ? Icons.play_circle_outline : Icons.lock_outline,
            size: 20,
            color: isEnrolled ? Colors.green : Colors.grey,
          ),
          title: Text(lesson.title, style: const TextStyle(fontSize: 13)),
          trailing: Text('${lesson.durationMinutes} min', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        )).toList(),
      ),
    );
  }
}
