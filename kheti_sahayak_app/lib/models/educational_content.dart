class EducationalContent {
  final String id;
  final String title;
  final String content;
  final String? summary;
  final String category;
  final String? subcategory;
  final String difficultyLevel;
  final String? authorId;
  final String? authorFirstName;
  final String? authorLastName;
  final String? authorUsername;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> tags;
  final bool isPublished;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  EducationalContent({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.category,
    this.subcategory,
    required this.difficultyLevel,
    this.authorId,
    this.authorFirstName,
    this.authorLastName,
    this.authorUsername,
    this.imageUrl,
    this.videoUrl,
    required this.tags,
    required this.isPublished,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    return EducationalContent(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      summary: json['summary'],
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      difficultyLevel: json['difficulty_level'] ?? 'beginner',
      authorId: json['author_id'],
      authorFirstName: json['author_first_name'],
      authorLastName: json['author_last_name'],
      authorUsername: json['author_username'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      tags: List<String>.from(json['tags'] ?? []),
      isPublished: json['is_published'] ?? true,
      viewCount: json['view_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'category': category,
      'subcategory': subcategory,
      'difficulty_level': difficultyLevel,
      'author_id': authorId,
      'author_first_name': authorFirstName,
      'author_last_name': authorLastName,
      'author_username': authorUsername,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'tags': tags,
      'is_published': isPublished,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get authorFullName {
    if (authorFirstName != null && authorLastName != null) {
      return '$authorFirstName $authorLastName';
    }
    return authorUsername ?? 'Unknown Author';
  }

  String get difficultyDisplay {
    switch (difficultyLevel.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasSummary => summary != null && summary!.isNotEmpty;
}