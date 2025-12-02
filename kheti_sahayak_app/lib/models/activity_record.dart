import 'dart:convert';

class ActivityRecord {
  final int? id;
  final int? fieldId;
  final String activityType;
  final DateTime timestamp;
  final String timezoneOffset;
  final Map<String, dynamic> metadata;
  final int synced;
  final double cost;

  ActivityRecord({
    this.id,
    this.fieldId,
    required this.activityType,
    required this.timestamp,
    required this.timezoneOffset,
    this.metadata = const {},
    this.synced = 0,
    this.cost = 0.0,
  });

  // Convert a ActivityRecord into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_id': fieldId,
      'activity_type': activityType,
      'timestamp': timestamp.toIso8601String(),
      'timezone_offset': timezoneOffset,
      'metadata': jsonEncode(metadata),
      'synced': synced,
      'cost': cost,
    };
  }

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['id'],
      fieldId: map['field_id'],
      activityType: map['activity_type'],
      timestamp: DateTime.parse(map['timestamp']),
      timezoneOffset: map['timezone_offset'] ?? '',
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : {},
      synced: map['synced'] ?? 0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ActivityRecord.fromJson(String source) =>
      ActivityRecord.fromMap(json.decode(source));
}
