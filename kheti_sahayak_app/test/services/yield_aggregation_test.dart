import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/models/yield_record.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    // Reset DB for testing (in-memory would be ideal, but using file-based for now)
    // For this test, we'll just insert unique data and verify it
  });

  test('Yield Record Insertion and Retrieval', () async {
    // 1. Insert a field (required for FK)
    final fieldId = await dbHelper.insertField({
      'name': 'Test Field Yield',
      'area': 2.5,
      'crop_type': 'Wheat',
      'location': 'Test Loc',
    });

    // 2. Insert Yield Records
    final record1 = YieldRecord(
      fieldId: fieldId,
      cropName: 'Wheat',
      harvestDate: DateTime(2023, 4, 15),
      yieldAmount: 5000.0,
      unit: 'kg',
    );
    
    final record2 = YieldRecord(
      fieldId: fieldId,
      cropName: 'Wheat',
      harvestDate: DateTime(2022, 4, 15),
      yieldAmount: 4800.0,
      unit: 'kg',
    );

    await dbHelper.insertYieldRecord(record1.toMap());
    await dbHelper.insertYieldRecord(record2.toMap());

    // 3. Verify Retrieval
    final records = await dbHelper.getYieldRecords(fieldId: fieldId);
    expect(records.length, greaterThanOrEqualTo(2));
    expect(records.first['crop_name'], 'Wheat');
  });

  test('Yield Aggregation Logic', () async {
    // 1. Insert a field
    final fieldId = await dbHelper.insertField({
      'name': 'Agg Field',
      'area': 1.0,
      'crop_type': 'Rice',
      'location': 'Loc',
    });

    // 2. Insert Records for multiple years
    await dbHelper.insertYieldRecord({
      'field_id': fieldId,
      'crop_name': 'Rice',
      'harvest_date': '2023-11-01',
      'yield_amount': 3000.0,
      'unit': 'kg',
    });
    
    await dbHelper.insertYieldRecord({
      'field_id': fieldId,
      'crop_name': 'Rice',
      'harvest_date': '2023-11-02', // Same year, different day
      'yield_amount': 1000.0,
      'unit': 'kg',
    });

    await dbHelper.insertYieldRecord({
      'field_id': fieldId,
      'crop_name': 'Rice',
      'harvest_date': '2022-11-01',
      'yield_amount': 3800.0,
      'unit': 'kg',
    });

    // 3. Verify Aggregation
    final aggregates = await dbHelper.getYieldAggregates(fieldId: fieldId);
    
    // Should have 2 entries (2023 and 2022)
    // 2023: 3000 + 1000 = 4000
    // 2022: 3800
    
    final agg2023 = aggregates.firstWhere((a) => a['year'] == '2023');
    expect(agg2023['total_yield'], 4000.0);
    
    final agg2022 = aggregates.firstWhere((a) => a['year'] == '2022');
    expect(agg2022['total_yield'], 3800.0);
  });
}
