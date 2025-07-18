import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';

class ApiService {
  static const String _baseUrl = AppConstants.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, 
    Map<String, dynamic> data,
  ) async {
    final token = await AuthService.getToken();
    final headers = <String, String>{};
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/$endpoint'));
    request.headers.addAll(headers);

    // Add text fields
    data.forEach((key, value) {
      if (value is! File) {
        request.fields[key] = value.toString();
      }
    });

    // Add file fields
    data.forEach((key, value) {
      if (value is File) {
        request.files.add(http.MultipartFile(
          key,
          value.readAsBytes().asStream(),
          value.lengthSync(),
          filename: value.path.split('/').last,
        ));
      }
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, 
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    
    final response = await http.put(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = await _getHeaders();
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    } else {
      String errorMessage = 'Failed to load data: ${response.statusCode}';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        errorMessage = '${errorMessage} ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }
}