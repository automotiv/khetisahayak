class EducationalContent {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String? authorId;
  final DateTime createdAt;

  EducationalContent({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.authorId,
    required this.createdAt,
  });

  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    return EducationalContent(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      authorId: json['author_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}