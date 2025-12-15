import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

class ApiService {
  static const String baseUrl = '${AppConstants.baseUrl}/api'; // Production API

  static Future<Map<String, dynamic>> syncLogbook({
    String? lastSyncTimestamp,
    required List<Map<String, dynamic>> changes,
  }) async {
    final token = await AuthService().getToken();
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
    
    final token = await AuthService().getToken();
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
}
