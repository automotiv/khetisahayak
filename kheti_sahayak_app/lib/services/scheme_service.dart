import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

class SchemeService {
  static Future<List<Scheme>> getSchemes() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/schemes'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => Scheme.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching schemes: $e');
      return [];
    }
  }
}
