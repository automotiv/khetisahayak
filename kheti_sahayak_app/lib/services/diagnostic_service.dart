import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../models/diagnostic.dart';
import '../utils/constants.dart';

class DiagnosticService {
  static Future<Diagnostic> uploadImageForDiagnosis(File imageFile, {
    String? cropType,
    String? description,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}/diagnostics/analyze'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      if (cropType != null) {
        request.fields['cropType'] = cropType;
      }

      if (description != null) {
        request.fields['description'] = description;
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(responseData);
        return Diagnostic.fromJson(jsonData['diagnostic']);
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  static Future<List<Diagnostic>> getDiagnosticHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/diagnostics/history?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        if (jsonData['diagnostics'] != null) {
          return (jsonData['diagnostics'] as List)
              .map((json) => Diagnostic.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch diagnostic history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch diagnostic history: $e');
    }
  }

  static Future<Diagnostic> getDiagnostic(String diagnosticId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/diagnostics/$diagnosticId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        return Diagnostic.fromJson(jsonData['diagnostic']);
      } else {
        throw Exception('Failed to fetch diagnostic: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch diagnostic: $e');
    }
  }

  static Future<List<String>> getSupportedCropTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/diagnostics/crop-types'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        if (jsonData['cropTypes'] != null) {
          return List<String>.from(jsonData['cropTypes']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch crop types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch crop types: $e');
    }
  }
}