import 'dart:convert';

class LogbookEntry {
  final int? id; // Local ID
  final String? backendId; // Server ID
  final String activityType;
  final String date;
  final String? description;
  final double cost;
  final double income;
  final List<String>? images; // URLs or local paths
  final int? fieldId;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final Map<String, dynamic>? weatherSnapshot;
  
  // Sync fields
  final int version;
  final bool deleted;
  final bool dirty;
  final bool synced;

  LogbookEntry({
    this.id,
    this.backendId,
    required this.activityType,
    required this.date,
    this.description,
    this.cost = 0.0,
    this.income = 0.0,
    this.images,
    this.fieldId,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.weatherSnapshot,
    this.version = 0,
    this.deleted = false,
    this.dirty = true,
    this.synced = false,
  });

  factory LogbookEntry.fromJson(Map<String, dynamic> json) {
    return LogbookEntry(
      id: json['id'] is int ? json['id'] : null,
      backendId: json['backend_id'],
      activityType: json['activity_type'],
      date: json['date'] ?? json['timestamp'],
      description: json['description'],
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      fieldId: json['field_id'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracy: (json['location_accuracy'] as num?)?.toDouble(),
      weatherSnapshot: json['weather_snapshot'] != null 
          ? (json['weather_snapshot'] is String 
              ? jsonDecode(json['weather_snapshot']) 
              : json['weather_snapshot'])
          : null,
      version: json['version'] ?? 0,
      deleted: json['deleted'] == 1 || json['deleted'] == true,
      dirty: json['dirty'] == 1 || json['dirty'] == true,
      synced: json['synced'] == 1 || json['synced'] == true,
    );
  }

  factory LogbookEntry.fromMap(Map<String, dynamic> map) {
    // Parse metadata JSON if present
    Map<String, dynamic> metadata = {};
    if (map['metadata'] != null) {
      try {
        metadata = jsonDecode(map['metadata']);
      } catch (e) {
        print('Error parsing metadata: $e');
      }
    }

    return LogbookEntry(
      id: map['id'],
      backendId: map['backend_id'],
      activityType: map['activity_type'],
      date: map['timestamp'],
      description: metadata['description'] ?? map['description'], // Fallback
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      income: (map['income'] as num?)?.toDouble() ?? 0.0, // Not in DB yet, might need adding
      images: map['photo_paths'] != null 
          ? (jsonDecode(map['photo_paths']) as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      fieldId: map['field_id'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAccuracy: (map['location_accuracy'] as num?)?.toDouble(),
      weatherSnapshot: map['weather_snapshot'] != null 
          ? jsonDecode(map['weather_snapshot']) 
          : null,
      version: map['version'] ?? 0,
      deleted: map['deleted'] == 1,
      dirty: map['dirty'] == 1,
      synced: map['synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backend_id': backendId,
      'activity_type': activityType,
      'date': date,
      'description': description,
      'cost': cost,
      'income': income,
      'images': images,
      'field_id': fieldId,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'weather_snapshot': weatherSnapshot,
      'version': version,
      'deleted': deleted,
      'dirty': dirty,
      'synced': synced,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'backend_id': backendId,
      'activity_type': activityType,
      'timestamp': date,
      'metadata': jsonEncode({'description': description}),
      'cost': cost,
      // 'income': income, // Add column to DB if needed
      'photo_paths': images != null ? jsonEncode(images) : null,
      'field_id': fieldId,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'weather_snapshot': weatherSnapshot != null ? jsonEncode(weatherSnapshot) : null,
      'version': version,
      'deleted': deleted ? 1 : 0,
      'dirty': dirty ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }
}
