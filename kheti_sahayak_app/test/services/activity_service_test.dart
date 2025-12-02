import 'package:flutter_test/flutter_test.dart';


void main() {
  group('ActivityService Logic', () {
    test('should format timezone offset correctly', () {
      // Logic verification for the timezone formatting used in ActivityService
      
      String formatOffset(Duration offset) {
        final hours = offset.inHours.abs().toString().padLeft(2, '0');
        final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
        final sign = offset.isNegative ? '-' : '+';
        return '$sign$hours:$minutes';
      }

      expect(formatOffset(Duration(hours: 5, minutes: 30)), '+05:30');
      expect(formatOffset(Duration(hours: -5)), '-05:00');
      expect(formatOffset(Duration(hours: 0)), '+00:00');
      expect(formatOffset(Duration(hours: 5, minutes: 45)), '+05:45');
    });
  });
}
