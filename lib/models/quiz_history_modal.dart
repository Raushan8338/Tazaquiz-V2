// quiz_history_modal.dart

class QuizAttemptItem {
  final String id;
  final String quizId;
  final String quizTitle;
  final String quizDescription;
  final String categoryName;
  final String difficultyLevel;
  final String banner;
  final String date;
  final String time;
  final String duration;
  final String timeTaken;
  final double score;
  final int rawScore;
  final int totalScore;
  final int passingScore;
  final int correctAnswers;
  final int wrongAnswers;
  final int skipped;
  final int totalQuestions;
  final double accuracy;
  final int rank;
  final int totalParticipants;
  final String status;
  final bool passed;
  final int prize;
  final String prizeText;

  QuizAttemptItem({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.quizDescription,
    required this.categoryName,
    required this.difficultyLevel,
    required this.banner,
    required this.date,
    required this.time,
    required this.duration,
    required this.timeTaken,
    required this.score,
    required this.rawScore,
    required this.totalScore,
    required this.passingScore,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skipped,
    required this.totalQuestions,
    required this.accuracy,
    required this.rank,
    required this.totalParticipants,
    required this.status,
    required this.passed,
    required this.prize,
    required this.prizeText,
  });

  factory QuizAttemptItem.fromJson(Map<String, dynamic> j) {
    // ── Safe int parser ──────────────────────────────
    int safeInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    // ── Safe double parser ───────────────────────────
    double safeDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    // ── Safe bool parser ─────────────────────────────
    bool safeBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) {
        return val == '1' || val.toLowerCase() == 'true';
      }
      return false;
    }

    return QuizAttemptItem(
      id: j['id']?.toString() ?? j['attempt_id']?.toString() ?? '',
      quizId: j['quiz_id']?.toString() ?? '',
      quizTitle: j['quiz_title']?.toString() ?? '',
      quizDescription: j['quiz_description']?.toString() ?? '',
      categoryName: j['category_name']?.toString() ?? '',
      difficultyLevel: j['difficulty_level']?.toString() ?? 'Medium',
      banner: j['banner']?.toString() ?? '',
      date: j['date']?.toString() ?? '',
      time: j['time']?.toString() ?? '',
      duration: j['duration']?.toString() ?? '',
      timeTaken: j['time_taken']?.toString() ?? '',
      score: safeDouble(j['score']),
      rawScore: safeInt(j['raw_score']),
      totalScore: safeInt(j['total_score']),
      passingScore: safeInt(j['passing_score']),
      correctAnswers: safeInt(j['correct_answers']),
      wrongAnswers: safeInt(j['wrong_answers']),
      skipped: safeInt(j['skipped']),
      totalQuestions: safeInt(j['total_questions']),
      accuracy: safeDouble(j['accuracy']),
      rank: safeInt(j['rank']),
      totalParticipants: safeInt(j['total_participants']),
      status: j['status']?.toString() ?? 'in_progress',
      passed: safeBool(j['passed']),
      prize: safeInt(j['prize']),
      prizeText: j['prize_text']?.toString() ?? '',
    );
  }
}

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

  factory QuizHistoryStats.fromJson(Map<String, dynamic> j) {
    int safeInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    double safeDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return QuizHistoryStats(
      totalQuizzes: safeInt(j['total_quizzes']),
      totalWins: safeInt(j['total_wins']),
      averageScore: safeDouble(j['average_score']),
      totalPrizeWon: safeInt(j['total_prize_won']),
    );
  }
}

class QuizHistoryResponse {
  final bool status;
  final QuizHistoryStats stats;
  final List<QuizAttemptItem> data;

  QuizHistoryResponse({required this.status, required this.stats, required this.data});

  factory QuizHistoryResponse.fromJson(Map<String, dynamic> j) {
    return QuizHistoryResponse(
      status:
          j['status'] == true || j['status'] == 1 || j['status'] == '1' || j['success'] == true || j['success'] == 1,
      stats: QuizHistoryStats.fromJson(j['stats'] ?? {}),
      data: (j['data'] as List? ?? []).map((e) => QuizAttemptItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
