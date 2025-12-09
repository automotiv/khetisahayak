class Recommendation {
  final String id;
  final String type; // 'Crop', 'Input', 'Market'
  final String title;
  final String description;
  final double confidence; // 0.0 to 1.0
  final int relatedFieldId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Recommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.relatedFieldId,
    required this.timestamp,
    this.metadata,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      confidence: json['confidence'].toDouble(),
      relatedFieldId: json['related_field_id'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'confidence': confidence,
      'related_field_id': relatedFieldId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
