import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/services/document_checklist_service.dart';

void main() {
  group('DocumentChecklistService Tests', () {
    test('getChecklistForScheme returns required documents if present', () {
      final scheme = Scheme(
        id: 1,
        name: 'Test Scheme',
        description: 'Test Description',
        requiredDocuments: ['Doc A', 'Doc B'],
      );

      final checklist = DocumentChecklistService.getChecklistForScheme(scheme);
      expect(checklist, ['Doc A', 'Doc B']);
    });

    test('getChecklistForScheme returns fallback for Kisan schemes', () {
      final scheme = Scheme(
        id: 2,
        name: 'PM Kisan Scheme',
        description: 'Test Description',
        requiredDocuments: [],
      );

      final checklist = DocumentChecklistService.getChecklistForScheme(scheme);
      expect(checklist, contains('Land Record (7/12 Extract)'));
    });

    test('getAutoFilledData returns correct user data', () {
      final user = User(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        phoneNumber: '1234567890',
        address: 'Test Address',
        createdAt: DateTime.now(),
      );

      final data = DocumentChecklistService.getAutoFilledData(user);
      expect(data['Full Name'], 'Test User');
      expect(data['Mobile Number'], '1234567890');
      expect(data['Address'], 'Test Address');
      expect(data['Email'], 'test@example.com');
    });
  });
}
