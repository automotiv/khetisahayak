import '../models/sync_queue_item.dart';
import 'local_database_service.dart';

class SyncManagerService {
  final LocalDatabaseService _db = LocalDatabaseService();

  // Add an action to the local queue
  Future<void> addToQueue(String entityType, String action, Map<String, dynamic> payload) async {
    final item = SyncQueueItem(
      entityType: entityType,
      action: action,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _db.insert('sync_queue', item.toMap());
  }

  // Retrieve pending items
  Future<List<SyncQueueItem>> getPendingItems() async {
    final result = await _db.query('sync_queue'); // Get all
    return result.map((e) => SyncQueueItem.fromMap(e)).toList();
  }

  // Simulate processing the queue
  Future<void> processQueue() async {
    final pending = await getPendingItems();
    if (pending.isEmpty) return;

    print('SyncManager: Processing ${pending.length} items...');

    for (var item in pending) {
      try {
        await _performNetworkRequest(item);
        // If successful, remove from queue
        await _db.delete('sync_queue', 'id = ?', [item.id]);
        print('SyncManager: Item ${item.id} synced successfully.');
      } catch (e) {
        print('SyncManager: Failed to sync item ${item.id}. Error: $e');
        // Increase retry count (logic update skipped for brevity)
      }
    }
  }

  // Mock network request
  Future<void> _performNetworkRequest(SyncQueueItem item) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    // Simulate random failure
    // if (DateTime.now().millisecond % 10 == 0) throw Exception('API Error');
    print('Network: ${item.action.toUpperCase()} ${item.entityType} sent.');
  }

  // Mock sync down (Fetching latest data)
  Future<void> syncDown() async {
    print('SyncManager: Fetching latest data from server...');
    await Future.delayed(Duration(seconds: 1));
    print('SyncManager: Local cache updated.');
  }
}
