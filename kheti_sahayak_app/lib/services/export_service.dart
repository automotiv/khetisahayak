import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:kheti_sahayak_app/models/activity_record.dart';

class ExportService {
  /// Export activity records to CSV
  Future<String> exportActivityRecordsToCsv(List<ActivityRecord> records) async {
    final StringBuffer csvBuffer = StringBuffer();

    // Header
    csvBuffer.writeln('ID,Field ID,Activity Type,Timestamp,Timezone Offset,Synced');

    // Rows
    for (final record in records) {
      csvBuffer.writeln(
        '${record.id},${record.fieldId ?? ""},${record.activityType},${record.timestamp.toIso8601String()},${record.timezoneOffset},${record.synced}',
      );
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/activity_records_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvBuffer.toString());

    return path;
  }
}
