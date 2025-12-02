class CropRotation {
  final int? id;
  final int fieldId;
  final String cropName;
  final String season; // e.g., Kharif, Rabi, Zaid
  final int year;
  final String status; // e.g., Planned, Active, Completed
  final String? notes;

  CropRotation({
    this.id,
    required this.fieldId,
    required this.cropName,
    required this.season,
    required this.year,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_id': fieldId,
      'crop_name': cropName,
      'season': season,
      'year': year,
      'status': status,
      'notes': notes,
    };
  }

  factory CropRotation.fromMap(Map<String, dynamic> map) {
    return CropRotation(
      id: map['id'],
      fieldId: map['field_id'],
      cropName: map['crop_name'],
      season: map['season'],
      year: map['year'],
      status: map['status'],
      notes: map['notes'],
    );
  }
}
