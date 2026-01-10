/// Consultation Model
/// 
/// Represents a consultation booking between a farmer and an expert

class Consultation {
  final String id;
  final String farmerId;
  final String expertId;
  final String expertName;
  final String? expertImageUrl;
  final String expertSpecialization;
  final DateTime scheduledAt;
  final int durationMinutes;
  final ConsultationType type;
  final ConsultationStatus status;
  final double fee;
  final String? issueDescription;
  final List<String>? attachedImages;
  final String? expertNotes;
  final List<String>? recommendations;
  final String? meetingLink;
  final DateTime createdAt;
  final DateTime? completedAt;
  final ConsultationReview? review;

  Consultation({
    required this.id,
    required this.farmerId,
    required this.expertId,
    required this.expertName,
    this.expertImageUrl,
    required this.expertSpecialization,
    required this.scheduledAt,
    this.durationMinutes = 30,
    required this.type,
    required this.status,
    required this.fee,
    this.issueDescription,
    this.attachedImages,
    this.expertNotes,
    this.recommendations,
    this.meetingLink,
    required this.createdAt,
    this.completedAt,
    this.review,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'] ?? '',
      farmerId: json['farmer_id'] ?? json['farmerId'] ?? '',
      expertId: json['expert_id'] ?? json['expertId'] ?? '',
      expertName: json['expert_name'] ?? json['expertName'] ?? '',
      expertImageUrl: json['expert_image_url'] ?? json['expertImageUrl'],
      expertSpecialization: json['expert_specialization'] ?? json['expertSpecialization'] ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? json['scheduledAt'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 30,
      type: ConsultationType.fromString(json['type'] ?? 'video'),
      status: ConsultationStatus.fromString(json['status'] ?? 'pending'),
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      issueDescription: json['issue_description'] ?? json['issueDescription'],
      attachedImages: (json['attached_images'] ?? json['attachedImages'] as List?)?.cast<String>(),
      expertNotes: json['expert_notes'] ?? json['expertNotes'],
      recommendations: (json['recommendations'] as List?)?.cast<String>(),
      meetingLink: json['meeting_link'] ?? json['meetingLink'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completed_at'] != null || json['completedAt'] != null
          ? DateTime.parse(json['completed_at'] ?? json['completedAt'])
          : null,
      review: json['review'] != null ? ConsultationReview.fromJson(json['review']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'expert_id': expertId,
      'expert_name': expertName,
      'expert_image_url': expertImageUrl,
      'expert_specialization': expertSpecialization,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'type': type.value,
      'status': status.value,
      'fee': fee,
      'issue_description': issueDescription,
      'attached_images': attachedImages,
      'expert_notes': expertNotes,
      'recommendations': recommendations,
      'meeting_link': meetingLink,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'review': review?.toJson(),
    };
  }

  Consultation copyWith({
    String? id,
    String? farmerId,
    String? expertId,
    String? expertName,
    String? expertImageUrl,
    String? expertSpecialization,
    DateTime? scheduledAt,
    int? durationMinutes,
    ConsultationType? type,
    ConsultationStatus? status,
    double? fee,
    String? issueDescription,
    List<String>? attachedImages,
    String? expertNotes,
    List<String>? recommendations,
    String? meetingLink,
    DateTime? createdAt,
    DateTime? completedAt,
    ConsultationReview? review,
  }) {
    return Consultation(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      expertId: expertId ?? this.expertId,
      expertName: expertName ?? this.expertName,
      expertImageUrl: expertImageUrl ?? this.expertImageUrl,
      expertSpecialization: expertSpecialization ?? this.expertSpecialization,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      status: status ?? this.status,
      fee: fee ?? this.fee,
      issueDescription: issueDescription ?? this.issueDescription,
      attachedImages: attachedImages ?? this.attachedImages,
      expertNotes: expertNotes ?? this.expertNotes,
      recommendations: recommendations ?? this.recommendations,
      meetingLink: meetingLink ?? this.meetingLink,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      review: review ?? this.review,
    );
  }

  // Helper getters
  bool get isUpcoming => status == ConsultationStatus.confirmed && scheduledAt.isAfter(DateTime.now());
  bool get canJoin => status == ConsultationStatus.confirmed && 
      scheduledAt.difference(DateTime.now()).inMinutes <= 5 &&
      scheduledAt.difference(DateTime.now()).inMinutes >= -durationMinutes;
  bool get canCancel => status == ConsultationStatus.pending || 
      (status == ConsultationStatus.confirmed && scheduledAt.difference(DateTime.now()).inHours >= 2);
  bool get canReview => status == ConsultationStatus.completed && review == null;
}

enum ConsultationType {
  video('video'),
  audio('audio'),
  chat('chat');

  final String value;
  const ConsultationType(this.value);

  static ConsultationType fromString(String value) {
    return ConsultationType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ConsultationType.video,
    );
  }

  String get displayName {
    switch (this) {
      case ConsultationType.video:
        return 'Video Call';
      case ConsultationType.audio:
        return 'Audio Call';
      case ConsultationType.chat:
        return 'Chat';
    }
  }
}

enum ConsultationStatus {
  pending('pending'),
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  noShow('no_show');

  final String value;
  const ConsultationStatus(this.value);

  static ConsultationStatus fromString(String value) {
    return ConsultationStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ConsultationStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.confirmed:
        return 'Confirmed';
      case ConsultationStatus.inProgress:
        return 'In Progress';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
      case ConsultationStatus.noShow:
        return 'No Show';
    }
  }
}

class ConsultationReview {
  final String id;
  final String consultationId;
  final String farmerId;
  final String expertId;
  final int rating;
  final String? comment;
  final bool wasHelpful;
  final bool wouldRecommend;
  final DateTime createdAt;

  ConsultationReview({
    required this.id,
    required this.consultationId,
    required this.farmerId,
    required this.expertId,
    required this.rating,
    this.comment,
    required this.wasHelpful,
    required this.wouldRecommend,
    required this.createdAt,
  });

  factory ConsultationReview.fromJson(Map<String, dynamic> json) {
    return ConsultationReview(
      id: json['id'] ?? '',
      consultationId: json['consultation_id'] ?? json['consultationId'] ?? '',
      farmerId: json['farmer_id'] ?? json['farmerId'] ?? '',
      expertId: json['expert_id'] ?? json['expertId'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      wasHelpful: json['was_helpful'] ?? json['wasHelpful'] ?? false,
      wouldRecommend: json['would_recommend'] ?? json['wouldRecommend'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consultation_id': consultationId,
      'farmer_id': farmerId,
      'expert_id': expertId,
      'rating': rating,
      'comment': comment,
      'was_helpful': wasHelpful,
      'would_recommend': wouldRecommend,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      startTime: DateTime.parse(json['start_time'] ?? json['startTime']),
      endTime: DateTime.parse(json['end_time'] ?? json['endTime']),
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
    );
  }

  String get formattedTime {
    final hour = startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
