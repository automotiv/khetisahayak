
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _apiKey = '0f18d2edebf650586232b0cf54925db4';
  static const String _baseUrl = 'http://api.openweathermap.org/geo/1.0/reverse';

  Future<String> getLocationName(double lat, double lon) async {
    final Uri uri = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&limit=1&appid=$_apiKey');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded.isNotEmpty) {
          final name = decoded[0]['name'];
          final country = decoded[0]['country'];
          return '$name, $country';
        }
        return 'Unknown Location';
      } else {
        throw Exception('Failed to get location name');
      }
    } catch (e) {
      throw Exception('Failed to get location name: $e');
    }
  }
}
