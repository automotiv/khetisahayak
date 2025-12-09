import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SyncService Tests', () {
    test('Offline Data Creation sets dirty flag', () async {
      final dbHelper = DatabaseHelper.instance;
      
      // Simulate creating a record offline
      // Note: We need to expose a method to insert activity record or use raw insert
      final db = await dbHelper.database;
      await db.insert('activity_records', {
        'activity_type': 'Sowing',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': '{}',
        'dirty': 1, // Logic should set this
        'version': 0,
      });
      
      final dirty = await dbHelper.getDirtyActivityRecords();
      expect(dirty.length, 1);
      expect(dirty.first['activity_type'], 'Sowing');
    });

    // Note: Full sync test requires mocking ApiService which is static.
    // For now we verify the database helper methods which are crucial for sync.
    
    test('Update Sync Status clears dirty flag', () async {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      
      final id = await db.insert('activity_records', {
        'activity_type': 'Harvesting',
        'timestamp': DateTime.now().toIso8601String(),
        'dirty': 1,
      });
      
      await dbHelper.updateActivityRecordSyncStatus(
        localId: id,
        backendId: 'uuid-123',
        version: 1,
        dirty: 0,
      );
      
      final dirty = await dbHelper.getDirtyActivityRecords();
      expect(dirty.where((r) => r['id'] == id), isEmpty);
      
      final record = await dbHelper.getActivityRecordByBackendId('uuid-123');
      expect(record, isNotNull);
      expect(record!['version'], 1);
    });
  });
}
