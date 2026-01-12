/// Quiz model for interactive learning modules
class Quiz {
  final int id;
  final int moduleId;
  final String title;
  final String? description;
  final List<QuizQuestion> questions;
  final int passingScore; // Percentage required to pass (0-100)
  final int timeLimit; // In minutes, 0 for no limit
  final int maxAttempts; // 0 for unlimited

  Quiz({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    required this.questions,
    this.passingScore = 70,
    this.timeLimit = 0,
    this.maxAttempts = 0,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      moduleId: json['module_id'],
      title: json['title'],
      description: json['description'],
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => QuizQuestion.fromJson(q))
              .toList()
          : [],
      passingScore: json['passing_score'] ?? 70,
      timeLimit: json['time_limit'] ?? 0,
      maxAttempts: json['max_attempts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'passing_score': passingScore,
      'time_limit': timeLimit,
      'max_attempts': maxAttempts,
    };
  }

  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
}

/// Individual quiz question
class QuizQuestion {
  final int id;
  final String question;
  final QuestionType type;
  final List<QuizOption> options;
  final String? explanation;
  final String? imageUrl;
  final int points;
  final int? correctOptionId; // For single choice
  final List<int>? correctOptionIds; // For multiple choice

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    this.explanation,
    this.imageUrl,
    this.points = 1,
    this.correctOptionId,
    this.correctOptionIds,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      type: QuestionType.fromString(json['type'] ?? 'single_choice'),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => QuizOption.fromJson(o))
              .toList()
          : [],
      explanation: json['explanation'],
      imageUrl: json['image_url'],
      points: json['points'] ?? 1,
      correctOptionId: json['correct_option_id'],
      correctOptionIds: json['correct_option_ids'] != null
          ? List<int>.from(json['correct_option_ids'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.value,
      'options': options.map((o) => o.toJson()).toList(),
      'explanation': explanation,
      'image_url': imageUrl,
      'points': points,
      'correct_option_id': correctOptionId,
      'correct_option_ids': correctOptionIds,
    };
  }

  bool isCorrect(List<int> selectedOptionIds) {
    switch (type) {
      case QuestionType.singleChoice:
        return selectedOptionIds.length == 1 &&
            selectedOptionIds.first == correctOptionId;
      case QuestionType.multipleChoice:
        if (correctOptionIds == null) return false;
        final sortedSelected = [...selectedOptionIds]..sort();
        final sortedCorrect = [...correctOptionIds!]..sort();
        return sortedSelected.length == sortedCorrect.length &&
            sortedSelected.every((id) => sortedCorrect.contains(id));
      case QuestionType.trueFalse:
        return selectedOptionIds.length == 1 &&
            selectedOptionIds.first == correctOptionId;
    }
  }
}

/// Quiz option/answer choice
class QuizOption {
  final int id;
  final String text;
  final String? imageUrl;
  final bool isCorrect;

  QuizOption({
    required this.id,
    required this.text,
    this.imageUrl,
    this.isCorrect = false,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      text: json['text'],
      imageUrl: json['image_url'],
      isCorrect: json['is_correct'] == true || json['is_correct'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'image_url': imageUrl,
      'is_correct': isCorrect,
    };
  }
}

/// Question type enum
enum QuestionType {
  singleChoice('single_choice'),
  multipleChoice('multiple_choice'),
  trueFalse('true_false');

  final String value;
  const QuestionType(this.value);

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuestionType.singleChoice,
    );
  }
}

/// Quiz attempt record
class QuizAttempt {
  final int id;
  final int quizId;
  final int userId;
  final int score;
  final int totalPoints;
  final bool passed;
  final int timeTaken; // In seconds
  final List<QuestionAnswer> answers;
  final DateTime attemptedAt;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalPoints,
    required this.passed,
    this.timeTaken = 0,
    required this.answers,
    required this.attemptedAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quiz_id'],
      userId: json['user_id'],
      score: json['score'],
      totalPoints: json['total_points'],
      passed: json['passed'] == true || json['passed'] == 1,
      timeTaken: json['time_taken'] ?? 0,
      answers: json['answers'] != null
          ? (json['answers'] as List)
              .map((a) => QuestionAnswer.fromJson(a))
              .toList()
          : [],
      attemptedAt: DateTime.parse(json['attempted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'user_id': userId,
      'score': score,
      'total_points': totalPoints,
      'passed': passed,
      'time_taken': timeTaken,
      'answers': answers.map((a) => a.toJson()).toList(),
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }

  double get percentage => totalPoints > 0 ? (score / totalPoints) * 100 : 0;
}

/// Answer to a quiz question
class QuestionAnswer {
  final int questionId;
  final List<int> selectedOptionIds;
  final bool isCorrect;
  final int pointsEarned;

  QuestionAnswer({
    required this.questionId,
    required this.selectedOptionIds,
    required this.isCorrect,
    required this.pointsEarned,
  });

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      questionId: json['question_id'],
      selectedOptionIds: List<int>.from(json['selected_option_ids'] ?? []),
      isCorrect: json['is_correct'] == true || json['is_correct'] == 1,
      pointsEarned: json['points_earned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_option_ids': selectedOptionIds,
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
    };
  }
}
