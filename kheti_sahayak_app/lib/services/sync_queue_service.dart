import 'dart:async';
import 'dart:convert';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/services/connectivity_service.dart';

/// Sync operation types
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Sync operation status
enum SyncOperationStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Represents a sync operation in the queue
class SyncOperation {
  final int? id;
  final String tableName;
  final SyncOperationType operation;
  final String? entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  int maxRetries;
  SyncOperationStatus status;
  DateTime? lastAttempt;
  String? errorMessage;
  int priority;

  SyncOperation({
    this.id,
    required this.tableName,
    required this.operation,
    this.entityId,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.status = SyncOperationStatus.pending,
    this.lastAttempt,
    this.errorMessage,
    this.priority = 1,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as int?,
      tableName: map['table_name'] as String,
      operation: _parseOperation(map['operation'] as String),
      entityId: map['entity_id'] as String?,
      data: map['data'] is String 
          ? jsonDecode(map['data'] as String) as Map<String, dynamic>
          : map['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      maxRetries: map['max_retries'] as int? ?? 3,
      status: _parseStatus(map['status'] as String?),
      lastAttempt: map['last_attempt'] != null 
          ? DateTime.parse(map['last_attempt'] as String) 
          : null,
      errorMessage: map['error_message'] as String?,
      priority: map['priority'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'table_name': tableName,
      'operation': operation.name,
      'entity_id': entityId,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'status': status.name,
      'last_attempt': lastAttempt?.toIso8601String(),
      'error_message': errorMessage,
      'priority': priority,
    };
  }

  static SyncOperationType _parseOperation(String operation) {
    switch (operation.toLowerCase()) {
      case 'create':
        return SyncOperationType.create;
      case 'update':
        return SyncOperationType.update;
      case 'delete':
        return SyncOperationType.delete;
      default:
        return SyncOperationType.create;
    }
  }

  static SyncOperationStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return SyncOperationStatus.pending;
      case 'processing':
        return SyncOperationStatus.processing;
      case 'completed':
        return SyncOperationStatus.completed;
      case 'failed':
        return SyncOperationStatus.failed;
      default:
        return SyncOperationStatus.pending;
    }
  }

  bool get canRetry => retryCount < maxRetries && status == SyncOperationStatus.failed;
  
  bool get isExpired => DateTime.now().difference(createdAt).inDays > 7;

  @override
  String toString() {
    return 'SyncOperation(id: $id, table: $tableName, operation: ${operation.name}, status: ${status.name}, retries: $retryCount/$maxRetries)';
  }
}

/// Result of processing sync queue
class SyncQueueResult {
  final int processed;
  final int succeeded;
  final int failed;
  final int skipped;
  final List<String> errors;
  final Duration duration;

  SyncQueueResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.skipped,
    required this.errors,
    required this.duration,
  });

  bool get isSuccess => failed == 0;
  bool get hasPartialSuccess => succeeded > 0 && failed > 0;

  @override
  String toString() {
    return 'SyncQueueResult(processed: $processed, succeeded: $succeeded, failed: $failed, skipped: $skipped, duration: ${duration.inMilliseconds}ms)';
  }
}

/// Service for managing offline sync queue
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  static SyncQueueService get instance => _instance;
  
  factory SyncQueueService() => _instance;
  
  SyncQueueService._internal();
  
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  bool _isProcessing = false;
  Timer? _autoSyncTimer;
  
  /// Stream controller for sync progress updates
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get onSyncProgress => _syncProgressController.stream;
  
  // ================== ENQUEUE OPERATIONS ==================
  
  /// Add an operation to the sync queue
  static Future<int> enqueue(SyncOperation operation) async {
    return await DatabaseHelper.instance.enqueueSyncOperation(
      tableName: operation.tableName,
      operation: operation.operation.name,
      entityId: operation.entityId,
      data: operation.data,
      priority: operation.priority,
      maxRetries: operation.maxRetries,
    );
  }
  
  /// Enqueue a create operation
  static Future<int> enqueueCreate({
    required String tableName,
    required Map<String, dynamic> data,
    String? entityId,
    int priority = 1,
  }) async {
    return await enqueue(SyncOperation(
      tableName: tableName,
      operation: SyncOperationType.create,
      entityId: entityId,
      data: data,
      priority: priority,
    ));
  }
  
  /// Enqueue an update operation
  static Future<int> enqueueUpdate({
    required String tableName,
    required String entityId,
    required Map<String, dynamic> data,
    int priority = 1,
  }) async {
    return await enqueue(SyncOperation(
      tableName: tableName,
      operation: SyncOperationType.update,
      entityId: entityId,
      data: data,
      priority: priority,
    ));
  }
  
  /// Enqueue a delete operation
  static Future<int> enqueueDelete({
    required String tableName,
    required String entityId,
    int priority = 2,
  }) async {
    return await enqueue(SyncOperation(
      tableName: tableName,
      operation: SyncOperationType.delete,
      entityId: entityId,
      data: {},
      priority: priority,
    ));
  }
  
  // ================== QUEUE PROCESSING ==================
  
  /// Process the sync queue
  static Future<SyncQueueResult> processQueue({int? batchSize}) async {
    return await SyncQueueService.instance._processQueueInternal(batchSize: batchSize);
  }
  
  Future<SyncQueueResult> _processQueueInternal({int? batchSize}) async {
    if (_isProcessing) {
      return SyncQueueResult(
        processed: 0,
        succeeded: 0,
        failed: 0,
        skipped: 0,
        errors: ['Sync already in progress'],
        duration: Duration.zero,
      );
    }
    
    // Check connectivity
    final isOnline = await ConnectivityService.isOnline;
    if (!isOnline) {
      return SyncQueueResult(
        processed: 0,
        succeeded: 0,
        failed: 0,
        skipped: 0,
        errors: ['No internet connection'],
        duration: Duration.zero,
      );
    }
    
    _isProcessing = true;
    final startTime = DateTime.now();
    
    int processed = 0;
    int succeeded = 0;
    int failed = 0;
    int skipped = 0;
    final errors = <String>[];
    
    try {
      // Get pending operations
      final pendingOps = await _dbHelper.getPendingSyncOperations(limit: batchSize ?? 50);
      final totalOps = pendingOps.length;
      
      if (totalOps == 0) {
        _isProcessing = false;
        return SyncQueueResult(
          processed: 0,
          succeeded: 0,
          failed: 0,
          skipped: 0,
          errors: [],
          duration: DateTime.now().difference(startTime),
        );
      }
      
      // Emit progress start
      _syncProgressController.add(SyncProgress(
        current: 0,
        total: totalOps,
        status: SyncProgressStatus.started,
      ));
      
      for (final opMap in pendingOps) {
        final operation = SyncOperation.fromMap(opMap);
        processed++;
        
        // Skip expired operations
        if (operation.isExpired) {
          await _dbHelper.completeSyncOperation(operation.id!);
          skipped++;
          continue;
        }
        
        // Emit progress update
        _syncProgressController.add(SyncProgress(
          current: processed,
          total: totalOps,
          status: SyncProgressStatus.processing,
          currentOperation: operation,
        ));
        
        try {
          // Process the operation
          final success = await _processSingleOperation(operation);
          
          if (success) {
            await _dbHelper.completeSyncOperation(operation.id!);
            succeeded++;
          } else {
            await _dbHelper.failSyncOperation(operation.id!, 'Operation returned false');
            failed++;
            errors.add('${operation.tableName}: Operation failed');
          }
        } catch (e) {
          await _dbHelper.failSyncOperation(operation.id!, e.toString());
          failed++;
          errors.add('${operation.tableName}: ${e.toString()}');
        }
      }
      
      // Emit completion
      _syncProgressController.add(SyncProgress(
        current: processed,
        total: totalOps,
        status: SyncProgressStatus.completed,
        succeeded: succeeded,
        failed: failed,
      ));
      
    } catch (e) {
      errors.add('Queue processing error: ${e.toString()}');
      
      _syncProgressController.add(SyncProgress(
        current: processed,
        total: 0,
        status: SyncProgressStatus.error,
        error: e.toString(),
      ));
    } finally {
      _isProcessing = false;
    }
    
    return SyncQueueResult(
      processed: processed,
      succeeded: succeeded,
      failed: failed,
      skipped: skipped,
      errors: errors,
      duration: DateTime.now().difference(startTime),
    );
  }
  
  /// Process a single sync operation
  Future<bool> _processSingleOperation(SyncOperation operation) async {
    // Map table names to API endpoints
    final endpoint = _getEndpointForTable(operation.tableName);
    
    switch (operation.operation) {
      case SyncOperationType.create:
        final response = await ApiService.post(endpoint, operation.data);
        return response != null && response['success'] == true;
        
      case SyncOperationType.update:
        if (operation.entityId == null) return false;
        final response = await ApiService.put('$endpoint/${operation.entityId}', operation.data);
        return response != null && response['success'] == true;
        
      case SyncOperationType.delete:
        if (operation.entityId == null) return false;
        final response = await ApiService.delete('$endpoint/${operation.entityId}');
        return response != null && response['success'] == true;
    }
  }
  
  /// Get API endpoint for a table name
  String _getEndpointForTable(String tableName) {
    switch (tableName) {
      case 'diagnostics':
      case 'offline_diagnostics':
        return '/diagnostics';
      case 'activity_records':
        return '/logbook/activities';
      case 'products':
        return '/marketplace/products';
      case 'orders':
        return '/marketplace/orders';
      case 'cart':
      case 'cart_items':
        return '/marketplace/cart';
      case 'community_posts':
        return '/community/posts';
      case 'user_profile':
        return '/auth/profile';
      default:
        return '/$tableName';
    }
  }
  
  // ================== QUEUE MANAGEMENT ==================
  
  /// Get pending operations count
  static Future<int> getPendingCount() async {
    return await DatabaseHelper.instance.getPendingSyncCount();
  }
  
  /// Get all pending operations
  static Future<List<SyncOperation>> getPendingOperations({int? limit}) async {
    final results = await DatabaseHelper.instance.getPendingSyncOperations(limit: limit);
    return results.map((map) => SyncOperation.fromMap(map)).toList();
  }
  
  /// Retry failed operations
  static Future<int> retryFailed() async {
    return await DatabaseHelper.instance.resetFailedSyncOperations();
  }
  
  /// Clear completed operations
  static Future<int> clearCompleted() async {
    return await DatabaseHelper.instance.clearCompletedSyncOperations();
  }
  
  /// Clear all operations
  static Future<int> clearAll() async {
    return await DatabaseHelper.instance.clearAllSyncOperations();
  }
  
  // ================== AUTO SYNC ==================
  
  /// Start auto-sync timer (default: every 30 minutes)
  void startAutoSync({Duration interval = const Duration(minutes: 30)}) {
    stopAutoSync();
    
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      if (await ConnectivityService.isOnline) {
        await processQueue();
      }
    });
    
    // Also listen for connectivity changes
    ConnectivityService.onConnectivityChanged.listen((online) async {
      if (online) {
        final pendingCount = await getPendingCount();
        if (pendingCount > 0) {
          await processQueue();
        }
      }
    });
  }
  
  /// Stop auto-sync timer
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }
  
  /// Check if auto-sync is running
  bool get isAutoSyncRunning => _autoSyncTimer != null && _autoSyncTimer!.isActive;
  
  /// Check if queue is currently processing
  bool get isProcessing => _isProcessing;
  
  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _syncProgressController.close();
  }
}

/// Sync progress status
enum SyncProgressStatus {
  started,
  processing,
  completed,
  error,
}

/// Sync progress information
class SyncProgress {
  final int current;
  final int total;
  final SyncProgressStatus status;
  final SyncOperation? currentOperation;
  final int? succeeded;
  final int? failed;
  final String? error;

  SyncProgress({
    required this.current,
    required this.total,
    required this.status,
    this.currentOperation,
    this.succeeded,
    this.failed,
    this.error,
  });

  double get progress => total > 0 ? current / total : 0;
  
  String get statusMessage {
    switch (status) {
      case SyncProgressStatus.started:
        return 'Starting sync...';
      case SyncProgressStatus.processing:
        return 'Syncing $current of $total...';
      case SyncProgressStatus.completed:
        return 'Sync completed: $succeeded succeeded, $failed failed';
      case SyncProgressStatus.error:
        return 'Sync error: $error';
    }
  }
}
