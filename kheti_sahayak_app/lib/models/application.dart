import 'package:kheti_sahayak_app/models/application_timeline_event.dart';

class Application {
  final String id;
  final String schemeId;
  final String schemeName; // Denormalized for easier display
  final String userId;
  final ApplicationStatus status;
  final DateTime submissionDate;
  final DateTime? expectedDisbursementDate;
  final List<ApplicationTimelineEvent> timeline;
  final String? remarks;

  Application({
    required this.id,
    required this.schemeId,
    required this.schemeName,
    required this.userId,
    required this.status,
    required this.submissionDate,
    this.expectedDisbursementDate,
    required this.timeline,
    this.remarks,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      schemeId: json['schemeId'],
      schemeName: json['schemeName'] ?? 'Unknown Scheme',
      userId: json['userId'],
      status: ApplicationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ApplicationStatus.submitted,
      ),
      submissionDate: DateTime.parse(json['submissionDate']),
      expectedDisbursementDate: json['expectedDisbursementDate'] != null
          ? DateTime.parse(json['expectedDisbursementDate'])
          : null,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => ApplicationTimelineEvent.fromJson(e))
              .toList() ??
          [],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schemeId': schemeId,
      'schemeName': schemeName,
      'userId': userId,
      'status': status.toString(),
      'submissionDate': submissionDate.toIso8601String(),
      'expectedDisbursementDate': expectedDisbursementDate?.toIso8601String(),
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'remarks': remarks,
    };
  }

  Application copyWith({
    String? id,
    String? schemeId,
    String? schemeName,
    String? userId,
    ApplicationStatus? status,
    DateTime? submissionDate,
    DateTime? expectedDisbursementDate,
    List<ApplicationTimelineEvent>? timeline,
    String? remarks,
  }) {
    return Application(
      id: id ?? this.id,
      schemeId: schemeId ?? this.schemeId,
      schemeName: schemeName ?? this.schemeName,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      submissionDate: submissionDate ?? this.submissionDate,
      expectedDisbursementDate: expectedDisbursementDate ?? this.expectedDisbursementDate,
      timeline: timeline ?? this.timeline,
      remarks: remarks ?? this.remarks,
    );
  }
}
