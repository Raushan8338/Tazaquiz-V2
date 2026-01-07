import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';

class QuizHistoryPage extends StatefulWidget {
  @override
  _QuizHistoryPageState createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  String _selectedFilter = 'all'; // 'all', 'completed', 'won', 'lost'

  // Sample quiz history data
  final List<Map<String, dynamic>> _allQuizzes = [
    {
      'id': 'QZ1234567890',
      'title': 'Mathematics Challenge',
      'category': 'Mathematics',
      'date': '07 Jan 2026',
      'time': '10:30 AM',
      'duration': '30 min',
      'status': 'won',
      'score': 85,
      'totalQuestions': 50,
      'correctAnswers': 42,
      'wrongAnswers': 6,
      'skipped': 2,
      'rank': 12,
      'totalParticipants': 234,
      'prize': '₹500',
      'accuracy': 84.0,
      'timeTaken': '28 min',
    },
    {
      'id': 'QZ1234567889',
      'title': 'Science Quiz Battle',
      'category': 'Science',
      'date': '05 Jan 2026',
      'time': '02:15 PM',
      'duration': '45 min',
      'status': 'completed',
      'score': 72,
      'totalQuestions': 60,
      'correctAnswers': 43,
      'wrongAnswers': 12,
      'skipped': 5,
      'rank': 45,
      'totalParticipants': 189,
      'prize': '₹0',
      'accuracy': 71.6,
      'timeTaken': '42 min',
    },
    {
      'id': 'QZ1234567888',
      'title': 'General Knowledge Quiz',
      'category': 'GK',
      'date': '04 Jan 2026',
      'time': '09:45 AM',
      'duration': '60 min',
      'status': 'won',
      'score': 92,
      'totalQuestions': 100,
      'correctAnswers': 92,
      'wrongAnswers': 5,
      'skipped': 3,
      'rank': 5,
      'totalParticipants': 456,
      'prize': '₹2000',
      'accuracy': 92.0,
      'timeTaken': '55 min',
    },
    {
      'id': 'QZ1234567887',
      'title': 'History Masters',
      'category': 'History',
      'date': '03 Jan 2026',
      'time': '05:30 PM',
      'duration': '40 min',
      'status': 'lost',
      'score': 45,
      'totalQuestions': 50,
      'correctAnswers': 22,
      'wrongAnswers': 18,
      'skipped': 10,
      'rank': 156,
      'totalParticipants': 178,
      'prize': '₹0',
      'accuracy': 44.0,
      'timeTaken': '38 min',
    },
    {
      'id': 'QZ1234567886',
      'title': 'Weekly Physics Challenge',
      'category': 'Physics',
      'date': '02 Jan 2026',
      'time': '11:20 AM',
      'duration': '35 min',
      'status': 'completed',
      'score': 68,
      'totalQuestions': 40,
      'correctAnswers': 27,
      'wrongAnswers': 9,
      'skipped': 4,
      'rank': 67,
      'totalParticipants': 203,
      'prize': '₹0',
      'accuracy': 67.5,
      'timeTaken': '33 min',
    },
  ];

  List<Map<String, dynamic>> get _filteredQuizzes {
    if (_selectedFilter == 'all') {
      return _allQuizzes;
    }
    return _allQuizzes.where((quiz) => quiz['status'] == _selectedFilter).toList();
  }

  int get _totalQuizzes => _allQuizzes.length;
  int get _totalWins => _allQuizzes.where((q) => q['status'] == 'won').length;
  double get _averageScore {
    if (_allQuizzes.isEmpty) return 0;
    return _allQuizzes.fold(0.0, (sum, q) => sum + q['score']) / _allQuizzes.length;
  }

  int get _totalPrizeWon {
    return _allQuizzes
        .where((q) => q['status'] == 'won')
        .fold(0, (sum, q) => sum + int.parse(q['prize'].replaceAll('₹', '').replaceAll(',', '')));
  }

  void _showQuizDetails(Map<String, dynamic> quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuizDetailsSheet(quiz),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatsCard(),
          _buildFilterChips(),
          SizedBox(height: 8),
          Expanded(child: _filteredQuizzes.isEmpty ? _buildEmptyState() : _buildQuizList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
        ),
      ),
      title: AppRichText.setTextPoppinsStyle(
        context,
        'Quiz History',
        16,
        AppColors.white,
        FontWeight.w900,
        1,
        TextAlign.left,
        0.0,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.tealGreen, AppColors.darkNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events, color: AppColors.lightGold, size: 22),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Performance Overview',
                      12,
                      AppColors.white.withOpacity(0.9),
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '${_averageScore.toStringAsFixed(1)}% Avg Score',
                      18,
                      AppColors.white,
                      FontWeight.w900,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz,
                  label: 'Total Quizzes',
                  value: '$_totalQuizzes',
                  color: AppColors.white,
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.white.withOpacity(0.3)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.military_tech,
                  label: 'Wins',
                  value: '$_totalWins',
                  color: AppColors.lightGold,
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.white.withOpacity(0.3)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Prize Won',
                  value: '₹$_totalPrizeWon',
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        SizedBox(height: 6),
        AppRichText.setTextPoppinsStyle(context, value, 15, AppColors.white, FontWeight.w900, 1, TextAlign.center, 0.0),
        SizedBox(height: 2),
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          10,
          AppColors.white.withOpacity(0.8),
          FontWeight.w600,
          1,
          TextAlign.center,
          0.0,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All Quizzes', 'all', Icons.list),
          SizedBox(width: 8),
          _buildFilterChip('Completed', 'completed', Icons.check_circle_outline),
          SizedBox(width: 8),
          _buildFilterChip('Won', 'won', Icons.emoji_events),
          SizedBox(width: 8),
          _buildFilterChip('Lost', 'lost', Icons.sentiment_dissatisfied),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    Color chipColor;

    switch (value) {
      case 'won':
        chipColor = AppColors.tealGreen;
        break;
      case 'lost':
        chipColor = AppColors.red;
        break;
      case 'completed':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = AppColors.darkNavy;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [chipColor, chipColor.withOpacity(0.7)]) : null,
          color: isSelected ? null : AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? chipColor : AppColors.greyS300!, width: isSelected ? 2 : 1),
          boxShadow:
              isSelected ? [BoxShadow(color: chipColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.white : AppColors.greyS600),
            SizedBox(width: 6),
            AppRichText.setTextPoppinsStyle(
              context,
              label,
              13,
              isSelected ? AppColors.white : AppColors.darkNavy,
              FontWeight.w700,
              1,
              TextAlign.center,
              0.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = _filteredQuizzes[index];
        return _buildQuizCard(quiz);
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color badgeColor;

    switch (quiz['status']) {
      case 'won':
        statusColor = AppColors.tealGreen;
        statusIcon = Icons.emoji_events;
        statusText = 'Won';
        badgeColor = AppColors.gold;
        break;
      case 'lost':
        statusColor = AppColors.red;
        statusIcon = Icons.sentiment_dissatisfied;
        statusText = 'Lost';
        badgeColor = AppColors.red.withOpacity(0.30);
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        badgeColor = Colors.blue.withOpacity(0.30);
        break;
      default:
        statusColor = AppColors.greyS600;
        statusIcon = Icons.help;
        statusText = 'Unknown';
        badgeColor = AppColors.greyS600;
    }

    return InkWell(
      onTap: () => _showQuizDetails(quiz),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.08)]),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          quiz['title'],
                          14,
                          AppColors.darkNavy,
                          FontWeight.w800,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AppRichText.setTextPoppinsStyle(
                                context,
                                quiz['category'],
                                10,
                                AppColors.darkNavy,
                                FontWeight.w700,
                                1,
                                TextAlign.left,
                                0.0,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.access_time, size: 12, color: AppColors.greyS600),
                            SizedBox(width: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              quiz['date'],
                              10,
                              AppColors.greyS600,
                              FontWeight.w600,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: AppColors.black, size: 16),
                        SizedBox(width: 4),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          statusText,
                          11,
                          AppColors.black,
                          FontWeight.w800,
                          1,
                          TextAlign.center,
                          0.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Score Section
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Score Circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.7)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          '${quiz['score']}%',
                          22,
                          AppColors.white,
                          FontWeight.w900,
                          1,
                          TextAlign.center,
                          0.0,
                        ),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Score',
                          10,
                          AppColors.white.withOpacity(0.9),
                          FontWeight.w600,
                          1,
                          TextAlign.center,
                          0.0,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),

                  // Stats
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallStat(
                                icon: Icons.check_circle,
                                value: '${quiz['correctAnswers']}',
                                label: 'Correct',
                                color: AppColors.tealGreen,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildSmallStat(
                                icon: Icons.cancel,
                                value: '${quiz['wrongAnswers']}',
                                label: 'Wrong',
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallStat(
                                icon: Icons.skip_next,
                                value: '${quiz['skipped']}',
                                label: 'Skipped',
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildSmallStat(
                                icon: Icons.military_tech,
                                value: '#${quiz['rank']}',
                                label: 'Rank',
                                color: AppColors.lightGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.greyS1,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: AppColors.greyS600),
                      SizedBox(width: 6),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '${quiz['totalParticipants']} players',
                        12,
                        AppColors.greyS700,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                      if (quiz['status'] == 'won') ...[
                        SizedBox(width: 16),
                        Icon(Icons.emoji_events, size: 16, color: AppColors.lightGold),
                        SizedBox(width: 4),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          quiz['prize'],
                          12,
                          AppColors.lightGold,
                          FontWeight.w800,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'View Details',
                        12,
                        AppColors.tealGreen,
                        FontWeight.w700,
                        1,
                        TextAlign.right,
                        0.0,
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.tealGreen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(height: 4),
          AppRichText.setTextPoppinsStyle(
            context,
            value,
            14,
            AppColors.darkNavy,
            FontWeight.w800,
            1,
            TextAlign.center,
            0.0,
          ),
          AppRichText.setTextPoppinsStyle(
            context,
            label,
            9,
            AppColors.greyS600,
            FontWeight.w600,
            1,
            TextAlign.center,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealGreen.withOpacity(0.1), AppColors.darkNavy.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.quiz, size: 80, color: AppColors.greyS400),
          ),
          SizedBox(height: 24),
          AppRichText.setTextPoppinsStyle(
            context,
            'No quiz history found',
            20,
            AppColors.darkNavy,
            FontWeight.w800,
            1,
            TextAlign.center,
            0.0,
          ),
          SizedBox(height: 12),
          AppRichText.setTextPoppinsStyle(
            context,
            'Start playing quizzes to see your history',
            14,
            AppColors.greyS600,
            FontWeight.w500,
            1,
            TextAlign.center,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizDetailsSheet(Map<String, dynamic> quiz) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (quiz['status']) {
      case 'won':
        statusColor = AppColors.tealGreen;
        statusIcon = Icons.emoji_events;
        statusText = 'Congratulations! You Won';
        break;
      case 'lost':
        statusColor = AppColors.red;
        statusIcon = Icons.sentiment_dissatisfied;
        statusText = 'Better luck next time!';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Quiz Completed';
        break;
      default:
        statusColor = AppColors.greyS600;
        statusIcon = Icons.help;
        statusText = 'Unknown Status';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(10)),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.7)]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: AppColors.white, size: 48),
                  ),
                  SizedBox(height: 16),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    statusText,
                    22,
                    AppColors.darkNavy,
                    FontWeight.w900,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                  SizedBox(height: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    quiz['title'],
                    16,
                    AppColors.greyS600,
                    FontWeight.w600,
                    2,
                    TextAlign.center,
                    0.0,
                  ),
                ],
              ),
            ),

            // Score Display
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.08)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '${quiz['score']}%',
                        36,
                        statusColor,
                        FontWeight.w900,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Your Score',
                        13,
                        AppColors.greyS600,
                        FontWeight.w600,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                    ],
                  ),
                  Container(width: 2, height: 50, color: AppColors.greyS300),
                  Column(
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '#${quiz['rank']}',
                        36,
                        AppColors.lightGold,
                        FontWeight.w900,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Your Rank',
                        13,
                        AppColors.greyS600,
                        FontWeight.w600,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Detailed Stats
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Performance Breakdown',
                    16,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailStatCard(
                          icon: Icons.check_circle,
                          value: '${quiz['correctAnswers']}',
                          label: 'Correct',
                          color: AppColors.tealGreen,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailStatCard(
                          icon: Icons.cancel,
                          value: '${quiz['wrongAnswers']}',
                          label: 'Wrong',
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailStatCard(
                          icon: Icons.skip_next,
                          value: '${quiz['skipped']}',
                          label: 'Skipped',
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailStatCard(
                          icon: Icons.quiz,
                          value: '${quiz['totalQuestions']}',
                          label: 'Total',
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Quiz Information',
                    16,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Quiz ID', quiz['id']),
                  _buildInfoRow('Category', quiz['category']),
                  _buildInfoRow('Date', quiz['date']),
                  _buildInfoRow('Time', quiz['time']),
                  _buildInfoRow('Duration', quiz['duration']),
                  _buildInfoRow('Time Taken', quiz['timeTaken']),
                  _buildInfoRow('Accuracy', '${quiz['accuracy']}%'),
                  _buildInfoRow('Total Participants', '${quiz['totalParticipants']}'),
                  if (quiz['status'] == 'won') _buildInfoRow('Prize Won', quiz['prize'], isHighlight: true),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.tealGreen, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Close',
                            14,
                            AppColors.tealGreen,
                            FontWeight.w700,
                            1,
                            TextAlign.center,
                            0.0,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Review answers
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Answer review feature coming soon!'),
                                backgroundColor: AppColors.tealGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.transparent,
                            shadowColor: AppColors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: AppRichText.setTextPoppinsStyle(
                                context,
                                'Review Answers',
                                14,
                                AppColors.white,
                                FontWeight.w700,
                                1,
                                TextAlign.center,
                                0.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          SizedBox(height: 8),
          AppRichText.setTextPoppinsStyle(
            context,
            value,
            20,
            AppColors.darkNavy,
            FontWeight.w900,
            1,
            TextAlign.center,
            0.0,
          ),
          SizedBox(height: 4),
          AppRichText.setTextPoppinsStyle(
            context,
            label,
            11,
            AppColors.greyS600,
            FontWeight.w600,
            1,
            TextAlign.center,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            label,
            13,
            AppColors.greyS600,
            FontWeight.w600,
            1,
            TextAlign.left,
            0.0,
          ),
          AppRichText.setTextPoppinsStyle(
            context,
            value,
            13,
            isHighlight ? AppColors.lightGold : AppColors.darkNavy,
            FontWeight.w700,
            1,
            TextAlign.right,
            0.0,
          ),
        ],
      ),
    );
  }
}
