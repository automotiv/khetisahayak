import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_manager_service.dart';

class OfflineService {
  final Connectivity _connectivity = Connectivity();
  final SyncManagerService _syncManager = SyncManagerService();
  
  // Stream to expose connection status
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionChanged => _connectionStatusController.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // Singleton setup
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal() {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
     // connectivity_plus 6.0 returns a List
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Determine if any result implies online status
    bool newStatus = results.contains(ConnectivityResult.mobile) || 
                     results.contains(ConnectivityResult.wifi) || 
                     results.contains(ConnectivityResult.ethernet);

    if (newStatus != _isOnline) {
      _isOnline = newStatus;
      _connectionStatusController.add(_isOnline);
      print('OfflineService: Connectivity changed to ${_isOnline ? "ONLINE" : "OFFLINE"}');

      if (_isOnline) {
        // Trigger auto-sync when back online
        _syncManager.processQueue();
        _syncManager.syncDown();
      }
    }
  }

  // Helper to ensure database is initialized (optional wrapper)
  Future<void> initialize() async {
    // Could ensure DB is ready here
  }
}
