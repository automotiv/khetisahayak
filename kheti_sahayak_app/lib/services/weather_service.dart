
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/weather_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kheti_sahayak_app/services/geocoding_service.dart';

class WeatherService {
  static const String _apiKey = '0f18d2edebf650586232b0cf54925db4';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  Future<Map<String, dynamic>> getWeatherData() async {
    Position position = await _determinePosition();
    WeatherForecast weatherForecast = await getWeatherForecast(lat: position.latitude, lon: position.longitude);
    String locationName = await GeocodingService().getLocationName(position.latitude, position.longitude);

    return {
      'forecast': weatherForecast,
      'locationName': locationName,
    };
  }

  Future<WeatherForecast> getWeatherForecast({required double lat, required double lon}) async {
    final Uri uri = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return WeatherForecast.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load weather forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load weather forecast: $e');
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
