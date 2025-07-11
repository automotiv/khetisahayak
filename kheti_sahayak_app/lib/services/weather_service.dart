import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WeatherService {
  static Future<Map<String, dynamic>> getCurrentWeather({double? lat, double? lon}) async {
    try {
      Map<String, dynamic> params = {};

      if (lat != null && lon != null) {
        params['lat'] = lat.toString();
        params['lon'] = lon.toString();
      } else {
        final position = await _getCurrentLocation();
        params['lat'] = position.latitude.toString();
        params['lon'] = position.longitude.toString();
      }

      final token = await AuthService.getToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      final response = await ApiService.get(
        '/weather/current?${_buildQueryString(params)}',
        headers: headers,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to fetch current weather: $e');
    }
  }

  static Future<Map<String, dynamic>> getWeatherForecast({double? lat, double? lon, int days = 7}) async {
    try {
      Map<String, dynamic> params = {'days': days.toString()};

      if (lat != null && lon != null) {
        params['lat'] = lat.toString();
        params['lon'] = lon.toString();
      } else {
        final position = await _getCurrentLocation();
        params['lat'] = position.latitude.toString();
        params['lon'] = position.longitude.toString();
      }

      final token = await AuthService.getToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      final response = await ApiService.get(
        '/weather/forecast?${_buildQueryString(params)}',
        headers: headers,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to fetch weather forecast: $e');
    }
  }

  static Future<Map<String, dynamic>> getWeatherAlerts({double? lat, double? lon}) async {
    try {
      Map<String, dynamic> params = {};

      if (lat != null && lon != null) {
        params['lat'] = lat.toString();
        params['lon'] = lon.toString();
      } else {
        final position = await _getCurrentLocation();
        params['lat'] = position.latitude.toString();
        params['lon'] = position.longitude.toString();
      }

      final token = await AuthService.getToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      final response = await ApiService.get(
        '/weather/alerts?${_buildQueryString(params)}',
        headers: headers,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to fetch weather alerts: $e');
    }
  }

  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static String _buildQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}