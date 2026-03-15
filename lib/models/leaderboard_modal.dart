import 'dart:ui';

int _safeInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is double) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}

double _safeDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

bool _safeBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) return val == '1' || val.toLowerCase() == 'true';
  return false;
}

class LeaderboardBadge {
  final String icon;
  final String label;
  final String color;

  LeaderboardBadge({required this.icon, required this.label, required this.color});

  factory LeaderboardBadge.fromJson(Map<String, dynamic> j) {
    return LeaderboardBadge(
      icon: j['icon']?.toString() ?? '👤',
      label: j['label']?.toString() ?? '',
      color: j['color']?.toString() ?? '9E9E9E',
    );
  }

  Color get flutterColor {
    try {
      return Color(int.parse('FF$color', radix: 16));
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
  }
}

class LeaderboardItem {
  final int rank;
  final String userId;
  final String username;
  final String profileImage;
  final LeaderboardBadge badge;
  final bool isCurrentUser;

  // Course fields
  final double avgScore;
  final int totalAttempts;
  final int totalQuizzes;
  final int totalMocks;
  final int totalWins;
  final double winRate;
  final double bestQuizScore;
  final double bestMockScore;

  // Quiz/Mock fields
  final double score;
  final int correctAnswers;
  final int totalAnswered;
  final String timeTaken;
  final bool passed;

  LeaderboardItem({
    required this.rank,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.badge,
    required this.isCurrentUser,
    required this.avgScore,
    required this.totalAttempts,
    required this.totalQuizzes,
    required this.totalMocks,
    required this.totalWins,
    required this.winRate,
    required this.bestQuizScore,
    required this.bestMockScore,
    required this.score,
    required this.correctAnswers,
    required this.totalAnswered,
    required this.timeTaken,
    required this.passed,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> j) {
    return LeaderboardItem(
      rank: _safeInt(j['rank']),
      userId: j['user_id']?.toString() ?? '',
      username: j['username']?.toString() ?? 'User',
      profileImage: j['profile_image']?.toString() ?? '',
      badge: LeaderboardBadge.fromJson(j['badge'] as Map<String, dynamic>? ?? {}),
      isCurrentUser: _safeBool(j['is_current_user']),
      avgScore: _safeDouble(j['avg_score']),
      totalAttempts: _safeInt(j['total_attempts']),
      totalQuizzes: _safeInt(j['total_quizzes']),
      totalMocks: _safeInt(j['total_mocks']),
      totalWins: _safeInt(j['total_wins']),
      winRate: _safeDouble(j['win_rate']),
      bestQuizScore: _safeDouble(j['best_quiz_score']),
      bestMockScore: _safeDouble(j['best_mock_score']),
      score: _safeDouble(j['score']),
      correctAnswers: _safeInt(j['correct_answers']),
      totalAnswered: _safeInt(j['total_answered']),
      timeTaken: j['time_taken']?.toString() ?? '',
      passed: _safeBool(j['passed']),
    );
  }
}

class LeaderboardResponse {
  final bool status;
  final String type;
  final int? myRank;
  final LeaderboardItem? myData;
  final int total;
  final List<LeaderboardItem> leaderboard;

  LeaderboardResponse({
    required this.status,
    required this.type,
    required this.myRank,
    required this.myData,
    required this.total,
    required this.leaderboard,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> j) {
    return LeaderboardResponse(
      status: _safeBool(j['status']),
      type: j['type']?.toString() ?? 'course',
      myRank: j['my_rank'] != null ? _safeInt(j['my_rank']) : null,
      myData: j['my_data'] != null ? LeaderboardItem.fromJson(j['my_data'] as Map<String, dynamic>) : null,
      total: _safeInt(j['total']),
      leaderboard:
          (j['leaderboard'] as List? ?? []).map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
