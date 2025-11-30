import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // Get auth token from secure storage
  static Future<String?> _getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Build headers with optional auth token
  static Future<Map<String, String>> _buildHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Build full URL from endpoint
  static String _buildUrl(String endpoint, {Map<String, dynamic>? queryParams}) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    String url = '${AppConstants.baseUrl}/$endpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      url = '$url?$queryString';
    }

    return url;
  }

  // Parse response and handle errors
  static dynamic _handleResponse(http.Response response) {
    final body = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'] ?? body;
    } else {
      final message = body['error'] ?? body['message'] ?? 'An error occurred';
      throw Exception(message);
    }
  }

  // GET request
  static Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final url = _buildUrl(endpoint, queryParams: queryParams);
    final headers = await _buildHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  // POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = _buildUrl(endpoint);
    final headers = await _buildHeaders();

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = _buildUrl(endpoint);
    final headers = await _buildHeaders();

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // DELETE request
  static Future<dynamic> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _buildHeaders();

    final response = await http.delete(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  // POST multipart request (for file uploads)
  static Future<dynamic> postMultipart(String endpoint, Map<String, dynamic> formData) async {
    final url = _buildUrl(endpoint);
    final token = await _getToken();

    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add form fields and files
    for (final entry in formData.entries) {
      if (entry.value is File) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, (entry.value as File).path));
      } else if (entry.value is List<File>) {
        for (final file in entry.value as List<File>) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, file.path));
        }
      } else {
        request.fields[entry.key] = entry.value.toString();
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // Legacy instance methods for backward compatibility
  Future<List<dynamic>> getCrops() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {'name': 'Wheat', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Wheat'},
      {'name': 'Rice', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Rice'},
      {'name': 'Sugarcane', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Sugarcane'},
      {'name': 'Cotton', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Cotton'},
      {'name': 'Maize', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Maize'},
    ];
  }

  Future<List<dynamic>> getMarketPrices() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {'name': 'Onions', 'price': '₹2,500 / quintal'},
      {'name': 'Tomatoes', 'price': '₹1,800 / quintal'},
      {'name': 'Potatoes', 'price': '₹2,000 / quintal'},
      {'name': 'Soybeans', 'price': '₹4,500 / quintal'},
      {'name': 'Cotton', 'price': '₹7,000 / quintal'},
    ];
  }

  Future<Map<String, String>> getCropDetails(String cropName) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'sowingInfo': 'Ideal sowing time is from May to June. Use a seed rate of 15 kg/hectare.',
      'wateringSchedule': 'Requires irrigation every 10-15 days during the growing season.',
      'fertilizerReq': 'Apply a basal dose of NPK at 40:60:40 kg/ha.',
      'pestsAndDiseases': 'Watch out for aphids and stem borer. Powdery mildew can be an issue in humid conditions.',
    };
  }
}
