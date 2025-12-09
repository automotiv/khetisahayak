
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/weather_model.dart';
import 'package:kheti_sahayak_app/services/local_notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kheti_sahayak_app/services/geocoding_service.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';

class WeatherService {
  static const String _apiKey = '0f18d2edebf650586232b0cf54925db4';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  static const String _oneCallUrl = 'https://api.openweathermap.org/data/2.5/onecall';

  Future<Map<String, dynamic>> getWeatherData() async {
    Position position = await _determinePosition();
    UnifiedWeather weather;

    try {
      // Try One Call API first (Precision)
      weather = await _getOneCallWeather(lat: position.latitude, lon: position.longitude);
    } catch (e) {
      // Fallback to Standard API
      AppLogger.warning('One Call API failed ($e), falling back to standard forecast');
      weather = await _getStandardForecast(lat: position.latitude, lon: position.longitude);
    }

    // Check for severe weather and notify
    _checkAndNotifySevereWeather(weather);

    String locationName = await GeocodingService().getLocationName(position.latitude, position.longitude);

    return {
      'forecast': weather,
      'locationName': locationName,
    };
  }

  Future<UnifiedWeather> _getOneCallWeather({required double lat, required double lon}) async {
    final Uri uri = Uri.parse('$_oneCallUrl?lat=$lat&lon=$lon&exclude=minutely,hourly&appid=$_apiKey&units=metric');
    
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return UnifiedWeather.fromOneCall(jsonResponse);
    } else {
      throw Exception('Failed to load one call weather: ${response.statusCode}');
    }
  }

  Future<UnifiedWeather> _getStandardForecast({required double lat, required double lon}) async {
    final Uri uri = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return UnifiedWeather.fromStandard(jsonResponse);
    } else {
      throw Exception('Failed to load standard weather: ${response.statusCode}');
    }
  }

  Future<UnifiedWeather> getHistoricalWeather(DateTime date) async {
    Position position = await _determinePosition();
    // Unix timestamp for the specific date
    final int timestamp = date.millisecondsSinceEpoch ~/ 1000;
    
    // One Call 2.5 Time Machine endpoint
    // https://api.openweathermap.org/data/2.5/onecall/timemachine?lat={lat}&lon={lon}&dt={time}&appid={API key}
    final Uri uri = Uri.parse('$_oneCallUrl/timemachine?lat=${position.latitude}&lon=${position.longitude}&dt=$timestamp&appid=$_apiKey&units=metric');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return UnifiedWeather.fromHistorical(jsonResponse);
    } else {
      throw Exception('Failed to load historical weather: ${response.statusCode}');
    }
  }

  void _checkAndNotifySevereWeather(UnifiedWeather weather) {
    // Simple logic: Notify if Thunderstorm or heavy rain
    // In a real app, we would check specific IDs or alert fields from One Call API
    
    bool isSevere = false;
    String title = '';
    String body = '';

    if (weather.condition.toLowerCase().contains('thunderstorm')) {
      isSevere = true;
      title = 'Severe Weather Alert: Thunderstorm';
      body = 'Thunderstorms detected in your area. Please take necessary precautions.';
    } else if (weather.condition.toLowerCase().contains('rain') && weather.description.toLowerCase().contains('heavy')) {
      isSevere = true;
      title = 'Heavy Rain Alert';
      body = 'Heavy rain detected. Check drainage and protect sensitive crops.';
    } else if (weather.windSpeed > 20.0) { // > 20 m/s is very strong wind
      isSevere = true;
      title = 'High Wind Alert';
      body = 'High winds detected (${weather.windSpeed} m/s). Secure loose equipment.';
    }

    if (isSevere) {
      LocalNotificationService().showNotification(
        id: 1001, // Static ID for weather alert
        title: title,
        body: body,
        payload: 'weather_alert',
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
