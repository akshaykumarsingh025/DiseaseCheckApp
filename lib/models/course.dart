class Course {
  final String courseId;
  final String title;
  final String description;
  final String category;
  final bool isFree;
  final int price;
  final String thumbnailUrl;
  final List<CourseSection> sections;
  final String instructorName;
  final double rating;
  final int enrolledCount;
  final DateTime createdAt;

  Course({
    required this.courseId,
    required this.title,
    required this.description,
    required this.category,
    this.isFree = false,
    this.price = 0,
    this.thumbnailUrl = '',
    this.sections = const [],
    this.instructorName = 'Dr. Deepika Singh',
    this.rating = 4.8,
    this.enrolledCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'General',
      isFree: json['isFree'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => CourseSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      instructorName: json['instructorName'] as String? ?? 'Dr. Deepika Singh',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      enrolledCount: json['enrolledCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'category': category,
      'isFree': isFree,
      'price': price,
      'thumbnailUrl': thumbnailUrl,
      'sections': sections.map((e) => e.toJson()).toList(),
      'instructorName': instructorName,
      'rating': rating,
      'enrolledCount': enrolledCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CourseSection {
  final String title;
  final List<CourseLesson> lessons;

  const CourseSection({
    required this.title,
    this.lessons = const [],
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    return CourseSection(
      title: json['title'] as String,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => CourseLesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'lessons': lessons.map((e) => e.toJson()).toList(),
    };
  }
}

class CourseLesson {
  final String title;
  final String type;
  final String content;
  final int durationMinutes;

  const CourseLesson({
    required this.title,
    this.type = 'text',
    this.content = '',
    this.durationMinutes = 5,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    return CourseLesson(
      title: json['title'] as String,
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'content': content,
      'durationMinutes': durationMinutes,
    };
  }
}
