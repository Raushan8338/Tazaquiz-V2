// Updated Quiz Item Model
class QuizItem {
  final String quizId;
  final String title;
  final String description;
  final String? banner;
  final String startDateTime;
  final String endDateTime;
  final String timeLimit;
  final String difficultyLevel;
  final String instruction;
  final String quizStatus;
  final bool is_attempted;

  // Payment & Access
  final bool isPaid;
  final double price;
  final bool isPurchased;
  final bool isAccessible;

  // Live Status
  final bool isLive;
  final int startsInSeconds;
  final String startsInText;

  QuizItem({
    required this.quizId,
    required this.title,
    this.description = '',
    this.banner,
    required this.startDateTime,
    this.endDateTime = '',
    this.timeLimit = '',
    this.difficultyLevel = '',
    this.instruction = '',
    required this.quizStatus,
    this.is_attempted = false,
    this.isPaid = false,
    this.price = 0.0,
    this.isPurchased = false,
    this.isAccessible = false,
    this.isLive = false,
    this.startsInSeconds = 0,
    this.startsInText = '',
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    bool _toBool(dynamic v) => v == true || v == 1 || v == '1';

    return QuizItem(
      quizId: json['quiz_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      banner: json['banner']?.toString(),
      startDateTime: json['startDateTime']?.toString() ?? '',
      endDateTime: json['endDateTime']?.toString() ?? '',
      timeLimit: json['time_limit']?.toString() ?? '',
      difficultyLevel: json['difficulty_level']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? '',
      quizStatus: json['quiz_status']?.toString() ?? 'upcoming',
      is_attempted: json['is_attempted'] ?? false,
      isPaid: _toBool(json['isPaid']),
      price: _toDouble(json['price']),
      isPurchased: _toBool(json['is_purchased']),
      isAccessible: _toBool(json['is_accessible']),
      isLive: _toBool(json['is_live']),
      startsInSeconds: _toInt(json['starts_in_seconds']),
      startsInText: json['starts_in_text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'title': title,
      'description': description,
      'banner': banner,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'time_limit': timeLimit,
      'difficulty_level': difficultyLevel,
      'instruction': instruction,
      'quiz_status': quizStatus,
      'is_attempted': is_attempted,
      'isPaid': isPaid,
      'price': price,
      'is_purchased': isPurchased,
      'is_accessible': isAccessible,
      'is_live': isLive,
      'starts_in_seconds': startsInSeconds,
      'starts_in_text': startsInText,
    };
  }
}
