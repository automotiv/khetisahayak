import 'package:kheti_sahayak_app/models/quiz.dart';

/// Learning module containing lessons, quizzes, and resources
class LearningModule {
  final int id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String category;
  final String difficulty; // beginner, intermediate, advanced
  final int estimatedDuration; // In minutes
  final List<LearningLesson> lessons;
  final Quiz? quiz;
  final List<String> tags;
  final int pointsReward;
  final String? certificateTemplate;
  final bool isDownloaded;
  final DateTime? lastAccessed;

  LearningModule({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.category,
    this.difficulty = 'beginner',
    this.estimatedDuration = 0,
    this.lessons = const [],
    this.quiz,
    this.tags = const [],
    this.pointsReward = 0,
    this.certificateTemplate,
    this.isDownloaded = false,
    this.lastAccessed,
  });

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    return LearningModule(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      category: json['category'] ?? 'general',
      difficulty: json['difficulty'] ?? 'beginner',
      estimatedDuration: json['estimated_duration'] ?? 0,
      lessons: json['lessons'] != null
          ? (json['lessons'] as List)
              .map((l) => LearningLesson.fromJson(l))
              .toList()
          : [],
      quiz: json['quiz'] != null ? Quiz.fromJson(json['quiz']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      pointsReward: json['points_reward'] ?? 0,
      certificateTemplate: json['certificate_template'],
      isDownloaded: json['is_downloaded'] == true || json['is_downloaded'] == 1,
      lastAccessed: json['last_accessed'] != null
          ? DateTime.parse(json['last_accessed'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'difficulty': difficulty,
      'estimated_duration': estimatedDuration,
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'quiz': quiz?.toJson(),
      'tags': tags,
      'points_reward': pointsReward,
      'certificate_template': certificateTemplate,
      'is_downloaded': isDownloaded,
      'last_accessed': lastAccessed?.toIso8601String(),
    };
  }

  LearningModule copyWith({
    int? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? category,
    String? difficulty,
    int? estimatedDuration,
    List<LearningLesson>? lessons,
    Quiz? quiz,
    List<String>? tags,
    int? pointsReward,
    String? certificateTemplate,
    bool? isDownloaded,
    DateTime? lastAccessed,
  }) {
    return LearningModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      lessons: lessons ?? this.lessons,
      quiz: quiz ?? this.quiz,
      tags: tags ?? this.tags,
      pointsReward: pointsReward ?? this.pointsReward,
      certificateTemplate: certificateTemplate ?? this.certificateTemplate,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  int get totalLessons => lessons.length;
  int get completedLessons => lessons.where((l) => l.isCompleted).length;
  double get progress =>
      totalLessons > 0 ? completedLessons / totalLessons : 0.0;
  bool get isCompleted => totalLessons > 0 && completedLessons == totalLessons;
}

/// Individual lesson within a learning module
class LearningLesson {
  final int id;
  final int moduleId;
  final String title;
  final LessonType type;
  final String? content; // Text content or URL
  final String? videoUrl;
  final List<String> imageUrls;
  final int duration; // In minutes
  final int order;
  final bool isCompleted;
  final String? localContentPath;

  LearningLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.type,
    this.content,
    this.videoUrl,
    this.imageUrls = const [],
    this.duration = 0,
    this.order = 0,
    this.isCompleted = false,
    this.localContentPath,
  });

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    return LearningLesson(
      id: json['id'],
      moduleId: json['module_id'],
      title: json['title'],
      type: LessonType.fromString(json['type'] ?? 'article'),
      content: json['content'],
      videoUrl: json['video_url'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      duration: json['duration'] ?? 0,
      order: json['order'] ?? 0,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      localContentPath: json['local_content_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'type': type.value,
      'content': content,
      'video_url': videoUrl,
      'image_urls': imageUrls,
      'duration': duration,
      'order': order,
      'is_completed': isCompleted,
      'local_content_path': localContentPath,
    };
  }

  LearningLesson copyWith({
    int? id,
    int? moduleId,
    String? title,
    LessonType? type,
    String? content,
    String? videoUrl,
    List<String>? imageUrls,
    int? duration,
    int? order,
    bool? isCompleted,
    String? localContentPath,
  }) {
    return LearningLesson(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      duration: duration ?? this.duration,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      localContentPath: localContentPath ?? this.localContentPath,
    );
  }

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasImages => imageUrls.isNotEmpty;
  bool get isAvailableOffline =>
      localContentPath != null && localContentPath!.isNotEmpty;
}

/// Lesson type enum
enum LessonType {
  article('article'),
  video('video'),
  infographic('infographic'),
  interactive('interactive');

  final String value;
  const LessonType(this.value);

  static LessonType fromString(String value) {
    return LessonType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LessonType.article,
    );
  }
}

/// Module category for filtering
class ModuleCategory {
  final String id;
  final String name;
  final String? iconUrl;
  final int moduleCount;

  ModuleCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.moduleCount = 0,
  });

  factory ModuleCategory.fromJson(Map<String, dynamic> json) {
    return ModuleCategory(
      id: json['id'],
      name: json['name'],
      iconUrl: json['icon_url'],
      moduleCount: json['module_count'] ?? 0,
    );
  }
}
