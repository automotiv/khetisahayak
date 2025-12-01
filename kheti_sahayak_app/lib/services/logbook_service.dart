import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/logbook_entry.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogbookService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<List<LogbookEntry>> getEntries() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/logbook'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => LogbookEntry.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching logbook entries: $e');
      return [];
    }
  }

  static Future<bool> createEntry(LogbookEntry entry) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/logbook'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(entry.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating logbook entry: $e');
      return false;
    }
  }

  static Future<bool> deleteEntry(int id) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/logbook/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting logbook entry: $e');
      return false;
    }
  }
}
