import 'dart:convert';
import 'package:kheti_sahayak_app/models/activity_record.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';

class ActivityService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Create a new activity record with automatic timestamp
  Future<int> createActivityRecord({
    required String activityType,
    int? fieldId,
    Map<String, dynamic> metadata = const {},
    DateTime? customTimestamp,
    double cost = 0.0,
  }) async {
    final now = DateTime.now();
    final timestamp = customTimestamp ?? now;
    final timezoneOffset = now.timeZoneOffset.inHours.toString().padLeft(2, '0') +
        ':' +
        (now.timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0');
    
    // Format offset as +HH:MM or -HH:MM
    final formattedOffset = now.timeZoneOffset.isNegative
        ? '-${timezoneOffset}'
        : '+${timezoneOffset}';

    final record = ActivityRecord(
      fieldId: fieldId,
      activityType: activityType,
      timestamp: timestamp,
      timezoneOffset: formattedOffset,
      metadata: metadata,
      cost: cost,
    );

    return await _dbHelper.insertActivityRecord(record.toMap());
  }

  /// Get all activity records
  Future<List<ActivityRecord>> getActivityRecords({int? limit, int? offset}) async {
    final maps = await _dbHelper.getActivityRecords(limit: limit, offset: offset);
    return maps.map((map) => ActivityRecord.fromMap(map)).toList();
  }

  /// Delete an activity record
  Future<int> deleteActivityRecord(int id) async {
    return await _dbHelper.deleteActivityRecord(id);
  }

  /// Bulk delete activity records
  Future<void> deleteActivityRecords(List<int> ids) async {
    for (final id in ids) {
      await _dbHelper.deleteActivityRecord(id);
    }
  }
}
