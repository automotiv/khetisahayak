import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _failedAttempts = 0;

  SyncService._init();

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Check if we have any connectivity
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Additionally, try to ping a reliable server to confirm internet access
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Listen to connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Get pending uploads count
  Future<int> getPendingUploadsCount() async {
    return await _dbHelper.getPendingCount();
  }

  /// Sync pending diagnostics
  Future<SyncResult> syncPendingDiagnostics({bool force = false}) async {
    // Check if already syncing
    if (_isSyncing && !force) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        itemsSynced: 0,
      );
    }

    // Check if online
    final online = await isOnline();
    if (!online) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        itemsSynced: 0,
      );
    }

    _isSyncing = true;
    final syncLogId = await _dbHelper.startSyncLog('pending_diagnostics');

    int successCount = 0;
    int failureCount = 0;
    final List<String> errors = [];

    try {
      // Get all pending diagnostics
      final pending = await _dbHelper.getPendingDiagnostics();

      if (pending.isEmpty) {
        _isSyncing = false;
        await _dbHelper.completeSyncLog(
          id: syncLogId,
          status: 'completed',
          itemsSynced: 0,
        );
        return SyncResult(
          success: true,
          message: 'No pending items to sync',
          itemsSynced: 0,
        );
      }

      // Upload each pending diagnostic
      for (final item in pending) {
        try {
          final localId = item['id'] as int;
          final imagePath = item['local_image_path'] as String;
          final cropType = item['crop_type'] as String;
          final issueDescription = item['issue_description'] as String;

          // Check if file still exists
          final file = File(imagePath);
          if (!await file.exists()) {
            errors.add('File not found: $imagePath');
            await _dbHelper.deletePendingDiagnostic(localId);
            failureCount++;
            continue;
          }

          // Upload to server
          final result = await DiagnosticService.uploadForDiagnosis(
            imageFile: file,
            cropType: cropType,
            issueDescription: issueDescription,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw 'Upload timed out';
            },
          );

          // Mark as synced
          await _dbHelper.markDiagnosticSynced(localId);

          // Cache the uploaded diagnostic
          if (result['diagnostic'] != null) {
            await _dbHelper.cacheDiagnostic(result['diagnostic'].toJson());
          }

          // Delete local image file to free up space
          try {
            await file.delete();
          } catch (e) {
            print('Could not delete local file: $e');
          }

          successCount++;
          _failedAttempts = 0; // Reset failure counter on success
        } catch (e) {
          final localId = item['id'] as int;
          final error = e.toString().replaceAll('Exception: ', '');
          errors.add(error);

          // Update sync attempt
          await _dbHelper.updateSyncAttempt(
            localId,
            errorMessage: error,
          );

          failureCount++;
        }
      }

      _lastSyncTime = DateTime.now();

      // Complete sync log
      await _dbHelper.completeSyncLog(
        id: syncLogId,
        status: failureCount > 0 ? 'partial' : 'completed',
        itemsSynced: successCount,
        errorMessage: errors.isNotEmpty ? errors.join('; ') : null,
      );

      _isSyncing = false;

      return SyncResult(
        success: successCount > 0,
        message: 'Synced $successCount of ${pending.length} items',
        itemsSynced: successCount,
        itemsFailed: failureCount,
        errors: errors,
      );
    } catch (e) {
      _isSyncing = false;
      _failedAttempts++;

      await _dbHelper.completeSyncLog(
        id: syncLogId,
        status: 'failed',
        errorMessage: e.toString(),
      );

      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
        itemsSynced: 0,
      );
    }
  }

  /// Auto-sync when connectivity is restored
  Future<void> startAutoSync() async {
    onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      // If we have connectivity and there are pending items, sync
      if (!results.contains(ConnectivityResult.none)) {
        final pendingCount = await getPendingUploadsCount();
        if (pendingCount > 0) {
          print('Connectivity restored. Auto-syncing $pendingCount pending items...');
          await syncPendingDiagnostics();
        }
      }
    });
  }

  /// Retry failed syncs with exponential backoff
  Future<SyncResult> retryFailedSyncs() async {
    // Implement exponential backoff
    final backoffMinutes = [1, 5, 15, 30, 60][_failedAttempts.clamp(0, 4)];

    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync.inMinutes < backoffMinutes) {
        return SyncResult(
          success: false,
          message: 'Please wait ${backoffMinutes - timeSinceLastSync.inMinutes} more minutes before retrying',
          itemsSynced: 0,
        );
      }
    }

    return await syncPendingDiagnostics(force: true);
  }

  /// Clear all sync data (for debugging/testing)
  Future<void> clearSyncData() async {
    await _dbHelper.clearAllData();
    _lastSyncTime = null;
    _failedAttempts = 0;
  }
}

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

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, synced: $itemsSynced, failed: $itemsFailed)';
  }
}
