import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/activity_record.dart';
import 'package:kheti_sahayak_app/models/yield_record.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    // Reset DB (in memory for tests usually, but here we use the actual helper which uses a file. 
    // For unit tests, we should ideally mock or use in-memory. 
    // Since DatabaseHelper is a singleton using a specific file, we might need to be careful.
    // However, for this verification, I'll assume we can use a temporary database path if possible, 
    // but DatabaseHelper hardcodes 'kheti_sahayak.db'.
    // I will just test the logic flow if I can't easily swap the DB.
    // Actually, I can't easily swap the DB path in the singleton without modifying it.
    // So I will write a test that inserts data, checks ROI, and then cleans up.
  });

  test('ROI Calculation Logic', () async {
    // 1. Create a dummy field (we need a field ID)
    final fieldId = await dbHelper.insertField({
      'name': 'Test Field ROI',
      'area': 10.0,
      'crop_type': 'Wheat',
      'location': 'Test Loc'
    });

    // 2. Add Activities (Cost)
    await dbHelper.insertActivityRecord(ActivityRecord(
      fieldId: fieldId,
      activityType: 'Sowing',
      timestamp: DateTime.now(),
      timezoneOffset: '',
      cost: 5000.0,
    ).toMap());

    await dbHelper.insertActivityRecord(ActivityRecord(
      fieldId: fieldId,
      activityType: 'Fertilizer',
      timestamp: DateTime.now(),
      timezoneOffset: '',
      cost: 3000.0,
    ).toMap());

    // Total Cost = 8000

    // 3. Add Yields (Return)
    await dbHelper.insertYieldRecord(YieldRecord(
      fieldId: fieldId,
      cropName: 'Wheat',
      harvestDate: DateTime.now(),
      yieldAmount: 10.0, // 10 Quintals
      unit: 'Quintal',
      marketPrice: 2000.0, // 2000 per Quintal
    ).toMap());

    // Total Return = 10 * 2000 = 20000

    // 4. Calculate ROI
    final metrics = await dbHelper.getROIMetrics(fieldId);

    expect(metrics['total_investment'], 8000.0);
    expect(metrics['total_return'], 20000.0);
    expect(metrics['net_profit'], 12000.0);
    expect(metrics['roi_percentage'], 150.0); // (12000 / 8000) * 100

    // Cleanup
    // We don't have a deleteField method exposed easily that cascades, but for now this is fine.
  });
}
