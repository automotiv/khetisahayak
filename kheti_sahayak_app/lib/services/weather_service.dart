import 'package:kheti_sahayak_app/services/api_service.dart';

class WeatherService {
  static Future<Map<String, dynamic>> getWeather(double latitude, double longitude) async {
    final response = await ApiService.get('weather?lat=$latitude&lon=$longitude');
    return response;
  }
}