// Quiz History Response Model
class QuizHistoryResponse {
  final bool success;
  final String message;
  final int totalRecords;
  final QuizHistoryStats stats;
  final List<QuizAttemptItem> data;

  QuizHistoryResponse({
    required this.success,
    required this.message,
    required this.totalRecords,
    required this.stats,
    required this.data,
  });

  factory QuizHistoryResponse.fromJson(Map<String, dynamic> json) {
    return QuizHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      totalRecords: json['total_records'] ?? 0,
      stats: QuizHistoryStats.fromJson(json['stats'] ?? {}),
      data: (json['data'] as List?)?.map((e) => QuizAttemptItem.fromJson(e)).toList() ?? [],
    );
  }
}

// Quiz History Stats Model
class QuizHistoryStats {
  final int totalQuizzes;
  final int totalWins;
  final double averageScore;
  final int totalPrizeWon;

  QuizHistoryStats({
    required this.totalQuizzes,
    required this.totalWins,
    required this.averageScore,
    required this.totalPrizeWon,
  });

  factory QuizHistoryStats.fromJson(Map<String, dynamic> json) {
    return QuizHistoryStats(
      totalQuizzes: _toInt(json['total_quizzes']),
      totalWins: _toInt(json['total_wins']),
      averageScore: _toDouble(json['average_score']),
      totalPrizeWon: _toInt(json['total_prize_won']),
    );
  }

  static int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
  static double _toDouble(dynamic value) => double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
}

// Quiz Attempt Item Model
class QuizAttemptItem {
  final int attemptId;
  final int quizId;
  final String quizTitle;
  final String quizDescription;
  final String categoryName;
  final int categoryId;
  final String difficultyLevel;
  final String banner;
  final String date;
  final String time;
  final String startTime;
  final String endTime;
  final String duration;
  final String timeTaken;
  final int durationSeconds;
  final String status; // 'won', 'lost', 'completed', 'in_progress'
  final double score; // Percentage
  final int rawScore;
  final int totalScore;
  final int passingScore;
  final bool passed;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int skipped;
  final double accuracy;
  final int rank;
  final int totalParticipants;
  final int prize;
  final String prizeText;

  QuizAttemptItem({
    required this.attemptId,
    required this.quizId,
    required this.quizTitle,
    required this.quizDescription,
    required this.categoryName,
    required this.categoryId,
    required this.difficultyLevel,
    required this.banner,
    required this.date,
    required this.time,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.timeTaken,
    required this.durationSeconds,
    required this.status,
    required this.score,
    required this.rawScore,
    required this.totalScore,
    required this.passingScore,
    required this.passed,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skipped,
    required this.accuracy,
    required this.rank,
    required this.totalParticipants,
    required this.prize,
    required this.prizeText,
  });

  factory QuizAttemptItem.fromJson(Map<String, dynamic> json) {
    return QuizAttemptItem(
      attemptId: _toInt(json['attempt_id']),
      quizId: _toInt(json['quiz_id']),
      quizTitle: json['quiz_title']?.toString() ?? '',
      quizDescription: json['quiz_description']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      categoryId: _toInt(json['category_id']),
      difficultyLevel: json['difficulty_level']?.toString() ?? '',
      banner: json['banner']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      timeTaken: json['time_taken']?.toString() ?? '',
      durationSeconds: _toInt(json['duration_seconds']),
      status: json['status']?.toString() ?? 'in_progress',
      score: _toDouble(json['score']),
      rawScore: _toInt(json['raw_score']),
      totalScore: _toInt(json['total_score']),
      passingScore: _toInt(json['passing_score']),
      passed: _toBool(json['passed']),
      totalQuestions: _toInt(json['total_questions']),
      correctAnswers: _toInt(json['correct_answers']),
      wrongAnswers: _toInt(json['wrong_answers']),
      skipped: _toInt(json['skipped']),
      accuracy: _toDouble(json['accuracy']),
      rank: _toInt(json['rank']),
      totalParticipants: _toInt(json['total_participants']),
      prize: _toInt(json['prize']),
      prizeText: json['prize_text']?.toString() ?? '₹0',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  // Helper getter for display status
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'won':
        return 'won';
      case 'lost':
        return 'lost';
      case 'in_progress':
        return 'in_progress';
      default:
        return 'completed';
    }
  }

  // Helper getter for unique ID
  String get id => 'QZ$attemptId';
}
