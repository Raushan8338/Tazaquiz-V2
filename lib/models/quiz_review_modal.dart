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
  final double negativeMarks;
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
    required this.negativeMarks,
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
      negativeMarks: (j['negative_marks'] ?? 0).toDouble(),
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
  final double score;
  final double totalScore;
  final double passingScore;
  final bool passed;
  final String status;

  QuizReviewAttempt({
    required this.attemptId,
    required this.quizId,
    required this.quizTitle,
    required this.categoryName,
    required this.score,
    required this.totalScore,
    required this.passingScore,
    required this.passed,
    required this.status,
  });

  factory QuizReviewAttempt.fromJson(Map<String, dynamic> j) {
    return QuizReviewAttempt(
      attemptId: (j['attempt_id'] ?? 0).toInt(),
      quizId: (j['quiz_id'] ?? 0).toInt(),
      quizTitle: j['quiz_title'] ?? '',
      categoryName: j['category_name'] ?? '',
      score: (j['score'] ?? 0).toDouble(),
      totalScore: (j['total_score'] ?? 0).toDouble(),
      passingScore: (j['passing_score'] ?? 0).toDouble(),
      passed: j['passed'] == true || j['passed'] == 1,
      status: j['status'] ?? '',
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
