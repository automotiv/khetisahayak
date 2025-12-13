enum ApplicationStatus {
  submitted,
  underReview,
  approved,
  rejected,
  disbursed,
}

class ApplicationTimelineEvent {
  final ApplicationStatus status;
  final DateTime date;
  final String description;

  ApplicationTimelineEvent({
    required this.status,
    required this.date,
    required this.description,
  });

  factory ApplicationTimelineEvent.fromJson(Map<String, dynamic> json) {
    return ApplicationTimelineEvent(
      status: ApplicationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ApplicationStatus.submitted,
      ),
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.toString(),
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}
