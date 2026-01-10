/// Expert Model
/// 
/// Represents an agricultural expert who can provide consultations

class Expert {
  final String id;
  final String name;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final int totalConsultations;
  final String? imageUrl;
  final bool isOnline;
  final bool isVerified;
  final String? bio;
  final List<String> expertiseAreas;
  final List<String> languages;
  final double consultationFee;
  final int responseTimeMinutes;
  final Map<String, List<String>>? availability;
  final List<ExpertReview>? reviews;

  Expert({
    required this.id,
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.rating,
    this.reviewCount = 0,
    this.totalConsultations = 0,
    this.imageUrl,
    this.isOnline = false,
    this.isVerified = false,
    this.bio,
    this.expertiseAreas = const [],
    this.languages = const ['English', 'Hindi'],
    this.consultationFee = 200.0,
    this.responseTimeMinutes = 30,
    this.availability,
    this.reviews,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      qualification: json['qualification'] ?? '',
      experienceYears: json['experience_years'] ?? json['experienceYears'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
      totalConsultations: json['total_consultations'] ?? json['totalConsultations'] ?? 0,
      imageUrl: json['image_url'] ?? json['imageUrl'],
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      bio: json['bio'],
      expertiseAreas: (json['expertise_areas'] ?? json['expertiseAreas'] as List?)?.cast<String>() ?? [],
      languages: (json['languages'] as List?)?.cast<String>() ?? ['English', 'Hindi'],
      consultationFee: (json['consultation_fee'] ?? json['consultationFee'] as num?)?.toDouble() ?? 200.0,
      responseTimeMinutes: json['response_time_minutes'] ?? json['responseTimeMinutes'] ?? 30,
      availability: json['availability'] != null 
          ? Map<String, List<String>>.from(
              (json['availability'] as Map).map((key, value) => 
                MapEntry(key.toString(), (value as List).cast<String>())))
          : null,
      reviews: (json['reviews'] as List?)
          ?.map((r) => ExpertReview.fromJson(r))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'qualification': qualification,
      'experience_years': experienceYears,
      'rating': rating,
      'review_count': reviewCount,
      'total_consultations': totalConsultations,
      'image_url': imageUrl,
      'is_online': isOnline,
      'is_verified': isVerified,
      'bio': bio,
      'expertise_areas': expertiseAreas,
      'languages': languages,
      'consultation_fee': consultationFee,
      'response_time_minutes': responseTimeMinutes,
      'availability': availability,
      'reviews': reviews?.map((r) => r.toJson()).toList(),
    };
  }

  // Helper getters
  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedFee => '₹${consultationFee.toStringAsFixed(0)}';
  String get experienceText => '$experienceYears years';
  String get languagesText => languages.join(', ');
}

class ExpertReview {
  final String id;
  final String farmerName;
  final String? farmerImageUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ExpertReview({
    required this.id,
    required this.farmerName,
    this.farmerImageUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ExpertReview.fromJson(Map<String, dynamic> json) {
    return ExpertReview(
      id: json['id']?.toString() ?? '',
      farmerName: json['farmer_name'] ?? json['farmerName'] ?? 'Anonymous',
      farmerImageUrl: json['farmer_image_url'] ?? json['farmerImageUrl'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_name': farmerName,
      'farmer_image_url': farmerImageUrl,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
