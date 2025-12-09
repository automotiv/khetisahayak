import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/services/education_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/models/course.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Generate mocks
@GenerateMocks([DatabaseHelper, http.Client])
import 'education_service_test.mocks.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockClient mockClient;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockClient = MockClient();
    EducationService.setHelpers(dbHelper: mockDbHelper, client: mockClient);
    SharedPreferences.setMockInitialValues({'auth_token': 'test_token'});
  });

  group('EducationService', () {
    test('getCourses returns list of courses from API when successful', () async {
      final mockCourses = [
        {
          'id': 1,
          'title': 'Test Course',
          'description': 'Description',
          'thumbnail_url': 'url',
          'language': 'en',
          'difficulty': 'easy',
          'total_lessons': 10,
        }
      ];

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode({'success': true, 'data': mockCourses}),
                200,
              ));

      final courses = await EducationService.getCourses();

      expect(courses, isA<List<Course>>());
      expect(courses.length, 1);
      expect(courses.first.title, 'Test Course');
    });

    test('getCourses falls back to cache when API fails', () async {
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('Error', 500));

      when(mockDbHelper.getCachedCourses()).thenAnswer((_) async => [
            {
              'id': 1,
              'title': 'Cached Course',
              'description': 'Description',
              'thumbnail_url': 'url',
              'language': 'en',
              'difficulty': 'easy',
              'total_lessons': 10,
              'cached_at': DateTime.now().toIso8601String(),
            }
          ]);

      final courses = await EducationService.getCourses();

      expect(courses, isA<List<Course>>());
      expect(courses.first.title, 'Cached Course');
    });
  });
}
