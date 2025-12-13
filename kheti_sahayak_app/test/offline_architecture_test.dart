import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kheti_sahayak_app/services/local_database_service.dart';
import 'package:kheti_sahayak_app/services/sync_manager_service.dart';
import 'package:kheti_sahayak_app/models/sync_queue_item.dart';

// Note: Test requires sqflite_common_ffi and environment setup for DB mocking
void main() {
  setUpAll(() {
    // Initialize FFI for SQLite testing (required for desktop/unit tests)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Architecture Tests', () {
    final syncManager = SyncManagerService();

    test('Queue Insertion Persistence', () async {
      // 1. Add item to queue
      final payload = {'name': 'Test Farm', 'area': 5.0};
      await syncManager.addToQueue('farm', 'create', payload);

      // 2. Fetch directly from DB (simulated via manager getter)
      final items = await syncManager.getPendingItems();

      // 3. Verify
      expect(items.length, greaterThanOrEqualTo(1));
      final item = items.last;
      expect(item.entityType, 'farm');
      expect(item.action, 'create');
      expect(item.payload['name'], 'Test Farm');
    });

    // Note: processQueue test involves network mocking which is more complex
    // and skipped for this basic architecture verification.
  });
}
