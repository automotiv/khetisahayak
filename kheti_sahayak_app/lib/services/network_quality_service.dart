import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkQuality {
  high,   // WiFi, 5G
  medium, // 4G
  low,    // 3G, 2G, None
}

class NetworkQualityService {
  static final NetworkQualityService _instance = NetworkQualityService._internal();
  factory NetworkQualityService() => _instance;
  NetworkQualityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _qualityController = StreamController<NetworkQuality>.broadcast();

  Stream<NetworkQuality> get qualityStream => _qualityController.stream;
  NetworkQuality _currentQuality = NetworkQuality.high;
  NetworkQuality get currentQuality => _currentQuality;

  void init() {
    _connectivity.onConnectivityChanged.listen(_updateQuality);
    _checkInitialQuality();
  }

  Future<void> _checkInitialQuality() async {
    final result = await _connectivity.checkConnectivity();
    _updateQuality(result);
  }

  void _updateQuality(List<ConnectivityResult> results) {
    // connectivity_plus returns a list, usually we care about the first active one
    // or the best one.
    
    if (results.contains(ConnectivityResult.wifi) || 
        results.contains(ConnectivityResult.ethernet)) {
      _currentQuality = NetworkQuality.high;
    } else if (results.contains(ConnectivityResult.mobile)) {
      // We can't easily distinguish 2G/3G/4G with just connectivity_plus in all cases without native code or specific plugins,
      // but for now we'll assume mobile is Medium, unless we can get more info.
      // Ideally we'd use a package like `network_info_plus` or platform channels to get subtype.
      // For this MVP, let's treat Mobile as Medium. 
      // To simulate "Low" bandwidth, we might need a manual toggle or more advanced logic.
      _currentQuality = NetworkQuality.medium;
    } else if (results.contains(ConnectivityResult.none)) {
      _currentQuality = NetworkQuality.low;
    } else {
      _currentQuality = NetworkQuality.low;
    }
    
    _qualityController.add(_currentQuality);
  }

  bool shouldLoadHighQualityImages() {
    return _currentQuality == NetworkQuality.high;
  }
  
  bool shouldCompressAggressively() {
    return _currentQuality == NetworkQuality.low || _currentQuality == NetworkQuality.medium;
  }
  
  void dispose() {
    _qualityController.close();
  }
}
