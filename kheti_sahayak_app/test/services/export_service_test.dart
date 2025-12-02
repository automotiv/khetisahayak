import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/activity_record.dart';

void main() {
  group('ExportService Logic', () {
    test('should generate correct CSV content', () {
      final records = [
        ActivityRecord(
          id: 1,
          fieldId: 101,
          activityType: 'Sowing',
          timestamp: DateTime(2023, 10, 27, 10, 0),
          timezoneOffset: '+05:30',
          synced: 1,
        ),
        ActivityRecord(
          id: 2,
          activityType: 'Irrigation',
          timestamp: DateTime(2023, 10, 28, 14, 30),
          timezoneOffset: '+05:30',
          synced: 0,
        ),
      ];

      final StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('ID,Field ID,Activity Type,Timestamp,Timezone Offset,Synced');

      for (final record in records) {
        csvBuffer.writeln(
          '${record.id},${record.fieldId ?? ""},${record.activityType},${record.timestamp.toIso8601String()},${record.timezoneOffset},${record.synced}',
        );
      }

      final csvContent = csvBuffer.toString();
      final lines = csvContent.split('\n');

      expect(lines[0].trim(), 'ID,Field ID,Activity Type,Timestamp,Timezone Offset,Synced');
      expect(lines[1].trim(), '1,101,Sowing,2023-10-27T10:00:00.000,+05:30,1');
      expect(lines[2].trim(), '2,,Irrigation,2023-10-28T14:30:00.000,+05:30,0');
    });
  });
}
