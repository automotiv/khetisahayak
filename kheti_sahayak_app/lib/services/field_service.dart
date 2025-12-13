import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/models/crop_rotation.dart';
import 'package:kheti_sahayak_app/models/yield_record.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/models/soil_data.dart';

class FieldService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ================== FIELD OPERATIONS ==================

  /// Add a new field
  Future<int> addField(Field field) async {
    return await _dbHelper.insertField(field.toMap());
  }

  /// Get all fields
  Future<List<Field>> getFields() async {
    final maps = await _dbHelper.getFields();
    return maps.map((map) => Field.fromMap(map)).toList();
  }

  // ================== CROP ROTATION OPERATIONS ==================

  /// Add a crop rotation plan
  Future<int> addCropRotation(CropRotation rotation) async {
    return await _dbHelper.insertCropRotation(rotation.toMap());
  }

  /// Get crop rotations for a specific field
  Future<List<CropRotation>> getCropRotations(int fieldId) async {
    final maps = await _dbHelper.getCropRotations(fieldId);
    return maps.map((map) => CropRotation.fromMap(map)).toList();
  }

  /// Update a crop rotation plan
  Future<int> updateCropRotation(CropRotation rotation) async {
    if (rotation.id == null) {
      throw Exception('Cannot update rotation without ID');
    }
    return await _dbHelper.updateCropRotation(rotation.id!, rotation.toMap());
  }

  /// Delete a crop rotation plan
  Future<int> deleteCropRotation(int id) async {
    return await _dbHelper.deleteCropRotation(id);
  }

  // ================== YIELD RECORD OPERATIONS ==================

  /// Add a yield record
  Future<int> addYieldRecord(YieldRecord record) async {
    return await _dbHelper.insertYieldRecord(record.toMap());
  }

  /// Get yield history for a field
  Future<List<YieldRecord>> getYieldHistory({
    int? fieldId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final maps = await _dbHelper.getYieldRecords(
      fieldId: fieldId,
      startDate: startDate,
      endDate: endDate,
    );
    return maps.map((map) => YieldRecord.fromMap(map)).toList();
  }

  /// Get aggregated yield trends (grouped by year)
  Future<List<Map<String, dynamic>>> getYieldTrends({
    int? fieldId,
    String? cropName,
    int years = 5,
  }) async {
    return await _dbHelper.getYieldAggregates(
      fieldId: fieldId,
      cropName: cropName,
      years: years,
    );
  }

  /// Get seasonal comparison for a specific crop on a field
  Future<List<Map<String, dynamic>>> getSeasonalComparison({
    required int fieldId,
    required String cropName,
  }) async {
    // 1. Get Field Area
    final fields = await getFields();
    final field = fields.firstWhere((f) => f.id == fieldId);
    final area = field.area; // in acres

    // 2. Get Yield Records for this field and crop
    final allRecords = await getYieldHistory(fieldId: fieldId);
    final cropRecords = allRecords.where((r) => r.cropName.toLowerCase() == cropName.toLowerCase()).toList();

    // 3. Get Crop Rotations to map dates to seasons
    final rotations = await getCropRotations(fieldId);

    // 4. Group by Season/Year
    final Map<String, double> yieldBySeason = {};

    for (var record in cropRecords) {
      // Find matching rotation for season info
      // Simple logic: match year and crop name
      // In a real app, we might check date ranges more strictly
      String season = 'Unknown';
      String year = record.harvestDate.year.toString();

      try {
        final rotation = rotations.firstWhere(
          (r) => r.year == record.harvestDate.year && r.cropName.toLowerCase() == cropName.toLowerCase(),
        );
        season = rotation.season;
      } catch (e) {
        // Fallback: Estimate season based on month
        final month = record.harvestDate.month;
        if (month >= 6 && month <= 10) season = 'Kharif';
        else if (month >= 11 || month <= 3) season = 'Rabi';
        else season = 'Zaid';
      }

      final key = '$season $year';
      yieldBySeason[key] = (yieldBySeason[key] ?? 0) + record.yieldAmount;
    }

    // 5. Calculate Metrics
    final List<Map<String, dynamic>> result = [];
    yieldBySeason.forEach((key, totalYield) {
      result.add({
        'season_year': key,
        'total_yield': totalYield,
        'yield_per_acre': area > 0 ? totalYield / area : 0,
      });
    });

    // Sort by year (extracted from key)
    result.sort((a, b) {
      final yearA = int.tryParse(a['season_year'].split(' ').last) ?? 0;
      final yearB = int.tryParse(b['season_year'].split(' ').last) ?? 0;
      return yearA.compareTo(yearB);
    });

    return result;
  }

  /// Get ROI metrics for a field
  Future<Map<String, double>> getROIData(int fieldId) async {
    return await _dbHelper.getROIMetrics(fieldId);
  }

  // ================== SOIL DATA OPERATIONS ==================

  /// Add soil data
  Future<int> addSoilData(SoilData data) async {
    return await _dbHelper.insertSoilData(data.toMap());
  }

  /// Get soil data history for a field
  Future<List<SoilData>> getSoilDataHistory(int fieldId) async {
    final maps = await _dbHelper.getSoilData(fieldId);
    return maps.map((map) => SoilData.fromMap(map)).toList();
  }

  // ================== BULK OPERATIONS ==================

  /// Update multiple fields at once
  Future<void> updateFieldsBulk({
    required List<int> fieldIds,
    String? cropType,
    // Add other updateable fields here
  }) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var id in fieldIds) {
      final Map<String, dynamic> updates = {};
      if (cropType != null) updates['crop_type'] = cropType;

      if (updates.isNotEmpty) {
        batch.update(
          'fields',
          updates,
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

    await batch.commit(noResult: true);
  }
}
