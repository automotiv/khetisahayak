import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/equipment_listing.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EquipmentService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<List<EquipmentListing>> getListings() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/equipment/listings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => EquipmentListing.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching equipment listings: $e');
      return [];
    }
  }
}
