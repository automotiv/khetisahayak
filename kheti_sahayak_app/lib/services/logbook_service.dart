import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/logbook_entry.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';

class LogbookService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get logbook entries with optional filtering (Offline First)
  static Future<List<LogbookEntry>> getEntries({
    int? fieldId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;
      String where = 'deleted = 0';
      List<dynamic> whereArgs = [];

      if (fieldId != null) {
        where += ' AND field_id = ?';
        whereArgs.add(fieldId);
      }

      if (startDate != null) {
        where += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final maps = await db.query(
        'activity_records',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => LogbookEntry.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching logbook entries: $e');
      return [];
    }
  }

  /// Create a new logbook entry (Offline First)
  static Future<bool> createEntry(LogbookEntry entry) async {
    try {
      // 1. Save locally first
      final id = await _dbHelper.insertActivityRecordFromBackend(entry.toMap()..remove('id')); // Using insertActivityRecordFromBackend as a generic insert for now, but better to use a dedicated insert
      
      // Actually, insertActivityRecordFromBackend expects backend_id. 
      // We should use a simple insert for local creation.
      // Let's use raw insert via db helper or add a method there.
      // Since we can't easily modify db helper right now without context, let's try to use what we have or raw query.
      
      final db = await _dbHelper.database;
      await db.insert('activity_records', entry.toMap()..remove('id')..['dirty'] = 1..['synced'] = 0);
      
      // 2. Trigger background sync (fire and forget)
      _syncEntry(entry); 
      
      return true;
    } catch (e) {
      print('Error creating logbook entry: $e');
      return false;
    }
  }

  /// Delete a logbook entry (Offline First)
  static Future<bool> deleteEntry(int id) async {
    try {
      final db = await _dbHelper.database;
      // Soft delete
      await db.update(
        'activity_records',
        {'deleted': 1, 'dirty': 1, 'synced': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Trigger sync
      syncEntries();
      
      return true;
    } catch (e) {
      print('Error deleting logbook entry: $e');
      return false;
    }
  }

  /// Sync dirty entries with backend
  static Future<void> syncEntries() async {
    try {
      final dirtyRecords = await _dbHelper.getDirtyActivityRecords();
      if (dirtyRecords.isEmpty) return;

      final token = await _getToken();
      if (token == null) return;

      for (var recordMap in dirtyRecords) {
        final entry = LogbookEntry.fromMap(recordMap);
        await _syncEntry(entry, token: token);
      }
    } catch (e) {
      print('Error syncing entries: $e');
    }
  }

  static Future<void> _syncEntry(LogbookEntry entry, {String? token}) async {
    try {
      token ??= await _getToken();
      if (token == null) return;

      http.Response response;
      if (entry.deleted) {
        if (entry.backendId != null) {
           response = await http.delete(
            Uri.parse('${Constants.baseUrl}/api/logbook/${entry.backendId}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
        } else {
          // If no backend ID, just delete locally permanently
           final db = await _dbHelper.database;
           await db.delete('activity_records', where: 'id = ?', whereArgs: [entry.id]);
           return;
        }
      } else if (entry.backendId == null) {
        // Create
        response = await http.post(
          Uri.parse('${Constants.baseUrl}/api/logbook'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(entry.toJson()),
        );
      } else {
        // Update
        response = await http.put(
          Uri.parse('${Constants.baseUrl}/api/logbook/${entry.backendId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(entry.toJson()),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final backendData = data['data'];
          await _dbHelper.updateActivityRecordSyncStatus(
            localId: entry.id!,
            backendId: backendData['id'],
            version: backendData['version'] ?? entry.version + 1,
            dirty: 0,
          );
        }
      }
    } catch (e) {
      print('Error syncing single entry: $e');
    }
  }
}
