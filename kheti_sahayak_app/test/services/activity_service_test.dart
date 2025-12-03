import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/services/activity_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for desktop testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ActivityService Logic', () {
    test('should format timezone offset correctly', () {
      // Logic verification for the timezone formatting used in ActivityService
      
      String formatOffset(Duration offset) {
        final hours = offset.inHours.abs().toString().padLeft(2, '0');
        final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
        final sign = offset.isNegative ? '-' : '+';
        return '$sign$hours:$minutes';
      }

      expect(formatOffset(Duration(hours: 5, minutes: 30)), '+05:30');
      expect(formatOffset(Duration(hours: -5)), '-05:00');
      expect(formatOffset(Duration(hours: 0)), '+00:00');
      expect(formatOffset(Duration(hours: 5, minutes: 45)), '+05:45');
    });
  });

  group('Activity Record Sync', () {
    late ActivityService activityService;
    late DatabaseHelper dbHelper;

    setUp(() async {
      activityService = ActivityService();
      dbHelper = DatabaseHelper.instance;
    });

    test('should create activity record with synced=0 by default', () async {
      // Create an activity record
      final id = await activityService.createActivityRecord(
        activityType: 'Planting',
        fieldId: 1,
        cost: 500.0,
      );

      expect(id, greaterThan(0));

      // Verify it's marked as unsynced
      final unsyncedRecords = await dbHelper.getUnsyncedActivityRecords();
      expect(unsyncedRecords.any((r) => r['id'] == id), true);
    });

    test('should mark activity record as synced', () async {
      // Create an activity record
      final id = await activityService.createActivityRecord(
        activityType: 'Irrigation',
        fieldId: 1,
        cost: 200.0,
      );

      // Get unsynced count before
      final unsyncedBefore = await dbHelper.getUnsyncedActivityRecords();
      final countBefore = unsyncedBefore.where((r) => r['id'] == id).length;

      // Mark as synced
      await dbHelper.markActivityRecordSynced(id);

      // Get unsynced count after
      final unsyncedAfter = await dbHelper.getUnsyncedActivityRecords();
      final countAfter = unsyncedAfter.where((r) => r['id'] == id).length;

      // Verify it's no longer in unsynced list
      expect(countBefore, 1);
      expect(countAfter, 0);
    });

    test('should handle activity record with metadata', () async {
      // Create activity record with metadata
      final id = await activityService.createActivityRecord(
        activityType: 'Spraying',
        fieldId: 1,
        cost: 400.0,
        metadata: {
          'description': 'Applied pesticide for aphid control',
          'notes': 'Weather was clear',
        },
      );

      expect(id, greaterThan(0));

      // Retrieve and verify metadata
      final records = await activityService.getActivityRecords(limit: 10);
      final createdRecord = records.firstWhere((r) => r.id == id);
      expect(createdRecord.metadata['description'], contains('pesticide'));
    });
  });

  group('SyncService Integration', () {
    test('should handle sync when offline', () async {
      final syncService = SyncService.instance;
      
      // Note: This test assumes we're offline or the API is unavailable
      // In a real scenario, you'd mock the network connectivity
      
      final result = await syncService.syncPendingActivityRecords();
      
      // Should fail gracefully when offline
      expect(result, isNotNull);
      expect(result.message, isNotNull);
    });
  });
}
