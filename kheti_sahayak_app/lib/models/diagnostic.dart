class Diagnostic {
  final String id;
  final String userId;
  final String cropType;
  final String issueDescription;
  final String? diagnosisResult;
  final String? recommendations;
  final String? imageUrl;
  final DateTime createdAt;

  Diagnostic({
    required this.id,
    required this.userId,
    required this.cropType,
    required this.issueDescription,
    this.diagnosisResult,
    this.recommendations,
    this.imageUrl,
    required this.createdAt,
  });

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    return Diagnostic(
      id: json['id'],
      userId: json['user_id'],
      cropType: json['crop_type'],
      issueDescription: json['issue_description'],
      diagnosisResult: json['diagnosis_result'],
      recommendations: json['recommendations'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'crop_type': cropType,
      'issue_description': issueDescription,
      'diagnosis_result': diagnosisResult,
      'recommendations': recommendations,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}