import 'package:flutter_test/flutter_test.dart';

class SyncResult {
  final bool success;
  final String message;
  final int itemsSynced;
  final int itemsFailed;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.itemsSynced,
    this.itemsFailed = 0,
    this.errors = const [],
  });
}

void main() {
  group('SyncService Logic', () {
    test('should return correct SyncResult structure', () {
      final result = SyncResult(
        success: true,
        message: 'Synced 5 items',
        itemsSynced: 5,
      );

      expect(result.success, true);
      expect(result.message, 'Synced 5 items');
      expect(result.itemsSynced, 5);
      expect(result.itemsFailed, 0);
      expect(result.errors, isEmpty);
    });

    test('should handle failure result', () {
      final result = SyncResult(
        success: false,
        message: 'Sync failed',
        itemsSynced: 2,
        itemsFailed: 1,
        errors: ['Network error'],
      );

      expect(result.success, false);
      expect(result.itemsSynced, 2);
      expect(result.itemsFailed, 1);
      expect(result.errors.first, 'Network error');
    });
  });
}
