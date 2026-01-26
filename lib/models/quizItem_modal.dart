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
  final int is_premium;

  final String Category_name;
  final String Material_name;
  final double subscription_price;
  final String subscription_description;
  final int subscription_id;

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
    this.subscription_id = 0,
    this.isPaid = false,
    this.price = 0.0,
    required this.isPurchased,
    required this.isAccessible,
    required this.isLive,
    this.startsInSeconds = 0,
    this.startsInText = '',
    this.is_premium = 0,
    this.Category_name = '',
    this.Material_name = '',
    this.subscription_price = 0.0,
    this.subscription_description = '',
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
      subscription_id: _toInt(json['subscription_id']),
      isPaid: _toBool(json['isPaid']),
      price: _toDouble(json['price']),
      isPurchased: _toBool(json['isPurchased']),
      isAccessible: _toBool(json['isAccessible']),
      isLive: _toBool(json['isLive']),
      startsInSeconds: _toInt(json['startsInSeconds']),
      startsInText: json['starts_in_text']?.toString() ?? '',
      is_premium: _toInt(json['is_premium']),
      Category_name: json['Category_name']?.toString() ?? 'Test Series Name',
      Material_name: json['Material_name']?.toString() ?? 'Material Name',
      subscription_price: _toDouble(json['subscription_price']),
      subscription_description: json['subscription_description']?.toString() ?? '',
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
      'subscription_id': subscription_id,
      'isPaid': isPaid,
      'price': price,
      'is_purchased': isPurchased,
      'is_accessible': isAccessible,
      'is_live': isLive,
      'starts_in_seconds': startsInSeconds,
      'starts_in_text': startsInText,
      'is_premium': is_premium,
      'Category_name': Category_name,
      'Material_name': Material_name,
      'subscription_price': subscription_price,
      'subscription_description': subscription_description,
    };
  }
}
