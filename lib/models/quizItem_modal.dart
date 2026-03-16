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

  final bool isPaid;
  final double price;
  final bool isPurchased;
  final bool isAccessible;

  final bool isLive;
  final int startsInSeconds;
  final String startsInText;

  int totalQuestions;
  int totalMarks;
  final int pageType;

  // ── Naye 4 fields (package access) ──
  final bool accessStatus;
  final String? accessError;
  final String? accessMessage;
  final int? pendingAttemptId;

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
    this.totalQuestions = 0,
    this.totalMarks = 0,
    this.pageType = 0,
    // naye — default values hain to crash nahi hoga
    this.accessStatus = true,
    this.accessError,
    this.accessMessage,
    this.pendingAttemptId,
  });
  factory QuizItem.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) {
        return v.toLowerCase() == 'true' || v == '1';
      }
      return false;
    }

    String status =
        json['quizStatus']?.toString().toLowerCase() ?? json['quiz_status']?.toString().toLowerCase() ?? 'upcoming';

    return QuizItem(
      quizId: json['quizId']?.toString() ?? json['quiz_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      banner: json['banner']?.toString(),

      startDateTime: json['startDateTime']?.toString() ?? '',
      endDateTime: json['endDateTime']?.toString() ?? '',
      timeLimit: json['timeLimit']?.toString() ?? json['time_limit']?.toString() ?? '',

      difficultyLevel: json['difficultyLevel']?.toString() ?? json['difficulty_level']?.toString() ?? '',

      instruction: json['instruction']?.toString() ?? '',
      quizStatus: status,

      is_attempted: _toBool(json['is_attempted']),

      subscription_id: _toInt(json['subscription_id']),
      isPaid: _toBool(json['isPaid']),
      price: _toDouble(json['price']),

      isPurchased: _toBool(json['isPurchased'] ?? json['is_purchased']),
      isAccessible: _toBool(json['isAccessible'] ?? json['is_accessible']),

      // ⭐ LIVE FIX
      isLive: status == 'live' || _toBool(json['isLive']),

      startsInSeconds: _toInt(json['startsInSeconds']),
      startsInText: json['startsInText']?.toString() ?? '',

      is_premium: _toInt(json['is_premium']),

      Category_name: json['Category_name']?.toString() ?? '',
      Material_name: json['Material_name']?.toString() ?? '',

      subscription_price: _toDouble(json['subscription_price']),
      subscription_description: json['subscription_description']?.toString() ?? '',

      totalQuestions: _toInt(json['total_questions'] ?? json['questionCount']),
      totalMarks: _toInt(json['total_marks'] ?? json['passing_score']),

      pageType: _toInt(json['pageType']),

      // ⭐ ACCESS CONTROL
      accessStatus: _toBool(json['access_status']),
      accessError: json['access_error']?.toString(),
      accessMessage: json['access_message']?.toString(),

      pendingAttemptId: _toInt(json['pending_attempt_id'] ?? json['pendingAttemptId']),
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
      'total_questions': totalQuestions,
      'total_marks': totalMarks,
      'pageType': pageType,
      'access_status': accessStatus,
      'access_error': accessError,
      'access_message': accessMessage,
      'pending_attempt_id': pendingAttemptId,
    };
  }
}
