import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/application.dart';
import 'package:kheti_sahayak_app/models/application_timeline_event.dart';
import 'package:kheti_sahayak_app/services/application_service.dart';

void main() {
  group('ApplicationService Tests', () {
    test('submitApplication creates a new application with submitted status', () async {
      final app = await ApplicationService.submitApplication(
        schemeId: 'scheme_123',
        schemeName: 'Test Scheme',
        userId: 'user_123',
      );

      expect(app.schemeId, 'scheme_123');
      expect(app.userId, 'user_123');
      expect(app.status, ApplicationStatus.submitted);
      expect(app.timeline.length, 1);
      expect(app.timeline.first.status, ApplicationStatus.submitted);
    });

    test('updateApplicationStatus updates status and adds timeline event', () async {
      final app = await ApplicationService.submitApplication(
        schemeId: 'scheme_456',
        schemeName: 'Another Scheme',
        userId: 'user_456',
      );

      final updatedApp = await ApplicationService.updateApplicationStatus(
        app.id,
        ApplicationStatus.underReview,
      );

      expect(updatedApp.status, ApplicationStatus.underReview);
      expect(updatedApp.timeline.length, 2);
      expect(updatedApp.timeline.last.status, ApplicationStatus.underReview);
    });

    test('updateApplicationStatus to approved sets expected disbursement date', () async {
      final app = await ApplicationService.submitApplication(
        schemeId: 'scheme_789',
        schemeName: 'Approved Scheme',
        userId: 'user_789',
      );

      final updatedApp = await ApplicationService.updateApplicationStatus(
        app.id,
        ApplicationStatus.approved,
      );

      expect(updatedApp.status, ApplicationStatus.approved);
      expect(updatedApp.expectedDisbursementDate, isNotNull);
      // Check if date is roughly 15 days from now (allow small diff)
      final expectedDate = DateTime.now().add(const Duration(days: 15));
      final diff = updatedApp.expectedDisbursementDate!.difference(expectedDate).inSeconds.abs();
      expect(diff, lessThan(10)); // Should be very close
    });

    test('getApplicationsForUser returns correct applications', () async {
      final userId = 'user_test_list';
      await ApplicationService.submitApplication(
        schemeId: 's1',
        schemeName: 'Scheme 1',
        userId: userId,
      );
      await ApplicationService.submitApplication(
        schemeId: 's2',
        schemeName: 'Scheme 2',
        userId: userId,
      );

      final apps = await ApplicationService.getApplicationsForUser(userId);
      expect(apps.length, 2);
    });
  });
}
