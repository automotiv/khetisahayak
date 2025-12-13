class Field {
  final int? id;
  final String name;
  final double area; // in acres
  final String cropType;
  final String location;
  // New properties for Multi-field Management
  final List<Map<String, double>> boundaries; // simplified geo-points
  final String soilType;
  final String irrigationSource;
  final bool isActive;

  Field({
    this.id,
    required this.name,
    required this.area,
    required this.cropType,
    required this.location,
    this.boundaries = const [],
    this.soilType = 'Unknown',
    this.irrigationSource = 'Rainfed',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'crop_type': cropType,
      'location': location,
      'boundaries': boundaries.isEmpty ? null : boundaries, // serialized as JSON implicitly by some DB wrappers, but better to be explicit if using raw SQLite. For now keeping it simple as List<Map>.
      'soil_type': soilType,
      'irrigation_source': irrigationSource,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Field.fromMap(Map<String, dynamic> map) {
    return Field(
      id: map['id'],
      name: map['name'],
      area: (map['area'] as num).toDouble(),
      cropType: map['crop_type'],
      location: map['location'],
      boundaries: map['boundaries'] != null 
          ? List<Map<String, double>>.from((map['boundaries'] as List).map((e) => Map<String, double>.from(e)))
          : [],
      soilType: map['soil_type'] ?? 'Unknown',
      irrigationSource: map['irrigation_source'] ?? 'Rainfed',
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }
}
