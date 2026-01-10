import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity types
enum NetworkType {
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  none,
}

/// Connectivity status with detailed information
class ConnectivityStatus {
  final bool isConnected;
  final NetworkType networkType;
  final bool hasInternetAccess;
  final DateTime checkedAt;

  ConnectivityStatus({
    required this.isConnected,
    required this.networkType,
    required this.hasInternetAccess,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  bool get isOnline => isConnected && hasInternetAccess;
  bool get isOffline => !isOnline;

  @override
  String toString() {
    return 'ConnectivityStatus(isConnected: $isConnected, networkType: ${networkType.name}, hasInternetAccess: $hasInternetAccess)';
  }
}

/// Service for monitoring network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  
  /// Internal connectivity stream controller
  static final _connectivityStreamController = StreamController<bool>.broadcast();
  
  /// Detailed status stream controller
  static final _statusStreamController = StreamController<ConnectivityStatus>.broadcast();
  
  /// Subscription to system connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Last known connectivity status
  static ConnectivityStatus? _lastStatus;
  
  /// Whether the service has been initialized
  static bool _isInitialized = false;
  
  // ================== PUBLIC GETTERS ==================
  
  /// Stream of connectivity changes (simple boolean)
  static Stream<bool> get onConnectivityChanged => _connectivityStreamController.stream;
  
  /// Stream of detailed connectivity status
  static Stream<ConnectivityStatus> get onStatusChanged => _statusStreamController.stream;
  
  /// Check if device is currently online
  static Future<bool> get isOnline async {
    final status = await checkConnectivity();
    return status.isOnline;
  }
  
  /// Get last known connectivity status
  static ConnectivityStatus? get lastStatus => _lastStatus;
  
  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;
  
  // ================== INITIALIZATION ==================
  
  /// Initialize the connectivity service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    final instance = ConnectivityService.instance;
    
    // Get initial status
    await checkConnectivity();
    
    // Subscribe to connectivity changes
    instance._connectivitySubscription = instance._connectivity.onConnectivityChanged.listen(
      (results) async {
        // Check actual internet access
        final status = await _checkInternetAccess(results);
        
        // Update last status
        _lastStatus = status;
        
        // Emit to streams
        _connectivityStreamController.add(status.isOnline);
        _statusStreamController.add(status);
      },
    );
    
    _isInitialized = true;
  }
  
  /// Dispose the connectivity service
  static void dispose() {
    final instance = ConnectivityService.instance;
    instance._connectivitySubscription?.cancel();
    instance._connectivitySubscription = null;
    _isInitialized = false;
  }
  
  // ================== CONNECTIVITY CHECKING ==================
  
  /// Check current connectivity status
  static Future<ConnectivityStatus> checkConnectivity() async {
    final instance = ConnectivityService.instance;
    
    try {
      final results = await instance._connectivity.checkConnectivity();
      final status = await _checkInternetAccess(results);
      
      _lastStatus = status;
      return status;
    } catch (e) {
      final status = ConnectivityStatus(
        isConnected: false,
        networkType: NetworkType.none,
        hasInternetAccess: false,
      );
      _lastStatus = status;
      return status;
    }
  }
  
  /// Check if device has actual internet access
  static Future<ConnectivityStatus> _checkInternetAccess(List<ConnectivityResult> results) async {
    // Determine network type
    NetworkType networkType = NetworkType.none;
    bool isConnected = false;
    
    if (results.contains(ConnectivityResult.none)) {
      networkType = NetworkType.none;
      isConnected = false;
    } else if (results.contains(ConnectivityResult.wifi)) {
      networkType = NetworkType.wifi;
      isConnected = true;
    } else if (results.contains(ConnectivityResult.mobile)) {
      networkType = NetworkType.mobile;
      isConnected = true;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      networkType = NetworkType.ethernet;
      isConnected = true;
    } else if (results.contains(ConnectivityResult.bluetooth)) {
      networkType = NetworkType.bluetooth;
      isConnected = true;
    } else if (results.contains(ConnectivityResult.vpn)) {
      networkType = NetworkType.vpn;
      isConnected = true;
    }
    
    // If not connected, no need to check internet access
    if (!isConnected) {
      return ConnectivityStatus(
        isConnected: false,
        networkType: networkType,
        hasInternetAccess: false,
      );
    }
    
    // Verify actual internet access
    bool hasInternetAccess = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      hasInternetAccess = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      hasInternetAccess = false;
    } on TimeoutException catch (_) {
      hasInternetAccess = false;
    } catch (_) {
      hasInternetAccess = false;
    }
    
    return ConnectivityStatus(
      isConnected: isConnected,
      networkType: networkType,
      hasInternetAccess: hasInternetAccess,
    );
  }
  
  // ================== UTILITY METHODS ==================
  
  /// Wait until device is online (with timeout)
  static Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    // First check if already online
    if (await isOnline) return true;
    
    // Wait for connectivity change
    try {
      final completer = Completer<bool>();
      StreamSubscription<bool>? subscription;
      Timer? timeoutTimer;
      
      // Set up timeout
      timeoutTimer = Timer(timeout, () {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      // Listen for connectivity changes
      subscription = onConnectivityChanged.listen((isOnline) {
        if (isOnline && !completer.isCompleted) {
          timeoutTimer?.cancel();
          subscription?.cancel();
          completer.complete(true);
        }
      });
      
      return await completer.future;
    } catch (e) {
      return false;
    }
  }
  
  /// Execute action when online (immediately if already online, or when connection is restored)
  static Future<T?> executeWhenOnline<T>(
    Future<T> Function() action, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (await isOnline) {
      return await action();
    }
    
    final connected = await waitForConnection(timeout: timeout);
    if (connected) {
      return await action();
    }
    
    return null;
  }
  
  /// Get human-readable network type name
  static String getNetworkTypeName(NetworkType type) {
    switch (type) {
      case NetworkType.wifi:
        return 'WiFi';
      case NetworkType.mobile:
        return 'Mobile Data';
      case NetworkType.ethernet:
        return 'Ethernet';
      case NetworkType.bluetooth:
        return 'Bluetooth';
      case NetworkType.vpn:
        return 'VPN';
      case NetworkType.none:
        return 'No Connection';
    }
  }
  
  /// Check if on metered connection (mobile data)
  static Future<bool> isMeteredConnection() async {
    final status = await checkConnectivity();
    return status.networkType == NetworkType.mobile;
  }
  
  /// Check if on WiFi
  static Future<bool> isWifiConnected() async {
    final status = await checkConnectivity();
    return status.networkType == NetworkType.wifi && status.hasInternetAccess;
  }
  
  // ================== PERIODIC CONNECTIVITY CHECK ==================
  
  Timer? _periodicCheckTimer;
  
  /// Start periodic connectivity checking
  void startPeriodicCheck({Duration interval = const Duration(minutes: 1)}) {
    stopPeriodicCheck();
    
    _periodicCheckTimer = Timer.periodic(interval, (_) async {
      final status = await checkConnectivity();
      
      // Only emit if status changed
      if (_lastStatus == null || 
          _lastStatus!.isOnline != status.isOnline ||
          _lastStatus!.networkType != status.networkType) {
        _connectivityStreamController.add(status.isOnline);
        _statusStreamController.add(status);
      }
      
      _lastStatus = status;
    });
  }
  
  /// Stop periodic connectivity checking
  void stopPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }
}

/// Extension for easy connectivity checks
extension ConnectivityExtension on Future<void> Function() {
  /// Execute only when online
  Future<void> executeWhenOnline() async {
    if (await ConnectivityService.isOnline) {
      await this();
    }
  }
}
