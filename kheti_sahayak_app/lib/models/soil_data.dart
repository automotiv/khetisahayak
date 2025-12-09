class SoilData {
  final int? id;
  final int fieldId;
  final DateTime testDate;
  final double? pH;
  final double? organicCarbon; // Percentage
  final double? nitrogen; // kg/ha
  final double? phosphorus; // kg/ha
  final double? potassium; // kg/ha
  final String? notes;

  SoilData({
    this.id,
    required this.fieldId,
    required this.testDate,
    this.pH,
    this.organicCarbon,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_id': fieldId,
      'test_date': testDate.toIso8601String(),
      'ph': pH,
      'organic_carbon': organicCarbon,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'notes': notes,
    };
  }

  factory SoilData.fromMap(Map<String, dynamic> map) {
    return SoilData(
      id: map['id'],
      fieldId: map['field_id'],
      testDate: DateTime.parse(map['test_date']),
      pH: map['ph'],
      organicCarbon: map['organic_carbon'],
      nitrogen: map['nitrogen'],
      phosphorus: map['phosphorus'],
      potassium: map['potassium'],
      notes: map['notes'],
    );
  }
}
