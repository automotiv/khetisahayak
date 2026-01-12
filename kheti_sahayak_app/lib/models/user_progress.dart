/// User learning progress tracking
class UserProgress {
  final String oderId;
  final int totalPoints;
  final int currentLevel;
  final int experiencePoints;
  final List<Badge> badges;
  final List<Certificate> certificates;
  final List<ModuleProgress> moduleProgress;
  final LearningStreak streak;
  final DateTime? lastActivityDate;

  UserProgress({
    required this.oderId,
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.experiencePoints = 0,
    this.badges = const [],
    this.certificates = const [],
    this.moduleProgress = const [],
    LearningStreak? streak,
    this.lastActivityDate,
  }) : streak = streak ?? LearningStreak();

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      oderId: json['user_id'],
      totalPoints: json['total_points'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
      experiencePoints: json['experience_points'] ?? 0,
      badges: json['badges'] != null
          ? (json['badges'] as List).map((b) => Badge.fromJson(b)).toList()
          : [],
      certificates: json['certificates'] != null
          ? (json['certificates'] as List)
              .map((c) => Certificate.fromJson(c))
              .toList()
          : [],
      moduleProgress: json['module_progress'] != null
          ? (json['module_progress'] as List)
              .map((m) => ModuleProgress.fromJson(m))
              .toList()
          : [],
      streak: json['streak'] != null
          ? LearningStreak.fromJson(json['streak'])
          : LearningStreak(),
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.parse(json['last_activity_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': oderId,
      'total_points': totalPoints,
      'current_level': currentLevel,
      'experience_points': experiencePoints,
      'badges': badges.map((b) => b.toJson()).toList(),
      'certificates': certificates.map((c) => c.toJson()).toList(),
      'module_progress': moduleProgress.map((m) => m.toJson()).toList(),
      'streak': streak.toJson(),
      'last_activity_date': lastActivityDate?.toIso8601String(),
    };
  }

  UserProgress copyWith({
    String? userId,
    int? totalPoints,
    int? currentLevel,
    int? experiencePoints,
    List<Badge>? badges,
    List<Certificate>? certificates,
    List<ModuleProgress>? moduleProgress,
    LearningStreak? streak,
    DateTime? lastActivityDate,
  }) {
    return UserProgress(
      oderId: userId ?? this.oderId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      badges: badges ?? this.badges,
      certificates: certificates ?? this.certificates,
      moduleProgress: moduleProgress ?? this.moduleProgress,
      streak: streak ?? this.streak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  int get completedModules =>
      moduleProgress.where((m) => m.isCompleted).length;
  int get totalBadges => badges.length;
  int get totalCertificates => certificates.length;
  int get pointsToNextLevel => (currentLevel * 100) - experiencePoints;
  double get levelProgress =>
      experiencePoints / (currentLevel * 100).clamp(0, 1);
}

/// Individual module progress
class ModuleProgress {
  final int moduleId;
  final String moduleTitle;
  final double progressPercentage;
  final int lessonsCompleted;
  final int totalLessons;
  final bool quizPassed;
  final int? quizScore;
  final int pointsEarned;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isCompleted;

  ModuleProgress({
    required this.moduleId,
    required this.moduleTitle,
    this.progressPercentage = 0.0,
    this.lessonsCompleted = 0,
    this.totalLessons = 0,
    this.quizPassed = false,
    this.quizScore,
    this.pointsEarned = 0,
    this.startedAt,
    this.completedAt,
    this.isCompleted = false,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['module_id'],
      moduleTitle: json['module_title'] ?? '',
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
      lessonsCompleted: json['lessons_completed'] ?? 0,
      totalLessons: json['total_lessons'] ?? 0,
      quizPassed: json['quiz_passed'] == true || json['quiz_passed'] == 1,
      quizScore: json['quiz_score'],
      pointsEarned: json['points_earned'] ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'module_title': moduleTitle,
      'progress_percentage': progressPercentage,
      'lessons_completed': lessonsCompleted,
      'total_lessons': totalLessons,
      'quiz_passed': quizPassed,
      'quiz_score': quizScore,
      'points_earned': pointsEarned,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_completed': isCompleted,
    };
  }

  ModuleProgress copyWith({
    int? moduleId,
    String? moduleTitle,
    double? progressPercentage,
    int? lessonsCompleted,
    int? totalLessons,
    bool? quizPassed,
    int? quizScore,
    int? pointsEarned,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return ModuleProgress(
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      totalLessons: totalLessons ?? this.totalLessons,
      quizPassed: quizPassed ?? this.quizPassed,
      quizScore: quizScore ?? this.quizScore,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Badge earned by user
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeType type;
  final int pointsValue;
  final DateTime earnedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    this.pointsValue = 0,
    required this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      type: BadgeType.fromString(json['type'] ?? 'achievement'),
      pointsValue: json['points_value'] ?? 0,
      earnedAt: DateTime.parse(json['earned_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'type': type.value,
      'points_value': pointsValue,
      'earned_at': earnedAt.toIso8601String(),
    };
  }
}

/// Badge type enum
enum BadgeType {
  achievement('achievement'),
  milestone('milestone'),
  streak('streak'),
  quiz('quiz'),
  special('special');

  final String value;
  const BadgeType(this.value);

  static BadgeType fromString(String value) {
    return BadgeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BadgeType.achievement,
    );
  }
}

/// Certificate of completion
class Certificate {
  final String id;
  final int moduleId;
  final String moduleTitle;
  final String userName;
  final int score;
  final DateTime issuedAt;
  final String? certificateUrl;
  final String? verificationCode;

  Certificate({
    required this.id,
    required this.moduleId,
    required this.moduleTitle,
    required this.userName,
    required this.score,
    required this.issuedAt,
    this.certificateUrl,
    this.verificationCode,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'],
      moduleId: json['module_id'],
      moduleTitle: json['module_title'],
      userName: json['user_name'],
      score: json['score'],
      issuedAt: DateTime.parse(json['issued_at']),
      certificateUrl: json['certificate_url'],
      verificationCode: json['verification_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'module_title': moduleTitle,
      'user_name': userName,
      'score': score,
      'issued_at': issuedAt.toIso8601String(),
      'certificate_url': certificateUrl,
      'verification_code': verificationCode,
    };
  }
}

/// Learning streak tracking
class LearningStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLearningDate;
  final List<DateTime> streakDates;

  LearningStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLearningDate,
    this.streakDates = const [],
  });

  factory LearningStreak.fromJson(Map<String, dynamic> json) {
    return LearningStreak(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastLearningDate: json['last_learning_date'] != null
          ? DateTime.parse(json['last_learning_date'])
          : null,
      streakDates: json['streak_dates'] != null
          ? (json['streak_dates'] as List)
              .map((d) => DateTime.parse(d))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_learning_date': lastLearningDate?.toIso8601String(),
      'streak_dates':
          streakDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  bool get isActiveToday {
    if (lastLearningDate == null) return false;
    final now = DateTime.now();
    return lastLearningDate!.year == now.year &&
        lastLearningDate!.month == now.month &&
        lastLearningDate!.day == now.day;
  }

  bool get willLoseStreak {
    if (lastLearningDate == null) return false;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return lastLearningDate!.isBefore(
      DateTime(yesterday.year, yesterday.month, yesterday.day),
    );
  }
}

/// Leaderboard entry
class LeaderboardEntry {
  final String oderId;
  final String userName;
  final String? userAvatar;
  final int totalPoints;
  final int rank;
  final int badgeCount;
  final int certificateCount;

  LeaderboardEntry({
    required this.oderId,
    required this.userName,
    this.userAvatar,
    required this.totalPoints,
    required this.rank,
    this.badgeCount = 0,
    this.certificateCount = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      oderId: json['user_id'],
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
      totalPoints: json['total_points'],
      rank: json['rank'],
      badgeCount: json['badge_count'] ?? 0,
      certificateCount: json['certificate_count'] ?? 0,
    );
  }
}
