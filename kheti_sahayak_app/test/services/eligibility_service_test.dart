import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/eligibility_service.dart';

void main() {
  group('EligibilityService Tests', () {
    final user = User(
      id: '1',
      username: 'test',
      email: 'test@example.com',
      createdAt: DateTime.now(),
      address: 'Pune, Maharashtra',
    );

    final field1 = Field(
      id: 1,
      name: 'Field 1',
      area: 2.5,
      cropType: 'Wheat',
      location: 'Pune',
    );

    final field2 = Field(
      id: 2,
      name: 'Field 2',
      area: 1.0,
      cropType: 'Rice',
      location: 'Pune',
    );

    test('returns uncertain if user is null', () {
      final scheme = Scheme(id: 1, name: 'Test', description: 'Test');
      final result = EligibilityService.checkEligibility(scheme, null, []);
      expect(result.status, EligibilityStatus.uncertain);
    });

    test('returns uncertain if no criteria', () {
      final scheme = Scheme(id: 1, name: 'Test', description: 'Test');
      final result = EligibilityService.checkEligibility(scheme, user, []);
      expect(result.status, EligibilityStatus.uncertain);
    });

    test('checks min land area correctly', () {
      final scheme = Scheme(
        id: 1,
        name: 'Test',
        description: 'Test',
        eligibilityCriteria: {'min_land_area': 3.0},
      );

      // Total area = 3.5
      var result = EligibilityService.checkEligibility(scheme, user, [field1, field2]);
      expect(result.status, EligibilityStatus.eligible);

      // Total area = 2.5
      result = EligibilityService.checkEligibility(scheme, user, [field1]);
      expect(result.status, EligibilityStatus.notEligible);
      expect(result.missingCriteria.first, contains('Minimum land area'));
    });

    test('checks max land area correctly', () {
      final scheme = Scheme(
        id: 1,
        name: 'Test',
        description: 'Test',
        eligibilityCriteria: {'max_land_area': 3.0},
      );

      // Total area = 3.5
      var result = EligibilityService.checkEligibility(scheme, user, [field1, field2]);
      expect(result.status, EligibilityStatus.notEligible);

      // Total area = 2.5
      result = EligibilityService.checkEligibility(scheme, user, [field1]);
      expect(result.status, EligibilityStatus.eligible);
    });

    test('checks allowed crops correctly', () {
      final scheme = Scheme(
        id: 1,
        name: 'Test',
        description: 'Test',
        eligibilityCriteria: {'allowed_crops': ['Wheat', 'Corn']},
      );

      // Has Wheat
      var result = EligibilityService.checkEligibility(scheme, user, [field1]);
      expect(result.status, EligibilityStatus.eligible);

      // Has Rice only
      result = EligibilityService.checkEligibility(scheme, user, [field2]);
      expect(result.status, EligibilityStatus.notEligible);
      expect(result.missingCriteria.first, contains('Required crops'));
    });

    test('checks allowed states correctly', () {
      final scheme = Scheme(
        id: 1,
        name: 'Test',
        description: 'Test',
        eligibilityCriteria: {'allowed_states': ['Maharashtra']},
      );

      var result = EligibilityService.checkEligibility(scheme, user, []);
      expect(result.status, EligibilityStatus.eligible);

      final userGujarat = user.copyWith(address: 'Ahmedabad, Gujarat');
      result = EligibilityService.checkEligibility(scheme, userGujarat, []);
      expect(result.status, EligibilityStatus.notEligible);
    });
  });
}
