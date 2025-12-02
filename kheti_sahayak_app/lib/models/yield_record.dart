class YieldRecord {
  final int? id;
  final int fieldId;
  final String cropName;
  final DateTime harvestDate;
  final double yieldAmount;
  final String unit;
  final String? notes;
  final double marketPrice;

  YieldRecord({
    this.id,
    required this.fieldId,
    required this.cropName,
    required this.harvestDate,
    required this.yieldAmount,
    required this.unit,
    this.notes,
    this.marketPrice = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_id': fieldId,
      'crop_name': cropName,
      'harvest_date': harvestDate.toIso8601String(),
      'yield_amount': yieldAmount,
      'unit': unit,
      'notes': notes,
      'market_price': marketPrice,
    };
  }

  factory YieldRecord.fromMap(Map<String, dynamic> map) {
    return YieldRecord(
      id: map['id'],
      fieldId: map['field_id'],
      cropName: map['crop_name'],
      harvestDate: DateTime.parse(map['harvest_date']),
      yieldAmount: map['yield_amount'],
      unit: map['unit'],
      notes: map['notes'],
      marketPrice: (map['market_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
