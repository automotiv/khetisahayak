import 'package:kheti_sahayak_app/models/lesson.dart';

class Module {
  final int id;
  final int courseId;
  final String title;
  final int order;
  final List<Lesson> lessons;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    this.lessons = const [],
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      order: json['order'] ?? 0,
      lessons: json['lessons'] != null
          ? (json['lessons'] as List).map((l) => Lesson.fromJson(l)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'order': order,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }
}
