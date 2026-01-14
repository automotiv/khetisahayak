import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/activity_record.dart';

void main() {
  group('ActivityRecord', () {
    test('should create ActivityRecord instance', () {
      final record = ActivityRecord(
        activityType: 'Sowing',
        timestamp: DateTime(2023, 10, 1),
        timezoneOffset: '+05:30',
        metadata: {'crop': 'Wheat'},
      );

      expect(record.activityType, 'Sowing');
      expect(record.timestamp, DateTime(2023, 10, 1));
      expect(record.metadata, {'crop': 'Wheat'});
      expect(record.synced, 0);
    });

    test('toMap should return correct map', () {
      final record = ActivityRecord(
        id: 1,
        activityType: 'Irrigation',
        timestamp: DateTime(2023, 10, 2, 10, 30),
        timezoneOffset: '+05:30',
        metadata: {'duration': '2 hours'},
        synced: 1,
      );

      final map = record.toMap();

      expect(map['id'], 1);
      expect(map['activity_type'], 'Irrigation');
      expect(map['timestamp'], '2023-10-02T10:30:00.000');
      expect(map['metadata'], '{"duration":"2 hours"}');
      expect(map['synced'], 1);
    });

    test('fromMap should create correct ActivityRecord', () {
      final map = {
        'id': 2,
        'activity_type': 'Harvesting',
        'timestamp': '2023-10-03T14:00:00.000',
        'metadata': '{"yield": "500kg"}',
        'synced': 0,
      };

      final record = ActivityRecord.fromMap(map);

      expect(record.id, 2);
      expect(record.activityType, 'Harvesting');
      expect(record.timestamp, DateTime(2023, 10, 3, 14, 0, 0));
      expect(record.metadata, {'yield': '500kg'});
      expect(record.synced, 0);
    });

    test('should handle empty metadata', () {
      final map = {
        'activity_type': 'Other',
        'timestamp': '2023-10-04T09:00:00.000',
      };

      final record = ActivityRecord.fromMap(map);
      expect(record.metadata, {});
    });
  });
}
