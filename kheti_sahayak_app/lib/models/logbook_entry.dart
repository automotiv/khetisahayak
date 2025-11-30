class LogbookEntry {
  final int id;
  final String activityType;
  final String date;
  final String? description;
  final double cost;
  final double income;
  final List<String>? images;

  LogbookEntry({
    required this.id,
    required this.activityType,
    required this.date,
    this.description,
    this.cost = 0.0,
    this.income = 0.0,
    this.images,
  });

  factory LogbookEntry.fromJson(Map<String, dynamic> json) {
    return LogbookEntry(
      id: json['id'],
      activityType: json['activity_type'],
      date: json['date'],
      description: json['description'],
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_type': activityType,
      'date': date,
      'description': description,
      'cost': cost,
      'income': income,
    };
  }
}
