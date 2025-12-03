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

  /// Upload activity record to server
  /// Converts local activity record to logbook entry format
  static Future<Map<String, dynamic>> uploadActivityRecord(Map<String, dynamic> record) async {
    try {
      // Parse timestamp to get date
      final timestamp = record['timestamp'] is String
          ? DateTime.parse(record['timestamp'])
          : record['timestamp'] as DateTime;
      
      // Format date as YYYY-MM-DD for API
      final date = timestamp.toIso8601String().split('T')[0];
      
      // Extract metadata if present
      final metadata = record['metadata'] is String
          ? json.decode(record['metadata'])
          : (record['metadata'] ?? {});
      
      // Build request body matching backend API expectations
      final requestBody = {
        'activity_type': record['activity_type'],
        'date': date,
        'description': metadata['description'] ?? metadata['notes'] ?? '',
        'cost': (record['cost'] as num?)?.toDouble() ?? 0.0,
        'income': 0.0, // Can be extended later if needed
      };
      
      // Upload to logbook endpoint
      final result = await post('/logbook', requestBody);
      
      return {
        'success': true,
        'data': result,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Real API calls for crops and market data
  Future<List<dynamic>> getCrops() async {
    try {
      final result = await get('educational-content', queryParams: {'category': 'crops'});
      final List<dynamic> content = result['content'] ?? result ?? [];
      return content.map((item) => {
        'id': item['id'],
        'name': item['title'] ?? item['name'] ?? 'Unknown Crop',
        'imageUrl': item['image_url'] ?? 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=${item['title'] ?? 'Crop'}',
        'description': item['summary'] ?? item['description'] ?? '',
        'category': item['category'] ?? 'crops',
      }).toList();
    } catch (e) {
      // Fallback to default crops if API fails
      return [
        {'name': 'Wheat', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Wheat'},
        {'name': 'Rice', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Rice'},
        {'name': 'Sugarcane', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Sugarcane'},
        {'name': 'Cotton', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Cotton'},
        {'name': 'Maize', 'imageUrl': 'https://via.placeholder.com/400x200.png/a2dca7/000000?text=Maize'},
      ];
    }
  }

  Future<List<dynamic>> getMarketPrices() async {
    try {
      final result = await get('marketplace');
      final List<dynamic> products = result['products'] ?? result ?? [];
      return products.map((item) => {
        'id': item['id'],
        'name': item['name'] ?? 'Unknown Product',
        'price': '₹${_formatPrice(item['price'])} / ${item['unit'] ?? 'unit'}',
        'rawPrice': item['price'],
        'category': item['category'] ?? '',
        'description': item['description'] ?? '',
        'imageUrl': item['image_url'] ?? item['images']?[0] ?? '',
        'isOrganic': item['is_organic'] ?? false,
        'sellerName': item['seller_name'] ?? '',
      }).toList();
    } catch (e) {
      // Fallback to default prices if API fails
      return [
        {'name': 'Onions', 'price': '₹2,500 / quintal'},
        {'name': 'Tomatoes', 'price': '₹1,800 / quintal'},
        {'name': 'Potatoes', 'price': '₹2,000 / quintal'},
        {'name': 'Soybeans', 'price': '₹4,500 / quintal'},
        {'name': 'Cotton', 'price': '₹7,000 / quintal'},
      ];
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final numPrice = price is num ? price : num.tryParse(price.toString()) ?? 0;
    return numPrice.toStringAsFixed(numPrice.truncateToDouble() == numPrice ? 0 : 2);
  }

  Future<Map<String, String>> getCropDetails(String cropName) async {
    try {
      // Search for crop in educational content
      final result = await get('educational-content', queryParams: {'search': cropName, 'category': 'crops'});
      final List<dynamic> content = result['content'] ?? result ?? [];

      if (content.isNotEmpty) {
        final crop = content.first;
        return {
          'id': crop['id']?.toString() ?? '',
          'title': crop['title'] ?? cropName,
          'sowingInfo': crop['sowing_info'] ?? _extractSection(crop['content'], 'sowing') ?? 'Sowing information not available.',
          'wateringSchedule': crop['watering_schedule'] ?? _extractSection(crop['content'], 'water') ?? 'Watering schedule not available.',
          'fertilizerReq': crop['fertilizer_req'] ?? _extractSection(crop['content'], 'fertilizer') ?? 'Fertilizer requirements not available.',
          'pestsAndDiseases': crop['pests_diseases'] ?? _extractSection(crop['content'], 'pest') ?? 'Pest and disease information not available.',
          'content': crop['content'] ?? '',
          'summary': crop['summary'] ?? '',
        };
      }
      throw Exception('Crop not found');
    } catch (e) {
      // Fallback to default info if API fails
      return {
        'sowingInfo': 'Ideal sowing time varies by region. Consult local agricultural experts.',
        'wateringSchedule': 'Requires regular irrigation based on soil moisture levels.',
        'fertilizerReq': 'Apply balanced NPK fertilizer as per soil test recommendations.',
        'pestsAndDiseases': 'Monitor regularly for common pests. Use integrated pest management practices.',
      };
    }
  }

  String? _extractSection(String? content, String keyword) {
    if (content == null || content.isEmpty) return null;
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(keyword)) {
        // Return this line and next few lines as the relevant section
        return lines.skip(i).take(3).join(' ').trim();
      }
    }
    return null;
  }
}
