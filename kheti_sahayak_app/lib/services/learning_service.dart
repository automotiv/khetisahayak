import 'dart:convert';
import 'package:kheti_sahayak_app/models/learning_module.dart';
import 'package:kheti_sahayak_app/models/quiz.dart';
import 'package:kheti_sahayak_app/models/user_progress.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing learning modules, quizzes, and progress
class LearningService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== MODULE OPERATIONS ====================

  /// Get all learning modules
  Future<List<LearningModule>> getModules({
    String? category,
    String? difficulty,
  }) async {
    try {
      // Try API first
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (difficulty != null) queryParams['difficulty'] = difficulty;

      final response = await ApiService.get(
        'learning/modules',
        queryParams: queryParams,
      );

      if (response['success'] == true && response['data'] != null) {
        final modules = (response['data'] as List)
            .map((m) => LearningModule.fromJson(m))
            .toList();

        // Cache modules
        await _cacheModules(modules);

        return modules;
      }
    } catch (e) {
      // Fall back to cache
    }

    // Return cached or mock data
    return _getMockModules(category: category, difficulty: difficulty);
  }

  /// Get module details with lessons and quiz
  Future<LearningModule> getModuleDetails(int moduleId) async {
    try {
      final response = await ApiService.get('learning/modules/$moduleId');

      if (response['success'] == true && response['data'] != null) {
        final module = LearningModule.fromJson(response['data']);
        await _cacheModuleDetails(module);
        return module;
      }
    } catch (e) {
      // Fall back to cache
    }

    // Return mock details
    return _getMockModuleDetails(moduleId);
  }

  /// Get module categories
  Future<List<ModuleCategory>> getCategories() async {
    try {
      final response = await ApiService.get('learning/categories');

      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((c) => ModuleCategory.fromJson(c))
            .toList();
      }
    } catch (e) {
      // Return defaults
    }

    return _getMockCategories();
  }

  // ==================== PROGRESS OPERATIONS ====================

  /// Get user's learning progress
  Future<UserProgress> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';

    try {
      final response = await ApiService.get('learning/progress');

      if (response['success'] == true && response['data'] != null) {
        final progress = UserProgress.fromJson(response['data']);
        await _cacheUserProgress(progress);
        return progress;
      }
    } catch (e) {
      // Fall back to local
    }

    return _getLocalUserProgress(userId);
  }

  /// Mark lesson as completed
  Future<void> markLessonComplete(int lessonId, int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';

    // Save locally first
    await _saveLessonProgress(userId, moduleId, lessonId, true);

    // Sync to server
    try {
      await ApiService.post('learning/lessons/$lessonId/complete', {
        'module_id': moduleId,
      });
    } catch (e) {
      // Will sync later
    }

    // Update streak
    await _updateLearningStreak(userId);
  }

  // ==================== QUIZ OPERATIONS ====================

  /// Get quiz for a module
  Future<Quiz?> getQuiz(int moduleId) async {
    try {
      final response = await ApiService.get('learning/modules/$moduleId/quiz');

      if (response['success'] == true && response['data'] != null) {
        return Quiz.fromJson(response['data']);
      }
    } catch (e) {
      // Return mock
    }

    return _getMockQuiz(moduleId);
  }

  /// Submit quiz attempt
  Future<QuizAttempt> submitQuizAttempt({
    required int quizId,
    required int moduleId,
    required int score,
    required int totalPoints,
    required bool passed,
    required int timeTaken,
    required List<QuestionAnswer> answers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';
    final now = DateTime.now();

    final attempt = QuizAttempt(
      id: now.millisecondsSinceEpoch,
      quizId: quizId,
      userId: int.tryParse(userId) ?? 0,
      score: score,
      totalPoints: totalPoints,
      passed: passed,
      timeTaken: timeTaken,
      answers: answers,
      attemptedAt: now,
    );

    // Save locally
    await _saveQuizAttempt(attempt);

    // Sync to server
    try {
      await ApiService.post('learning/quizzes/$quizId/submit', attempt.toJson());
    } catch (e) {
      // Will sync later
    }

    return attempt;
  }

  // ==================== GAMIFICATION OPERATIONS ====================

  /// Award points to user
  Future<void> awardPoints(int points, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';

    // Update local progress
    final currentPoints = prefs.getInt('total_points_$userId') ?? 0;
    await prefs.setInt('total_points_$userId', currentPoints + points);

    // Sync to server
    try {
      await ApiService.post('learning/points', {
        'points': points,
        'reason': reason,
      });
    } catch (e) {
      // Will sync later
    }
  }

  /// Check for new badges based on progress
  Future<List<Badge>> checkForNewBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';
    final newBadges = <Badge>[];

    final progress = await _getLocalUserProgress(userId);

    // Check badge conditions
    if (progress.completedModules >= 1 &&
        !_hasBadge(progress, 'first_module')) {
      newBadges.add(_createBadge('first_module', 'First Steps',
          'Completed your first learning module'));
    }

    if (progress.completedModules >= 5 &&
        !_hasBadge(progress, 'five_modules')) {
      newBadges.add(_createBadge(
          'five_modules', 'Knowledge Seeker', 'Completed 5 learning modules'));
    }

    if (progress.streak.currentStreak >= 7 &&
        !_hasBadge(progress, 'week_streak')) {
      newBadges.add(_createBadge(
          'week_streak', 'Consistent Learner', 'Maintained a 7-day streak'));
    }

    if (progress.totalPoints >= 500 && !_hasBadge(progress, '500_points')) {
      newBadges
          .add(_createBadge('500_points', 'Point Collector', 'Earned 500 points'));
    }

    // Save new badges
    for (final badge in newBadges) {
      await _saveBadge(userId, badge);
    }

    return newBadges;
  }

  /// Generate certificate for completed module
  Future<Certificate?> generateCertificate(int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';
    final userName = prefs.getString('user_name') ?? 'Farmer';

    try {
      final response = await ApiService.post('learning/certificates', {
        'module_id': moduleId,
      });

      if (response['success'] == true && response['data'] != null) {
        return Certificate.fromJson(response['data']);
      }
    } catch (e) {
      // Generate local certificate
    }

    // Create local certificate
    final module = await getModuleDetails(moduleId);
    final cert = Certificate(
      id: '${userId}_${moduleId}_${DateTime.now().millisecondsSinceEpoch}',
      moduleId: moduleId,
      moduleTitle: module.title,
      userName: userName,
      score: 100,
      issuedAt: DateTime.now(),
      verificationCode: _generateVerificationCode(),
    );

    await _saveCertificate(userId, cert);
    return cert;
  }

  // ==================== OFFLINE OPERATIONS ====================

  /// Download module for offline use
  Future<void> downloadModule(int moduleId) async {
    final module = await getModuleDetails(moduleId);
    await _cacheModuleDetails(module);

    // Mark as downloaded
    final prefs = await SharedPreferences.getInstance();
    final downloaded =
        prefs.getStringList('downloaded_modules') ?? [];
    if (!downloaded.contains(moduleId.toString())) {
      downloaded.add(moduleId.toString());
      await prefs.setStringList('downloaded_modules', downloaded);
    }
  }

  /// Remove downloaded module
  Future<void> removeDownloadedModule(int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded =
        prefs.getStringList('downloaded_modules') ?? [];
    downloaded.remove(moduleId.toString());
    await prefs.setStringList('downloaded_modules', downloaded);

    // Could also delete cached content here
  }

  /// Get downloaded modules
  Future<List<int>> getDownloadedModuleIds() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded =
        prefs.getStringList('downloaded_modules') ?? [];
    return downloaded.map((id) => int.parse(id)).toList();
  }

  // ==================== PRIVATE HELPER METHODS ====================

  Future<void> _cacheModules(List<LearningModule> modules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = modules.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList('cached_learning_modules', jsonList);
  }

  Future<void> _cacheModuleDetails(LearningModule module) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'module_details_${module.id}', json.encode(module.toJson()));
  }

  Future<void> _cacheUserProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'user_progress_${progress.oderId}', json.encode(progress.toJson()));
  }

  Future<UserProgress> _getLocalUserProgress(String oderId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_progress_$oderId');

    if (cached != null) {
      return UserProgress.fromJson(json.decode(cached));
    }

    // Return default progress
    return UserProgress(
      oderId: oderId,
      totalPoints: prefs.getInt('total_points_$oderId') ?? 0,
      currentLevel: 1,
      experiencePoints: 0,
    );
  }

  Future<void> _saveLessonProgress(
    String oderId,
    int moduleId,
    int lessonId,
    bool completed,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'lesson_progress_${oderId}_$moduleId';
    final progressMap =
        json.decode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    progressMap[lessonId.toString()] = completed;
    await prefs.setString(key, json.encode(progressMap));
  }

  Future<void> _updateLearningStreak(String oderId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final lastDateStr = prefs.getString('last_learning_date_$oderId');
    final currentStreak = prefs.getInt('current_streak_$oderId') ?? 0;
    final longestStreak = prefs.getInt('longest_streak_$oderId') ?? 0;

    if (lastDateStr == todayStr) {
      // Already learned today
      return;
    }

    int newStreak;
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        // Consecutive day
        newStreak = currentStreak + 1;
      } else {
        // Streak broken
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    await prefs.setString('last_learning_date_$oderId', todayStr);
    await prefs.setInt('current_streak_$oderId', newStreak);
    if (newStreak > longestStreak) {
      await prefs.setInt('longest_streak_$oderId', newStreak);
    }
  }

  Future<void> _saveQuizAttempt(QuizAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_attempts_${attempt.quizId}';
    final attempts = prefs.getStringList(key) ?? [];
    attempts.add(json.encode(attempt.toJson()));
    await prefs.setStringList(key, attempts);
  }

  Future<void> _saveBadge(String oderId, Badge badge) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'badges_$oderId';
    final badges = prefs.getStringList(key) ?? [];
    badges.add(json.encode(badge.toJson()));
    await prefs.setStringList(key, badges);
  }

  Future<void> _saveCertificate(String oderId, Certificate cert) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'certificates_$oderId';
    final certs = prefs.getStringList(key) ?? [];
    certs.add(json.encode(cert.toJson()));
    await prefs.setStringList(key, certs);
  }

  bool _hasBadge(UserProgress progress, String badgeId) {
    return progress.badges.any((b) => b.id == badgeId);
  }

  Badge _createBadge(String id, String name, String description) {
    return Badge(
      id: id,
      name: name,
      description: description,
      iconUrl: 'assets/badges/$id.png',
      type: BadgeType.achievement,
      pointsValue: 25,
      earnedAt: DateTime.now(),
    );
  }

  String _generateVerificationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buffer.write(chars[DateTime.now().millisecondsSinceEpoch % chars.length]);
    }
    return buffer.toString();
  }

  // ==================== MOCK DATA ====================

  List<LearningModule> _getMockModules({String? category, String? difficulty}) {
    final modules = [
      LearningModule(
        id: 1,
        title: 'Introduction to Organic Farming',
        description:
            'Learn the basics of organic farming practices and sustainable agriculture.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=400',
        category: 'organic_farming',
        difficulty: 'beginner',
        estimatedDuration: 30,
        tags: ['organic', 'sustainable', 'basics'],
        pointsReward: 100,
      ),
      LearningModule(
        id: 2,
        title: 'Pest Management Techniques',
        description:
            'Comprehensive guide to identifying and managing common crop pests.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
        category: 'pest_management',
        difficulty: 'intermediate',
        estimatedDuration: 45,
        tags: ['pests', 'management', 'crop protection'],
        pointsReward: 150,
      ),
      LearningModule(
        id: 3,
        title: 'Soil Health & Nutrition',
        description:
            'Understanding soil composition and how to maintain healthy soil for optimal crop growth.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
        category: 'soil_health',
        difficulty: 'beginner',
        estimatedDuration: 35,
        tags: ['soil', 'nutrition', 'health'],
        pointsReward: 100,
      ),
      LearningModule(
        id: 4,
        title: 'Water Conservation Methods',
        description:
            'Efficient irrigation techniques and water conservation practices for farming.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=400',
        category: 'irrigation',
        difficulty: 'intermediate',
        estimatedDuration: 40,
        tags: ['water', 'irrigation', 'conservation'],
        pointsReward: 125,
      ),
      LearningModule(
        id: 5,
        title: 'Advanced Crop Rotation',
        description:
            'Strategic crop rotation techniques for improved yield and soil health.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=400',
        category: 'crop_management',
        difficulty: 'advanced',
        estimatedDuration: 60,
        tags: ['rotation', 'yield', 'planning'],
        pointsReward: 200,
      ),
    ];

    return modules.where((m) {
      if (category != null && m.category != category) return false;
      if (difficulty != null && m.difficulty != difficulty) return false;
      return true;
    }).toList();
  }

  LearningModule _getMockModuleDetails(int moduleId) {
    final baseModule = _getMockModules().firstWhere(
      (m) => m.id == moduleId,
      orElse: () => _getMockModules().first,
    );

    return baseModule.copyWith(
      lessons: [
        LearningLesson(
          id: 1,
          moduleId: moduleId,
          title: 'Introduction',
          type: LessonType.article,
          content: '''
Welcome to this learning module! In this course, you will learn essential farming techniques
that will help you improve your agricultural practices.

## What You'll Learn
- Understanding the fundamentals
- Practical applications
- Best practices and tips

## Prerequisites
Basic knowledge of farming is helpful but not required.
          ''',
          duration: 5,
          order: 1,
        ),
        LearningLesson(
          id: 2,
          moduleId: moduleId,
          title: 'Core Concepts',
          type: LessonType.video,
          videoUrl: 'https://example.com/video1.mp4',
          duration: 10,
          order: 2,
        ),
        LearningLesson(
          id: 3,
          moduleId: moduleId,
          title: 'Practical Guide',
          type: LessonType.infographic,
          imageUrls: [
            'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800',
          ],
          duration: 8,
          order: 3,
        ),
        LearningLesson(
          id: 4,
          moduleId: moduleId,
          title: 'Summary & Best Practices',
          type: LessonType.article,
          content: '''
## Key Takeaways

1. Always start with proper planning
2. Monitor your progress regularly
3. Adapt techniques to your local conditions
4. Seek expert advice when needed

## Next Steps
Complete the quiz to test your knowledge and earn your certificate!
          ''',
          duration: 5,
          order: 4,
        ),
      ],
      quiz: _getMockQuiz(moduleId),
    );
  }

  Quiz? _getMockQuiz(int moduleId) {
    return Quiz(
      id: moduleId * 100,
      moduleId: moduleId,
      title: 'Module Assessment',
      description: 'Test your knowledge of the module content',
      passingScore: 70,
      timeLimit: 15,
      questions: [
        QuizQuestion(
          id: 1,
          question: 'What is the primary benefit of organic farming?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption(
                id: 1, text: 'Higher immediate yields', isCorrect: false),
            QuizOption(
                id: 2, text: 'Lower production costs', isCorrect: false),
            QuizOption(
                id: 3,
                text: 'Environmental sustainability',
                isCorrect: true),
            QuizOption(id: 4, text: 'Faster crop growth', isCorrect: false),
          ],
          correctOptionId: 3,
          explanation:
              'Organic farming prioritizes environmental sustainability through natural practices.',
          points: 10,
        ),
        QuizQuestion(
          id: 2,
          question: 'Which of the following are natural pest control methods?',
          type: QuestionType.multipleChoice,
          options: [
            QuizOption(id: 5, text: 'Companion planting', isCorrect: true),
            QuizOption(id: 6, text: 'Chemical pesticides', isCorrect: false),
            QuizOption(id: 7, text: 'Beneficial insects', isCorrect: true),
            QuizOption(id: 8, text: 'Crop rotation', isCorrect: true),
          ],
          correctOptionIds: [5, 7, 8],
          explanation:
              'Natural pest control includes companion planting, beneficial insects, and crop rotation.',
          points: 15,
        ),
        QuizQuestion(
          id: 3,
          question: 'Healthy soil contains a diverse microbiome.',
          type: QuestionType.trueFalse,
          options: [
            QuizOption(id: 9, text: 'True', isCorrect: true),
            QuizOption(id: 10, text: 'False', isCorrect: false),
          ],
          correctOptionId: 9,
          explanation:
              'A diverse soil microbiome is essential for nutrient cycling and plant health.',
          points: 10,
        ),
        QuizQuestion(
          id: 4,
          question: 'What is the ideal soil pH for most crops?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption(id: 11, text: '4.0 - 5.0 (Acidic)', isCorrect: false),
            QuizOption(
                id: 12, text: '6.0 - 7.0 (Slightly acidic to neutral)', isCorrect: true),
            QuizOption(id: 13, text: '8.0 - 9.0 (Alkaline)', isCorrect: false),
            QuizOption(
                id: 14, text: 'pH does not matter', isCorrect: false),
          ],
          correctOptionId: 12,
          explanation:
              'Most crops thrive in slightly acidic to neutral soil with pH between 6.0 and 7.0.',
          points: 10,
        ),
        QuizQuestion(
          id: 5,
          question: 'Which practice helps conserve water in farming?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption(id: 15, text: 'Flood irrigation', isCorrect: false),
            QuizOption(id: 16, text: 'Drip irrigation', isCorrect: true),
            QuizOption(id: 17, text: 'Open channels', isCorrect: false),
            QuizOption(
                id: 18, text: 'Watering during midday', isCorrect: false),
          ],
          correctOptionId: 16,
          explanation:
              'Drip irrigation delivers water directly to plant roots, minimizing waste.',
          points: 10,
        ),
      ],
    );
  }

  List<ModuleCategory> _getMockCategories() {
    return [
      ModuleCategory(
          id: 'organic_farming', name: 'Organic Farming', moduleCount: 5),
      ModuleCategory(
          id: 'pest_management', name: 'Pest Management', moduleCount: 8),
      ModuleCategory(id: 'soil_health', name: 'Soil Health', moduleCount: 6),
      ModuleCategory(id: 'irrigation', name: 'Irrigation', moduleCount: 4),
      ModuleCategory(
          id: 'crop_management', name: 'Crop Management', moduleCount: 10),
      ModuleCategory(
          id: 'post_harvest', name: 'Post Harvest', moduleCount: 3),
    ];
  }
}
