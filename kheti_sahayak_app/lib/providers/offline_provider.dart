import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kheti_sahayak_app/services/connectivity_service.dart';
import 'package:kheti_sahayak_app/services/sync_queue_service.dart';
import 'package:kheti_sahayak_app/services/offline_cache_service.dart';
import 'package:kheti_sahayak_app/services/sync_service.dart';

/// Sync state for the app
enum SyncState {
  idle,
  syncing,
  success,
  error,
}

/// Provider for managing offline state and sync operations
class OfflineProvider extends ChangeNotifier {
  // ================== STATE ==================
  
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;
  SyncState _syncState = SyncState.idle;
  String? _lastSyncError;
  DateTime? _lastSyncTime;
  SyncProgress? _currentProgress;
  ConnectivityStatus? _connectivityStatus;
  
  // ================== SUBSCRIPTIONS ==================
  
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncProgress>? _syncProgressSubscription;
  
  // ================== GETTERS ==================
  
  /// Whether the device is online
  bool get isOnline => _isOnline;
  
  /// Whether the device is offline
  bool get isOffline => !_isOnline;
  
  /// Number of pending sync operations
  int get pendingSyncCount => _pendingSyncCount;
  
  /// Whether there are pending operations
  bool get hasPendingSync => _pendingSyncCount > 0;
  
  /// Whether sync is in progress
  bool get isSyncing => _isSyncing;
  
  /// Current sync state
  SyncState get syncState => _syncState;
  
  /// Last sync error message
  String? get lastSyncError => _lastSyncError;
  
  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Current sync progress
  SyncProgress? get currentProgress => _currentProgress;
  
  /// Detailed connectivity status
  ConnectivityStatus? get connectivityStatus => _connectivityStatus;
  
  /// Network type display name
  String get networkTypeName {
    if (_connectivityStatus == null) return 'Unknown';
    return ConnectivityService.getNetworkTypeName(_connectivityStatus!.networkType);
  }
  
  /// Status message for display
  String get statusMessage {
    if (_isSyncing) {
      if (_currentProgress != null) {
        return _currentProgress!.statusMessage;
      }
      return 'Syncing...';
    }
    
    if (!_isOnline) {
      return 'You are offline. Changes will sync when connected.';
    }
    
    if (_pendingSyncCount > 0) {
      return '$_pendingSyncCount pending changes';
    }
    
    if (_lastSyncTime != null) {
      final duration = DateTime.now().difference(_lastSyncTime!);
      if (duration.inMinutes < 1) {
        return 'Synced just now';
      } else if (duration.inHours < 1) {
        return 'Synced ${duration.inMinutes}m ago';
      } else if (duration.inDays < 1) {
        return 'Synced ${duration.inHours}h ago';
      } else {
        return 'Synced ${duration.inDays}d ago';
      }
    }
    
    return 'Online';
  }
  
  // ================== INITIALIZATION ==================
  
  /// Initialize the provider
  Future<void> initialize() async {
    // Initialize connectivity service
    await ConnectivityService.initialize();
    
    // Get initial state
    await checkConnectivity();
    await refreshPendingCount();
    
    // Subscribe to connectivity changes
    _connectivitySubscription = ConnectivityService.onConnectivityChanged.listen((isOnline) {
      _handleConnectivityChange(isOnline);
    });
    
    // Subscribe to detailed status changes
    ConnectivityService.onStatusChanged.listen((status) {
      _connectivityStatus = status;
      notifyListeners();
    });
    
    // Subscribe to sync progress
    _syncProgressSubscription = SyncQueueService.instance.onSyncProgress.listen((progress) {
      _currentProgress = progress;
      notifyListeners();
    });
    
    // Start auto-sync
    SyncQueueService.instance.startAutoSync();
  }
  
  /// Handle connectivity change
  void _handleConnectivityChange(bool isOnline) async {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;
    notifyListeners();
    
    // If we just came online and have pending operations, sync
    if (isOnline && wasOffline && _pendingSyncCount > 0) {
      await syncNow();
    }
  }
  
  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncProgressSubscription?.cancel();
    SyncQueueService.instance.stopAutoSync();
    ConnectivityService.dispose();
    super.dispose();
  }
  
  // ================== CONNECTIVITY ==================
  
  /// Check current connectivity
  Future<void> checkConnectivity() async {
    final status = await ConnectivityService.checkConnectivity();
    _isOnline = status.isOnline;
    _connectivityStatus = status;
    notifyListeners();
  }
  
  // ================== SYNC OPERATIONS ==================
  
  /// Refresh pending sync count
  Future<void> refreshPendingCount() async {
    _pendingSyncCount = await SyncQueueService.getPendingCount();
    
    // Also count pending diagnostics from legacy sync service
    final legacyCount = await SyncService.instance.getPendingUploadsCount();
    _pendingSyncCount += legacyCount;
    
    notifyListeners();
  }
  
  /// Trigger sync now
  Future<bool> syncNow() async {
    if (_isSyncing) return false;
    if (!_isOnline) {
      _lastSyncError = 'Cannot sync while offline';
      notifyListeners();
      return false;
    }
    
    _isSyncing = true;
    _syncState = SyncState.syncing;
    _lastSyncError = null;
    notifyListeners();
    
    try {
      // Process new sync queue
      final queueResult = await SyncQueueService.processQueue();
      
      // Also process legacy sync (diagnostics, tasks, etc.)
      final diagnosticsResult = await SyncService.instance.syncPendingDiagnostics();
      final activityResult = await SyncService.instance.syncLogbookBidirectional();
      
      // Clear expired caches
      await OfflineCacheService.clearExpiredCache();
      
      // Update state
      final allSucceeded = queueResult.isSuccess && 
                          diagnosticsResult.success && 
                          activityResult.success;
      
      _syncState = allSucceeded ? SyncState.success : SyncState.error;
      _lastSyncTime = DateTime.now();
      
      if (!allSucceeded) {
        final errors = <String>[];
        if (queueResult.errors.isNotEmpty) {
          errors.addAll(queueResult.errors);
        }
        if (!diagnosticsResult.success && diagnosticsResult.errors.isNotEmpty) {
          errors.addAll(diagnosticsResult.errors);
        }
        if (!activityResult.success && activityResult.errors.isNotEmpty) {
          errors.addAll(activityResult.errors);
        }
        _lastSyncError = errors.isNotEmpty ? errors.first : 'Some items failed to sync';
      }
      
      await refreshPendingCount();
      
      _isSyncing = false;
      _currentProgress = null;
      notifyListeners();
      
      return allSucceeded;
    } catch (e) {
      _isSyncing = false;
      _syncState = SyncState.error;
      _lastSyncError = e.toString();
      _currentProgress = null;
      notifyListeners();
      return false;
    }
  }
  
  /// Retry failed sync operations
  Future<void> retryFailed() async {
    await SyncQueueService.retryFailed();
    await refreshPendingCount();
    
    if (_isOnline && _pendingSyncCount > 0) {
      await syncNow();
    }
  }
  
  /// Cancel current sync (if possible)
  void cancelSync() {
    // Note: Current implementation doesn't support cancellation
    // This is a placeholder for future enhancement
  }
  
  // ================== CACHE MANAGEMENT ==================
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await OfflineCacheService.getCacheStats();
  }
  
  /// Clear all caches
  Future<void> clearCaches() async {
    await OfflineCacheService.clearAllCache();
    notifyListeners();
  }
  
  /// Clear expired caches only
  Future<void> clearExpiredCaches() async {
    await OfflineCacheService.clearExpiredCache();
  }
  
  /// Check if cache is within size limits
  Future<bool> isCacheWithinLimits() async {
    return await OfflineCacheService.isCacheWithinLimits();
  }
  
  /// Get cache size in bytes
  Future<int> getCacheSizeBytes() async {
    return await OfflineCacheService.getCacheSizeBytes();
  }
  
  /// Get cache size formatted for display
  Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSizeBytes();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  // ================== OFFLINE ACTIONS ==================
  
  /// Queue an action for when online
  Future<void> queueAction({
    required String tableName,
    required String operation,
    required Map<String, dynamic> data,
    String? entityId,
    int priority = 1,
  }) async {
    await SyncQueueService.enqueue(SyncOperation(
      tableName: tableName,
      operation: _parseOperation(operation),
      entityId: entityId,
      data: data,
      priority: priority,
    ));
    
    await refreshPendingCount();
    
    // If online, sync immediately
    if (_isOnline) {
      await syncNow();
    }
  }
  
  SyncOperationType _parseOperation(String operation) {
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
  
  // ================== STATUS HELPERS ==================
  
  /// Check if essential data is cached for offline use
  Future<Map<String, bool>> checkOfflineReadiness({
    String? userId,
    double? latitude,
    double? longitude,
  }) async {
    return await OfflineCacheService.checkEssentialDataCached(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
    );
  }
  
  /// Get offline readiness percentage
  Future<double> getOfflineReadinessPercentage({
    String? userId,
    double? latitude,
    double? longitude,
  }) async {
    final status = await checkOfflineReadiness(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
    );
    
    final total = status.length;
    final ready = status.values.where((v) => v).length;
    
    return total > 0 ? ready / total : 0.0;
  }
}
