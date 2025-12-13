class CropRotation {
  final int? id;
  final int fieldId;
  final String cropName;
  final String season; // e.g., Kharif, Rabi, Zaid
  final int year;
  final String status; // Planned, Active, Completed, Harvested
  final DateTime? plantedDate;
  final DateTime? harvestedDate;
  final double? yieldAmount; // in kg/ton depending on unit
  final String? notes;

  CropRotation({
    this.id,
    required this.fieldId,
    required this.cropName,
    required this.season,
    required this.year,
    required this.status,
    this.plantedDate,
    this.harvestedDate,
    this.yieldAmount,
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
      'planted_date': plantedDate?.toIso8601String(),
      'harvested_date': harvestedDate?.toIso8601String(),
      'yield_amount': yieldAmount,
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
      plantedDate: map['planted_date'] != null ? DateTime.parse(map['planted_date']) : null,
      harvestedDate: map['harvested_date'] != null ? DateTime.parse(map['harvested_date']) : null,
      yieldAmount: (map['yield_amount'] as num?)?.toDouble(),
      notes: map['notes'],
    );
  }
}
