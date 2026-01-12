import 'package:flutter/foundation.dart';
import 'package:kheti_sahayak_app/models/learning_module.dart';
import 'package:kheti_sahayak_app/models/quiz.dart';
import 'package:kheti_sahayak_app/models/user_progress.dart';
import 'package:kheti_sahayak_app/services/learning_service.dart';

/// Provider for managing learning modules, quizzes, and user progress
class LearningProvider with ChangeNotifier {
  final LearningService _service = LearningService();

  // State
  List<LearningModule> _modules = [];
  List<ModuleCategory> _categories = [];
  UserProgress? _userProgress;
  LearningModule? _currentModule;
  Quiz? _currentQuiz;
  bool _isLoading = false;
  String? _error;

  // Quiz state
  int _currentQuestionIndex = 0;
  Map<int, List<int>> _selectedAnswers = {};
  DateTime? _quizStartTime;
  bool _quizSubmitted = false;
  QuizAttempt? _lastQuizAttempt;

  // Getters
  List<LearningModule> get modules => [..._modules];
  List<ModuleCategory> get categories => [..._categories];
  UserProgress? get userProgress => _userProgress;
  LearningModule? get currentModule => _currentModule;
  Quiz? get currentQuiz => _currentQuiz;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, List<int>> get selectedAnswers => {..._selectedAnswers};
  bool get quizSubmitted => _quizSubmitted;
  QuizAttempt? get lastQuizAttempt => _lastQuizAttempt;

  QuizQuestion? get currentQuestion {
    if (_currentQuiz == null ||
        _currentQuestionIndex >= _currentQuiz!.questions.length) {
      return null;
    }
    return _currentQuiz!.questions[_currentQuestionIndex];
  }

  bool get isLastQuestion {
    if (_currentQuiz == null) return true;
    return _currentQuestionIndex >= _currentQuiz!.questions.length - 1;
  }

  int get answeredCount => _selectedAnswers.length;

  double get quizProgress {
    if (_currentQuiz == null || _currentQuiz!.questions.isEmpty) return 0;
    return (_currentQuestionIndex + 1) / _currentQuiz!.questions.length;
  }

  // Initialize provider
  Future<void> initialize() async {
    await Future.wait([
      loadModules(),
      loadUserProgress(),
      loadCategories(),
    ]);
  }

  // Load all learning modules
  Future<void> loadModules({String? category, String? difficulty}) async {
    _setLoading(true);
    try {
      _modules = await _service.getModules(
        category: category,
        difficulty: difficulty,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load modules: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Load module categories
  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  // Load user progress
  Future<void> loadUserProgress() async {
    try {
      _userProgress = await _service.getUserProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load user progress: $e');
    }
  }

  // Load specific module details
  Future<void> loadModuleDetails(int moduleId) async {
    _setLoading(true);
    try {
      _currentModule = await _service.getModuleDetails(moduleId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load module: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Mark lesson as completed
  Future<void> completeLesson(int lessonId) async {
    if (_currentModule == null) return;

    try {
      await _service.markLessonComplete(lessonId, _currentModule!.id);

      // Update local state
      final updatedLessons = _currentModule!.lessons.map((lesson) {
        if (lesson.id == lessonId) {
          return lesson.copyWith(isCompleted: true);
        }
        return lesson;
      }).toList();

      _currentModule = _currentModule!.copyWith(lessons: updatedLessons);

      // Award points
      await _awardPoints(10, 'lesson_complete');

      // Check if module is completed
      if (_currentModule!.isCompleted) {
        await _onModuleCompleted();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to complete lesson: $e');
    }
  }

  // Start quiz
  void startQuiz(Quiz quiz) {
    _currentQuiz = quiz;
    _currentQuestionIndex = 0;
    _selectedAnswers = {};
    _quizStartTime = DateTime.now();
    _quizSubmitted = false;
    _lastQuizAttempt = null;
    notifyListeners();
  }

  // Select answer for current question
  void selectAnswer(int optionId) {
    if (_currentQuiz == null || currentQuestion == null || _quizSubmitted) {
      return;
    }

    final questionId = currentQuestion!.id;

    if (currentQuestion!.type == QuestionType.multipleChoice) {
      // Toggle selection for multiple choice
      final currentSelection = _selectedAnswers[questionId] ?? [];
      if (currentSelection.contains(optionId)) {
        currentSelection.remove(optionId);
      } else {
        currentSelection.add(optionId);
      }
      _selectedAnswers[questionId] = currentSelection;
    } else {
      // Single selection
      _selectedAnswers[questionId] = [optionId];
    }

    notifyListeners();
  }

  // Navigate to next question
  void nextQuestion() {
    if (_currentQuiz == null) return;
    if (_currentQuestionIndex < _currentQuiz!.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  // Navigate to previous question
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  // Jump to specific question
  void goToQuestion(int index) {
    if (_currentQuiz == null) return;
    if (index >= 0 && index < _currentQuiz!.questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  // Submit quiz
  Future<QuizAttempt> submitQuiz() async {
    if (_currentQuiz == null) {
      throw Exception('No quiz in progress');
    }

    final timeTaken = _quizStartTime != null
        ? DateTime.now().difference(_quizStartTime!).inSeconds
        : 0;

    // Calculate score
    int totalScore = 0;
    int totalPoints = _currentQuiz!.totalPoints;
    final List<QuestionAnswer> answers = [];

    for (final question in _currentQuiz!.questions) {
      final selectedIds = _selectedAnswers[question.id] ?? [];
      final isCorrect = question.isCorrect(selectedIds);
      final pointsEarned = isCorrect ? question.points : 0;
      totalScore += pointsEarned;

      answers.add(QuestionAnswer(
        questionId: question.id,
        selectedOptionIds: selectedIds,
        isCorrect: isCorrect,
        pointsEarned: pointsEarned,
      ));
    }

    final passed =
        (totalScore / totalPoints) * 100 >= _currentQuiz!.passingScore;

    // Save attempt
    final attempt = await _service.submitQuizAttempt(
      quizId: _currentQuiz!.id,
      moduleId: _currentModule?.id ?? 0,
      score: totalScore,
      totalPoints: totalPoints,
      passed: passed,
      timeTaken: timeTaken,
      answers: answers,
    );

    _lastQuizAttempt = attempt;
    _quizSubmitted = true;

    // Award points for passing
    if (passed) {
      await _awardPoints(50, 'quiz_passed');
      await _checkForBadges();
    }

    notifyListeners();
    return attempt;
  }

  // Reset quiz
  void resetQuiz() {
    _currentQuiz = null;
    _currentQuestionIndex = 0;
    _selectedAnswers = {};
    _quizStartTime = null;
    _quizSubmitted = false;
    _lastQuizAttempt = null;
    notifyListeners();
  }

  // Download module for offline use
  Future<void> downloadModule(int moduleId) async {
    try {
      await _service.downloadModule(moduleId);

      // Update local state
      final index = _modules.indexWhere((m) => m.id == moduleId);
      if (index >= 0) {
        _modules[index] = _modules[index].copyWith(isDownloaded: true);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to download module: $e';
      notifyListeners();
    }
  }

  // Remove downloaded module
  Future<void> removeDownloadedModule(int moduleId) async {
    try {
      await _service.removeDownloadedModule(moduleId);

      final index = _modules.indexWhere((m) => m.id == moduleId);
      if (index >= 0) {
        _modules[index] = _modules[index].copyWith(isDownloaded: false);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to remove download: $e');
    }
  }

  // Get modules filtered by various criteria
  List<LearningModule> getFilteredModules({
    String? category,
    String? difficulty,
    bool? downloadedOnly,
    bool? inProgressOnly,
    bool? completedOnly,
  }) {
    return _modules.where((module) {
      if (category != null && module.category != category) return false;
      if (difficulty != null && module.difficulty != difficulty) return false;
      if (downloadedOnly == true && !module.isDownloaded) return false;
      if (inProgressOnly == true &&
          (module.progress == 0 || module.isCompleted)) {
        return false;
      }
      if (completedOnly == true && !module.isCompleted) return false;
      return true;
    }).toList();
  }

  // Get recommended modules based on progress
  List<LearningModule> getRecommendedModules({int limit = 5}) {
    // Priority: In-progress > Not started > Completed
    final inProgress =
        _modules.where((m) => m.progress > 0 && !m.isCompleted).toList();
    final notStarted = _modules.where((m) => m.progress == 0).toList();

    final recommended = [...inProgress, ...notStarted];
    return recommended.take(limit).toList();
  }

  // Private methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _awardPoints(int points, String reason) async {
    try {
      await _service.awardPoints(points, reason);
      await loadUserProgress();
    } catch (e) {
      debugPrint('Failed to award points: $e');
    }
  }

  Future<void> _checkForBadges() async {
    try {
      final newBadges = await _service.checkForNewBadges();
      if (newBadges.isNotEmpty) {
        await loadUserProgress();
      }
    } catch (e) {
      debugPrint('Failed to check badges: $e');
    }
  }

  Future<void> _onModuleCompleted() async {
    if (_currentModule == null) return;

    try {
      // Award completion points
      await _awardPoints(_currentModule!.pointsReward, 'module_complete');

      // Generate certificate if quiz passed
      if (_lastQuizAttempt?.passed == true) {
        await _service.generateCertificate(_currentModule!.id);
      }

      await _checkForBadges();
      await loadUserProgress();
    } catch (e) {
      debugPrint('Error on module completion: $e');
    }
  }

  // Clear state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentModule() {
    _currentModule = null;
    _currentQuiz = null;
    resetQuiz();
    notifyListeners();
  }
}
