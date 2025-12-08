import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/menu_item.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

class AppConfigService {
  static Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await http.get(Uri.parse('${Constants.baseUrl}/api/app-config/menu'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['menu'];
          return items.map((item) => MenuItem.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching menu items: $e');
      return [];
    }
  }
}
