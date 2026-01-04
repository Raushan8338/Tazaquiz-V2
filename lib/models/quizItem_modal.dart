// Quiz Item Model
class QuizItem {
  final String quizId;
  final String title;
  final String? banner;
  final String startDateTime;
  final String timeLimit;
  final String difficultyLevel;
  final String quizStatus;

  QuizItem({
    required this.quizId,
    required this.title,
    this.banner,
    required this.startDateTime,
    required this.timeLimit,
    required this.difficultyLevel,
    required this.quizStatus,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      quizId: json['quiz_id']?.toString() ?? '',
      title: json['title'] ?? '',
      banner: json['banner'],
      startDateTime: json['startDateTime'] ?? '',
      timeLimit: json['time_limit']?.toString() ?? '',
      difficultyLevel: json['difficulty_level'] ?? '',
      quizStatus: json['quiz_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'title': title,
      'banner': banner,
      'startDateTime': startDateTime,
      'time_limit': timeLimit,
      'difficulty_level': difficultyLevel,
      'quiz_status': quizStatus,
    };
  }
}
