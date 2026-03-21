class QuizAttempt {
  final int id;
  final String quizDate;
  final int score;
  final int total;
  final int timeTaken;

  QuizAttempt({
    required this.id,
    required this.quizDate,
    required this.score,
    required this.total,
    required this.timeTaken,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
    id: j['id'],
    quizDate: j['quiz_date'],
    score: j['score'],
    total: j['total'],
    timeTaken: j['time_taken'] ?? 0,
  );
}

class QuizResultDetail {
  final String questionId;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final String selectedAnswer;
  final bool isCorrect;

  QuizResultDetail({
    required this.questionId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  factory QuizResultDetail.fromJson(Map<String, dynamic> e) => QuizResultDetail(
    questionId: e['id'] ?? '0', // ✅ 'id' use karo
    question: e['question'] ?? '',
    optionA: e['option_a'] ?? '',
    optionB: e['option_b'] ?? '',
    optionC: e['option_c'] ?? '',
    optionD: e['option_d'] ?? '',
    correctAnswer: e['answer'] ?? '',
    selectedAnswer: e['selected'] ?? '',
    isCorrect: e['is_correct'] == 1 || e['is_correct'] == '1',
  );
}
