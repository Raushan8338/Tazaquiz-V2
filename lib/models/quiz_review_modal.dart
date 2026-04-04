class QuizReviewOption {
  final int answerId;
  final String answerText;
  final bool isCorrect;

  QuizReviewOption({required this.answerId, required this.answerText, required this.isCorrect});

  factory QuizReviewOption.fromJson(Map<String, dynamic> j) {
    return QuizReviewOption(
      answerId: (j['answer_id'] ?? 0).toInt(),
      answerText: j['answer_text'] ?? '',
      isCorrect: j['is_correct'] == true || j['is_correct'] == 1,
    );
  }
}

class QuizReviewQuestion {
  final int questionId;
  final String questionText;
  final String explanation;
  final double marks;
  final int? userAnswerId;
  final int? correctAnswerId;
  final bool isCorrect;
  final String status; // correct / wrong / skipped
  final int timeSpent;
  final List<QuizReviewOption> options;

  QuizReviewQuestion({
    required this.questionId,
    required this.questionText,
    required this.explanation,
    required this.marks,
    required this.userAnswerId,
    required this.correctAnswerId,
    required this.isCorrect,
    required this.status,
    required this.timeSpent,
    required this.options,
  });

  factory QuizReviewQuestion.fromJson(Map<String, dynamic> j) {
    return QuizReviewQuestion(
      questionId: (j['question_id'] ?? 0).toInt(),
      questionText: j['question_text'] ?? '',
      explanation: j['explanation'] ?? '',
      marks: (j['marks'] ?? 1).toDouble(),
      userAnswerId: j['user_answer_id'] != null ? (j['user_answer_id']).toInt() : null,
      correctAnswerId: j['correct_answer_id'] != null ? (j['correct_answer_id']).toInt() : null,
      isCorrect: j['is_correct'] == true || j['is_correct'] == 1,
      status: j['status'] ?? 'skipped',
      timeSpent: (j['time_spent'] ?? 0).toInt(),
      options: (j['options'] as List? ?? []).map((e) => QuizReviewOption.fromJson(e)).toList(),
    );
  }
}

class QuizReviewSummary {
  final int total;
  final int correct;
  final int wrong;
  final int skipped;

  QuizReviewSummary({required this.total, required this.correct, required this.wrong, required this.skipped});

  factory QuizReviewSummary.fromJson(Map<String, dynamic> j) {
    return QuizReviewSummary(
      total: (j['total'] ?? 0).toInt(),
      correct: (j['correct'] ?? 0).toInt(),
      wrong: (j['wrong'] ?? 0).toInt(),
      skipped: (j['skipped'] ?? 0).toInt(),
    );
  }
}

class QuizReviewAttempt {
  final int attemptId;
  final int quizId;
  final String quizTitle;
  final String categoryName;

  // ✅ Raw score (marks mein) — e.g. 7.0
  final double score;

  // ✅ Score % — e.g. 14.0
  final double scorePercent;

  // ✅ Total marks — e.g. 50.0
  final double totalScore;

  // ✅ Passing marks — e.g. 30.0
  final double passingScore;

  // ✅ Passing % — e.g. 60.0
  final double passingPercent;

  // ✅ Negative marking info
  final double negativeMarkRate; // per wrong question — e.g. 0.5
  final double negativeDeducted; // total kata — e.g. 2.5

  final bool passed;
  final String status;
  final String startTime;
  final String endTime;

  QuizReviewAttempt({
    required this.attemptId,
    required this.quizId,
    required this.quizTitle,
    required this.categoryName,
    required this.score,
    required this.scorePercent,
    required this.totalScore,
    required this.passingScore,
    required this.passingPercent,
    required this.negativeMarkRate,
    required this.negativeDeducted,
    required this.passed,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  factory QuizReviewAttempt.fromJson(Map<String, dynamic> j) {
    return QuizReviewAttempt(
      attemptId: (j['attempt_id'] ?? 0).toInt(),
      quizId: (j['quiz_id'] ?? 0).toInt(),
      quizTitle: j['quiz_title'] ?? '',
      categoryName: j['category_name'] ?? '',
      score: (j['score'] ?? 0).toDouble(),
      scorePercent: (j['score_percent'] ?? 0).toDouble(),
      totalScore: (j['total_score'] ?? 0).toDouble(),
      passingScore: (j['passing_score'] ?? 0).toDouble(),
      passingPercent: (j['passing_percent'] ?? 0).toDouble(),
      negativeMarkRate: (j['negative_mark_rate'] ?? 0).toDouble(),
      negativeDeducted: (j['negative_deducted'] ?? 0).toDouble(),
      passed: j['passed'] == true || j['passed'] == 1,
      status: j['status'] ?? '',
      startTime: j['start_time'] ?? '',
      endTime: j['end_time'] ?? '',
    );
  }
}

class QuizReviewResponse {
  final bool status;
  final QuizReviewAttempt attempt;
  final QuizReviewSummary summary;
  final List<QuizReviewQuestion> questions;

  QuizReviewResponse({required this.status, required this.attempt, required this.summary, required this.questions});

  factory QuizReviewResponse.fromJson(Map<String, dynamic> j) {
    return QuizReviewResponse(
      status: j['status'] ?? false,
      attempt: QuizReviewAttempt.fromJson(j['attempt'] ?? {}),
      summary: QuizReviewSummary.fromJson(j['summary'] ?? {}),
      questions: (j['questions'] as List? ?? []).map((e) => QuizReviewQuestion.fromJson(e)).toList(),
    );
  }
}
