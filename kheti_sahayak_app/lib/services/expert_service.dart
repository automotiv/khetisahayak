import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/expert.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

class ExpertService {
  static Future<List<Expert>> getExperts() async {
    try {
      final response = await http.get(Uri.parse('${Constants.baseUrl}/api/experts'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => Expert.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching experts: $e');
      return [];
    }
  }
}
