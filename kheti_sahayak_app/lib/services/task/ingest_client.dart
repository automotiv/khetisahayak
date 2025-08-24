import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/services/api_service.dart';

class IngestClient {
  /// Request a presigned upload URL from backend
  static Future<Map<String, dynamic>> presign(String filename, String contentType) async {
    final resp = await ApiService.post('ingestion/presign', {'filename': filename, 'contentType': contentType});
    return resp;
  }

  /// Upload bytes directly to the presigned URL returned by the server
  static Future<void> uploadToUrl(String url, List<int> bytes, String contentType) async {
    final r = await http.put(Uri.parse(url), headers: {'Content-Type': contentType}, body: bytes);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Presigned upload failed: ${r.statusCode} ${r.body}');
    }
  }

  /// Notify server to finalize ingest (strip EXIF etc.)
  static Future<Map<String, dynamic>> finalize(String key, {bool keepLocation = false}) async {
    final resp = await ApiService.post('ingestion/finalize', {'key': key, 'keepLocation': keepLocation});
    return resp;
  }
}
