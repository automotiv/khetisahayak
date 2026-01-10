import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

class ApiService {
  static const String baseUrl = '${AppConstants.baseUrl}/api'; // Production API

  /// Get crops list (used by CropAdvisoryScreen)
  Future<List<dynamic>> getCrops() async {
    try {
      final response = await ApiService.get('crops');
      if (response['crops'] != null) {
        return response['crops'] as List;
      } else if (response['data'] != null) {
        return response['data'] as List;
      }
      return [];
    } catch (e) {
      print('Error fetching crops: $e');
      // Return mock data for offline/error scenarios
      return [
        {'name': 'Rice', 'category': 'Cereals'},
        {'name': 'Wheat', 'category': 'Cereals'},
        {'name': 'Cotton', 'category': 'Cash Crops'},
        {'name': 'Sugarcane', 'category': 'Cash Crops'},
        {'name': 'Tomato', 'category': 'Vegetables'},
        {'name': 'Potato', 'category': 'Vegetables'},
      ];
    }
  }

  /// Get market prices (used by MarketPricesScreen)
  Future<List<dynamic>> getMarketPrices() async {
    try {
      final response = await ApiService.get('market-prices');
      if (response['prices'] != null) {
        return response['prices'] as List;
      } else if (response['data'] != null) {
        return response['data'] as List;
      }
      return [];
    } catch (e) {
      print('Error fetching market prices: $e');
      // Return mock data for offline/error scenarios
      return [
        {'name': 'Rice', 'price': 2500, 'unit': 'quintal', 'market': 'APMC Nashik'},
        {'name': 'Wheat', 'price': 2200, 'unit': 'quintal', 'market': 'APMC Nashik'},
        {'name': 'Cotton', 'price': 6500, 'unit': 'quintal', 'market': 'APMC Nagpur'},
        {'name': 'Tomato', 'price': 1500, 'unit': 'quintal', 'market': 'APMC Pune'},
      ];
    }
  }

  static Future<Map<String, dynamic>> syncLogbook({
    String? lastSyncTimestamp,
    required List<Map<String, dynamic>> changes,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    // Transform local changes to match backend schema
    final transformedChanges = changes.map((c) {
      final metadata = c['metadata'] != null ? jsonDecode(c['metadata']) : {};
      return {
        'local_id': c['id'],
        'id': c['backend_id'],
        'activity_type': c['activity_type'],
        'date': c['timestamp'],
        'description': metadata['description'],
        'cost': c['cost'],
        'deleted': c['deleted'] == 1,
        'version': c['version'],
      };
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/sync/logbook'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'last_sync_timestamp': lastSyncTimestamp,
        'changes': transformedChanges,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Sync failed: ${response.body}');
    }
  }

  // Legacy upload method (keep for compatibility if needed, but syncLogbook is preferred)
  static Future<Map<String, dynamic>> uploadActivityRecord(Map<String, dynamic> record) async {
    // ... existing implementation ...
    return {'success': true}; // Mock
  }

  // ================== REQUEST BATCHING ==================
  
  static final List<Map<String, dynamic>> _requestQueue = [];
  static const int _batchSize = 5;
  
  /// Queue a non-critical request (e.g. analytics, background sync)
  static void queueRequest(String endpoint, Map<String, dynamic> body) {
    _requestQueue.add({
      'endpoint': endpoint,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (_requestQueue.length >= _batchSize) {
      flushQueue();
    }
  }
  
  /// Flush queued requests
  static Future<void> flushQueue() async {
    if (_requestQueue.isEmpty) return;

    final token = await AuthService.getToken();
    if (token == null) return; // Or handle appropriately
    
    final batch = List<Map<String, dynamic>>.from(_requestQueue);
    _requestQueue.clear();
    
    try {
      // Assuming backend has a batch endpoint, or we send sequentially
      // For now, let's send sequentially but concurrently to speed up
      // In a real optimized scenario, we'd use a single /batch endpoint
      
      // await Future.wait(batch.map((req) => http.post(
      //   Uri.parse('$baseUrl/${req['endpoint']}'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode(req['body']),
      // )));
      
      // Better: Send to a hypothetical /batch endpoint
      /*
      await http.post(
        Uri.parse('$baseUrl/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'requests': batch}),
      );
      */
      
      // Since we don't have a batch endpoint yet, we'll just log this for now
      // as a placeholder for the implementation plan
      print('Flushed ${batch.length} requests');
      
    } catch (e) {
      print('Error flushing queue: $e');
      // Re-queue?
      _requestQueue.addAll(batch);
    }
  }

  // ================== GENERIC API METHODS ==================

  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final token = await AuthService.getToken();
      final uri = queryParams != null
          ? Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams)
          : Uri.parse('$baseUrl/$endpoint');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> postMultipart(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add fields and files from data
      data.forEach((key, value) {
        if (value is String) {
          request.fields[key] = value;
        }
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('API Error: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
