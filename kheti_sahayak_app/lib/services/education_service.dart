import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/course.dart';
import 'package:kheti_sahayak_app/models/module.dart';
import 'package:kheti_sahayak_app/models/lesson.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EducationService {
  static DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static http.Client _client = http.Client();

  // For testing
  static void setHelpers({DatabaseHelper? dbHelper, http.Client? client}) {
    if (dbHelper != null) _dbHelper = dbHelper;
    if (client != null) _client = client;
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get courses (Offline First)
  static Future<List<Course>> getCourses() async {
    try {
      // 1. Try to fetch from API
      final token = await _getToken();
      if (token != null) {
        final response = await _client.get(
          Uri.parse('${Constants.baseUrl}/api/courses'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> items = data['data'];
            // We don't cache everything here, just basic info
            // Full caching happens on "Download Course" or viewing details
            return items.map((item) => Course.fromJson(item)).toList();
          }
        }
      }
    } catch (e) {
      print('Error fetching courses from API: $e');
    }

    // 2. Fallback to cache
    final cached = await _dbHelper.getCachedCourses();
    return cached.map((map) => Course.fromJson(map)).toList();
  }

  /// Get course details with modules and lessons (Offline First)
  static Future<Course?> getCourseDetails(int courseId) async {
    try {
      // 1. Try to fetch from API
      final token = await _getToken();
      if (token != null) {
        final response = await _client.get(
          Uri.parse('${Constants.baseUrl}/api/courses/$courseId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final courseData = data['data'];
            final course = Course.fromJson(courseData);
            
            // Cache it
            await _cacheCourseStructure(course);
            
            return course;
          }
        }
      }
    } catch (e) {
      print('Error fetching course details from API: $e');
    }

    // 2. Fallback to cache
    return await _loadCourseFromCache(courseId);
  }

  static Future<void> _cacheCourseStructure(Course course) async {
    final List<Map<String, dynamic>> modules = [];
    final List<Map<String, dynamic>> lessons = [];

    for (var module in course.modules) {
      modules.add(module.toJson());
      for (var lesson in module.lessons) {
        lessons.add(lesson.toJson());
      }
    }

    await _dbHelper.cacheCourse(course.toJson(), modules, lessons);
  }

  static Future<Course?> _loadCourseFromCache(int courseId) async {
    final cachedCourses = await _dbHelper.getCachedCourses();
    final courseMap = cachedCourses.firstWhere((c) => c['id'] == courseId, orElse: () => {});
    
    if (courseMap.isEmpty) return null;

    final cachedModules = await _dbHelper.getCachedModules(courseId);
    final List<Module> modules = [];

    for (var moduleMap in cachedModules) {
      final cachedLessons = await _dbHelper.getCachedLessons(moduleMap['id']);
      final lessons = cachedLessons.map((l) => Lesson.fromJson(l)).toList();
      
      // Update completion status from progress table
      final progress = await _dbHelper.getCourseProgress(courseId);
      final updatedLessons = lessons.map((l) {
        return Lesson(
          id: l.id,
          moduleId: l.moduleId,
          title: l.title,
          type: l.type,
          contentUrl: l.contentUrl,
          localContentPath: l.localContentPath,
          duration: l.duration,
          isCompleted: progress[l.id] ?? false,
        );
      }).toList();

      modules.add(Module(
        id: moduleMap['id'],
        courseId: moduleMap['course_id'],
        title: moduleMap['title'],
        order: moduleMap['order_index'],
        lessons: updatedLessons,
      ));
    }

    return Course(
      id: courseMap['id'],
      title: courseMap['title'],
      description: courseMap['description'],
      thumbnailUrl: courseMap['thumbnail_url'],
      language: courseMap['language'],
      difficulty: courseMap['difficulty'],
      totalLessons: courseMap['total_lessons'],
      modules: modules,
    );
  }

  /// Mark lesson as completed
  static Future<void> markLessonComplete(int lessonId, int courseId) async {
    await _dbHelper.markLessonCompleted(lessonId, courseId);
    // TODO: Sync progress to backend
  }
}
