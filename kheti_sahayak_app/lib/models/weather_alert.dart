/// Weather Alert Model
///
/// Represents a weather alert with severity levels and recommendations
/// for farmers to take necessary precautions.
class WeatherAlert {
  final String id;
  final String type; // heat_wave, heavy_rain, frost, storm, drought
  final String severity; // low, moderate, high, severe
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String recommendation;
  final double? latitude;
  final double? longitude;
  final String? affectedArea;
  final DateTime? createdAt;

  WeatherAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.recommendation,
    this.latitude,
    this.longitude,
    this.affectedArea,
    this.createdAt,
  });

  /// Check if the alert is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if the alert has expired
  bool get isExpired {
    return DateTime.now().isAfter(endTime);
  }

  /// Get the remaining time until alert ends
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  /// Get the remaining time as a formatted string
  String get remainingTimeFormatted {
    final remaining = remainingTime;
    if (remaining == Duration.zero) return 'Expired';
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
    } else {
      return '${remaining.inMinutes}m left';
    }
  }

  /// Severity level as an integer (for sorting)
  int get severityLevel {
    switch (severity.toLowerCase()) {
      case 'severe':
        return 4;
      case 'high':
        return 3;
      case 'moderate':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  /// Create from JSON
  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'unknown',
      severity: json['severity'] ?? 'low',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now().add(const Duration(hours: 24)),
      recommendation: json['recommendation'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      affectedArea: json['affected_area'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'recommendation': recommendation,
      'latitude': latitude,
      'longitude': longitude,
      'affected_area': affectedArea,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  WeatherAlert copyWith({
    String? id,
    String? type,
    String? severity,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? recommendation,
    double? latitude,
    double? longitude,
    String? affectedArea,
    DateTime? createdAt,
  }) {
    return WeatherAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recommendation: recommendation ?? this.recommendation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      affectedArea: affectedArea ?? this.affectedArea,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WeatherAlert(id: $id, type: $type, severity: $severity, title: $title)';
  }
}

/// Available alert types for subscription
class AlertType {
  static const String heatWave = 'heat_wave';
  static const String heavyRain = 'heavy_rain';
  static const String frost = 'frost';
  static const String storm = 'storm';
  static const String drought = 'drought';
  static const String flood = 'flood';
  static const String hailstorm = 'hailstorm';
  static const String strongWind = 'strong_wind';

  static List<String> get all => [
        heatWave,
        heavyRain,
        frost,
        storm,
        drought,
        flood,
        hailstorm,
        strongWind,
      ];

  static String getDisplayName(String type) {
    switch (type) {
      case heatWave:
        return 'Heat Wave';
      case heavyRain:
        return 'Heavy Rain';
      case frost:
        return 'Frost';
      case storm:
        return 'Storm';
      case drought:
        return 'Drought';
      case flood:
        return 'Flood';
      case hailstorm:
        return 'Hailstorm';
      case strongWind:
        return 'Strong Wind';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  static String getIcon(String type) {
    switch (type) {
      case heatWave:
        return 'wb_sunny';
      case heavyRain:
        return 'water_drop';
      case frost:
        return 'ac_unit';
      case storm:
        return 'thunderstorm';
      case drought:
        return 'wb_twilight';
      case flood:
        return 'waves';
      case hailstorm:
        return 'grain';
      case strongWind:
        return 'air';
      default:
        return 'warning';
    }
  }
}

/// Alert severity levels
class AlertSeverity {
  static const String low = 'low';
  static const String moderate = 'moderate';
  static const String high = 'high';
  static const String severe = 'severe';

  static List<String> get all => [low, moderate, high, severe];

  static String getDisplayName(String severity) {
    switch (severity) {
      case low:
        return 'Low';
      case moderate:
        return 'Moderate';
      case high:
        return 'High';
      case severe:
        return 'Severe';
      default:
        return severity.toUpperCase();
    }
  }
}
