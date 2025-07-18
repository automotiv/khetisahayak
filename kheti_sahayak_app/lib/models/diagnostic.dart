class Diagnostic {
  final String id;
  final String userId;
  final String cropType;
  final String issueDescription;
  final String? diagnosisResult;
  final String? recommendations;
  final double? confidenceScore;
  final List<String> imageUrls;
  final String status;
  final String? expertReviewId;
  final String? expertName;
  final String? expertFirstName;
  final String? expertLastName;
  final String? expertPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Diagnostic({
    required this.id,
    required this.userId,
    required this.cropType,
    required this.issueDescription,
    this.diagnosisResult,
    this.recommendations,
    this.confidenceScore,
    required this.imageUrls,
    required this.status,
    this.expertReviewId,
    this.expertName,
    this.expertFirstName,
    this.expertLastName,
    this.expertPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    return Diagnostic(
      id: json['id'],
      userId: json['user_id'],
      cropType: json['crop_type'],
      issueDescription: json['issue_description'],
      diagnosisResult: json['diagnosis_result'],
      recommendations: json['recommendations'],
      confidenceScore: json['confidence_score']?.toDouble(),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      status: json['status'] ?? 'pending',
      expertReviewId: json['expert_review_id'],
      expertName: json['expert_name'],
      expertFirstName: json['expert_first_name'],
      expertLastName: json['expert_last_name'],
      expertPhone: json['expert_phone'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'confidence_score': confidenceScore,
      'image_urls': imageUrls,
      'status': status,
      'expert_review_id': expertReviewId,
      'expert_name': expertName,
      'expert_first_name': expertFirstName,
      'expert_last_name': expertLastName,
      'expert_phone': expertPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get expertFullName {
    if (expertFirstName != null && expertLastName != null) {
      return '$expertFirstName $expertLastName';
    }
    return expertName ?? 'Unknown Expert';
  }

  bool get isResolved => status == 'resolved';
  bool get isPending => status == 'pending';
  bool get isAnalyzed => status == 'analyzed';
  bool get hasExpertReview => expertReviewId != null;
}