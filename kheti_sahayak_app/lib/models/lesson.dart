class Lesson {
  final int id;
  final int moduleId;
  final String title;
  final String type; // 'video', 'article', 'quiz'
  final String? contentUrl; // Video URL or Article content
  final String? localContentPath; // For offline access
  final int duration; // In minutes
  final bool isCompleted;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.type,
    this.contentUrl,
    this.localContentPath,
    this.duration = 0,
    this.isCompleted = false,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      moduleId: json['module_id'],
      title: json['title'],
      type: json['type'],
      contentUrl: json['content_url'],
      localContentPath: json['local_content_path'],
      duration: json['duration'] ?? 0,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'type': type,
      'content_url': contentUrl,
      'local_content_path': localContentPath,
      'duration': duration,
      'is_completed': isCompleted,
    };
  }
}
