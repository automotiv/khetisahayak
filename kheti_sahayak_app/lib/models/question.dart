class Question {
  final String id;
  final String userId;
  final String title;
  final String body;
  final List<String> tags;
  final int views;
  final int upvotes;
  final int downvotes;
  final bool isAnswered;
  final int answersCount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final int? userVote;
  final List<Answer>? answers;

  Question({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.tags = const [],
    this.views = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isAnswered = false,
    this.answersCount = 0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.userVote,
    this.answers,
  });

  int get score => upvotes - downvotes;

  String get authorName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username ?? 'Anonymous';
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    List<Answer>? answersList;
    if (json['answers'] != null) {
      answersList = (json['answers'] as List)
          .map((a) => Answer.fromJson(a))
          .toList();
    }

    List<String> tagsList = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tagsList = List<String>.from(json['tags']);
      }
    }

    return Question(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      tags: tagsList,
      views: json['views'] ?? 0,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      isAnswered: json['is_answered'] ?? false,
      answersCount: json['answers_count'] ?? 0,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImage: json['profile_image'],
      userVote: json['user_vote'],
      answers: answersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'tags': tags,
      'views': views,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'is_answered': isAnswered,
      'answers_count': answersCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Question copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    List<String>? tags,
    int? views,
    int? upvotes,
    int? downvotes,
    bool? isAnswered,
    int? answersCount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? firstName,
    String? lastName,
    String? profileImage,
    int? userVote,
    List<Answer>? answers,
  }) {
    return Question(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      views: views ?? this.views,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isAnswered: isAnswered ?? this.isAnswered,
      answersCount: answersCount ?? this.answersCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      userVote: userVote ?? this.userVote,
      answers: answers ?? this.answers,
    );
  }
}

class Answer {
  final String id;
  final String questionId;
  final String userId;
  final String body;
  final int upvotes;
  final int downvotes;
  final bool isAccepted;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final int? userVote;

  Answer({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.body,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isAccepted = false,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.userVote,
  });

  int get score => upvotes - downvotes;

  String get authorName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username ?? 'Anonymous';
  }

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['question_id'],
      userId: json['user_id'],
      body: json['body'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      isAccepted: json['is_accepted'] ?? false,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImage: json['profile_image'],
      userVote: json['user_vote'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'user_id': userId,
      'body': body,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'is_accepted': isAccepted,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Answer copyWith({
    String? id,
    String? questionId,
    String? userId,
    String? body,
    int? upvotes,
    int? downvotes,
    bool? isAccepted,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? firstName,
    String? lastName,
    String? profileImage,
    int? userVote,
  }) {
    return Answer(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      userId: userId ?? this.userId,
      body: body ?? this.body,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isAccepted: isAccepted ?? this.isAccepted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      userVote: userVote ?? this.userVote,
    );
  }
}

class Tag {
  final String name;
  final int questionsCount;

  Tag({
    required this.name,
    this.questionsCount = 0,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'],
      questionsCount: json['questions_count'] ?? 0,
    );
  }
}
