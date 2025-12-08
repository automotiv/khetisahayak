import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._init();

  LocationService._init();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return false;
    }
    
    return true;
  }

  /// Get current location with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check and request permission
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get location with timeout
  Future<Position?> getLocationWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final position = await getCurrentLocation()?.timeout(
        timeout,
        onTimeout: () {
          print('Location request timed out');
          return null;
        },
      );
      return position;
    } catch (e) {
      print('Error getting location with timeout: $e');
      return null;
    }
  }

  /// Get location accuracy description
  String getAccuracyDescription(double? accuracy) {
    if (accuracy == null) return 'Unknown';
    if (accuracy < 10) return 'Excellent (±${accuracy.toStringAsFixed(1)}m)';
    if (accuracy < 50) return 'Good (±${accuracy.toStringAsFixed(1)}m)';
    if (accuracy < 100) return 'Fair (±${accuracy.toStringAsFixed(1)}m)';
    return 'Poor (±${accuracy.toStringAsFixed(1)}m)';
  }

  /// Format coordinates for display
  String formatCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return 'No location';
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
}
