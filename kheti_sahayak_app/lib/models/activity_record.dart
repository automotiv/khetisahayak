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
  final Map<String, dynamic>? weatherSnapshot;
  
  // Photo and GPS fields
  final List<String> photoPaths;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;

  ActivityRecord({
    this.id,
    this.fieldId,
    required this.activityType,
    required this.timestamp,
    required this.timezoneOffset,
    this.metadata = const {},
    this.synced = 0,
    this.cost = 0.0,
    this.weatherSnapshot,
    this.photoPaths = const [],
    this.latitude,
    this.longitude,
    this.locationAccuracy,
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
      'weather_snapshot': weatherSnapshot != null ? jsonEncode(weatherSnapshot) : null,
      'photo_paths': photoPaths.isNotEmpty ? jsonEncode(photoPaths) : null,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
    };
  }

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    // Parse photo paths from JSON
    List<String> photos = [];
    if (map['photo_paths'] != null && map['photo_paths'] is String) {
      try {
        final decoded = jsonDecode(map['photo_paths']);
        if (decoded is List) {
          photos = decoded.cast<String>();
        }
      } catch (e) {
        print('Error parsing photo_paths: $e');
      }
    }
    
    return ActivityRecord(
      id: map['id'],
      fieldId: map['field_id'],
      activityType: map['activity_type'],
      timestamp: DateTime.parse(map['timestamp']),
      timezoneOffset: map['timezone_offset'] ?? '',
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : {},
      synced: map['synced'] ?? 0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      weatherSnapshot: map['weather_snapshot'] != null ? jsonDecode(map['weather_snapshot']) : null,
      photoPaths: photos,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAccuracy: (map['location_accuracy'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ActivityRecord.fromJson(String source) =>
      ActivityRecord.fromMap(json.decode(source));
}
