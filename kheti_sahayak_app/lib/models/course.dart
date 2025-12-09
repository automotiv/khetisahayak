import 'package:kheti_sahayak_app/models/module.dart';

class Course {
  final int id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String language;
  final String difficulty;
  final List<Module> modules;
  final int totalLessons;
  final int completedLessons;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.language,
    required this.difficulty,
    this.modules = const [],
    this.totalLessons = 0,
    this.completedLessons = 0,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      language: json['language'] ?? 'en',
      difficulty: json['difficulty'] ?? 'beginner',
      totalLessons: json['total_lessons'] ?? 0,
      completedLessons: json['completed_lessons'] ?? 0,
      modules: json['modules'] != null
          ? (json['modules'] as List).map((m) => Module.fromJson(m)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'language': language,
      'difficulty': difficulty,
      'total_lessons': totalLessons,
      'completed_lessons': completedLessons,
      'modules': modules.map((m) => m.toJson()).toList(),
    };
  }
}
