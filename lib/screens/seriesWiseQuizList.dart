import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';

class TestSeriesDetailPage extends StatefulWidget {
  final String seriesName;
  
  TestSeriesDetailPage({this.seriesName = 'Mathematics Master Series'});

  @override
  _TestSeriesDetailPageState createState() => _TestSeriesDetailPageState();
}

class _TestSeriesDetailPageState extends State<TestSeriesDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
 //hyggtt
  final List<Map<String, dynamic>> _quizList = [
    {
      'title': 'Algebra Basics - Part 1',
      'description': 'Introduction to algebraic expressions',
      'questions': 25,
      'duration': 30,
      'marks': 100,
      'attempted': true,
      'score': 85,
      'attempts': 2,
      'bestScore': 85,
      'lastAttempted': '2 days ago',
      'difficulty': 'Easy',
      'topics': ['Linear Equations', 'Expressions', 'Variables'],
    },
    {
      'title': 'Algebra Basics - Part 2',
      'description': 'Solving complex algebraic problems',
      'questions': 30,
      'duration': 40,
      'marks': 120,
      'attempted': false,
      'locked': false,
      'difficulty': 'Medium',
      'topics': ['Quadratic Equations', 'Factorization'],
    },
    {
      'title': 'Advanced Algebra',
      'description': 'Master level algebra challenges',
      'questions': 35,
      'duration': 45,
      'marks': 140,
      'attempted': false,
      'locked': true,
      'difficulty': 'Hard',
      'topics': ['Polynomials', 'Complex Numbers'],
      'unlockCondition': 'Complete Part 2 with 70% score',
    },
    {
      'title': 'Trigonometry Fundamentals',
      'description': 'Basic trigonometric concepts',
      'questions': 28,
      'duration': 35,
      'marks': 112,
      'attempted': true,
      'score': 72,
      'attempts': 1,
      'bestScore': 72,
      'lastAttempted': '1 week ago',
      'difficulty': 'Medium',
      'topics': ['Ratios', 'Identities', 'Angles'],
    },
  ];

  final List<Map<String, dynamic>> _studyMaterials = [
    {
      'title': 'Algebra Complete Guide',
      'description': 'Comprehensive notes covering all topics',
      'type': 'PDF',
      'size': '2.4 MB',
      'pages': 124,
      'downloads': 1520,
      'uploadDate': '15 days ago',
      'topics': ['All Algebra Topics'],
    },
    {
      'title': 'Trigonometry Video Lectures',
      'description': 'Step by step video explanations',
      'type': 'Video',
      'duration': '3h 45m',
      'lessons': 18,
      'downloads': 2340,
      'uploadDate': '1 month ago',
      'topics': ['Sin, Cos, Tan', 'Identities'],
    },
    {
      'title': 'Formula Sheet - Quick Reference',
      'description': 'All important formulas in one place',
      'type': 'PDF',
      'size': '0.5 MB',
      'pages': 8,
      'downloads': 4520,
      'uploadDate': '3 days ago',
      'topics': ['Formulas', 'Quick Tips'],
    },
    {
      'title': 'Practice Problems Set',
      'description': '500+ solved practice problems',
      'type': 'PDF',
      'size': '5.8 MB',
      'pages': 280,
      'downloads': 980,
      'uploadDate': '2 weeks ago',
      'topics': ['Practice', 'Solutions'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSeriesInfo(),
                _buildProgressCard(),
                _buildTabBar(),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuizListTab(),
                _buildStudyMaterialsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(60, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    widget.seriesName,
                    20,
                    AppColors.white,
                    FontWeight.w900,
                    2,
                    TextAlign.left,
                    1.2,
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.quiz, size: 14, color: AppColors.darkNavy),
                            SizedBox(width: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              '${_quizList.length} Tests',
                              11,
                              AppColors.darkNavy,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.library_books, size: 14, color: AppColors.white),
                            SizedBox(width: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              '${_studyMaterials.length} Materials',
                              11,
                              AppColors.white,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [

      ],
    );
  }

  Widget _buildSeriesInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealGreen, AppColors.darkNavy],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline, color: AppColors.white, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'About This Series',
                16,
                AppColors.darkNavy,
                FontWeight.w800,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 12),
          AppRichText.setTextPoppinsStyle(
            context,
            'Master mathematics with our comprehensive test series. Complete all quizzes to unlock advanced levels',
            13,
            AppColors.greyS700,
            FontWeight.w500,
            10,
            TextAlign.left,
            1.5,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    int completed = _quizList.where((q) => q['attempted'] == true).length;
    double progress = completed / _quizList.length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealGreen, AppColors.darkNavy],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                'Your Progress',
                16,
                AppColors.white,
                FontWeight.w800,
                1,
                TextAlign.left,
                0.0,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  '$completed/${_quizList.length} Completed',
                  12,
                  AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(AppColors.lightGold),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat('Average Score', '78.5%'),
              _buildProgressStat('Total Attempts', '3'),
              _buildProgressStat('Time Spent', '2h 15m'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          value,
          16,
          AppColors.white,
          FontWeight.w900,
          1,
          TextAlign.left,
          0.0,
        ),
        SizedBox(height: 2),
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          11,
          AppColors.white.withOpacity(0.8),
          FontWeight.w600,
          1,
          TextAlign.left,
          0.0,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.tealGreen, AppColors.darkNavy],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.darkNavy,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: 18),
                SizedBox(width: 8),
                Text('Quiz List'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books, size: 18),
                SizedBox(width: 8),
                Text('Materials'),
       
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizListTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _quizList.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final quiz = _quizList[index];
        return _buildQuizCard(quiz, index + 1);
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, int number) {
    bool isLocked = quiz['locked'] ?? false;
    bool isAttempted = quiz['attempted'] ?? false;
    
    Color difficultyColor = quiz['difficulty'] == 'Easy'
        ? AppColors.green
        : quiz['difficulty'] == 'Medium'
            ? AppColors.orange
            : AppColors.red;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isLocked
              ? Border.all(color: AppColors.greyS300, width: 2)
              : null,
          boxShadow: isLocked
              ? []
              : [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isAttempted
                        ? LinearGradient(
                            colors: [
                              AppColors.lightGold.withOpacity(0.2),
                              AppColors.lightGold.withOpacity(0.1),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAttempted
                                ? [AppColors.green, AppColors.greenS3]
                                : [AppColors.tealGreen, AppColors.darkNavy],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: isAttempted
                              ? Icon(Icons.check_circle, color: AppColors.white, size: 28)
                              : AppRichText.setTextPoppinsStyle(
                                  context,
                                  '$number',
                                  20,
                                  AppColors.white,
                                  FontWeight.w900,
                                  1,
                                  TextAlign.center,
                                  0.0,
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppRichText.setTextPoppinsStyle(
                              context,
                              quiz['title'],
                              16,
                              AppColors.darkNavy,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              1.2,
                            ),
                            SizedBox(height: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              quiz['description'],
                              12,
                              AppColors.greyS600,
                              FontWeight.w500,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Quiz Info
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          _buildQuizStat(Icons.help_outline, '${quiz['questions']} Qs'),
                          SizedBox(width: 16),
                          _buildQuizStat(Icons.schedule, '${quiz['duration']} min'),
                          SizedBox(width: 16),
                          _buildQuizStat(Icons.star, '${quiz['marks']} marks'),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: AppRichText.setTextPoppinsStyle(
                              context,
                              quiz['difficulty'],
                              11,
                              difficultyColor,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Topics
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (quiz['topics'] as List<String>).map((topic) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.greyS1,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.tealGreen.withOpacity(0.3)),
                            ),
                            child: AppRichText.setTextPoppinsStyle(
                              context,
                              topic,
                              10,
                              AppColors.darkNavy,
                              FontWeight.w600,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          );
                        }).toList(),
                      ),

                      // Attempted Info
                      if (isAttempted) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.green.withOpacity(0.1),
                                AppColors.green.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events, color: AppColors.green, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppRichText.setTextPoppinsStyle(
                                      context,
                                      'Score: ${quiz['score']}% • Best: ${quiz['bestScore']}%',
                                      13,
                                      AppColors.darkNavy,
                                      FontWeight.w700,
                                      1,
                                      TextAlign.left,
                                      0.0,
                                    ),
                                    SizedBox(height: 2),
                                    AppRichText.setTextPoppinsStyle(
                                      context,
                                      'Attempted ${quiz['attempts']} time(s) • ${quiz['lastAttempted']}',
                                      11,
                                      AppColors.greyS600,
                                      FontWeight.w500,
                                      1,
                                      TextAlign.left,
                                      0.0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Locked Info
                      if (isLocked) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.greyS200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.greyS400),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, color: AppColors.greyS600, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: AppRichText.setTextPoppinsStyle(
                                  context,
                                  quiz['unlockCondition'],
                                  12,
                                  AppColors.greyS700,
                                  FontWeight.w600,
                                  1,
                                  TextAlign.left,
                                  1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 16),

                      Row(
                        children: [
                          if (isAttempted && !isLocked) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.tealGreen, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.analytics, color: AppColors.tealGreen, size: 18),
                                    SizedBox(width: 8),
                                    AppRichText.setTextPoppinsStyle(
                                      context,
                                      'View Results',
                                      13,
                                      AppColors.tealGreen,
                                      FontWeight.w700,
                                      1,
                                      TextAlign.center,
                                      0.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLocked ? null : () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.transparent,
                                  shadowColor: AppColors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                  disabledBackgroundColor: AppColors.greyS300,
                                ),
                                child: isLocked
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.lock, color: AppColors.greyS600, size: 18),
                                          SizedBox(width: 8),
                                          AppRichText.setTextPoppinsStyle(
                                            context,
                                            'Locked',
                                            13,
                                            AppColors.greyS700,
                                            FontWeight.w700,
                                            1,
                                            TextAlign.center,
                                            0.0,
                                          ),
                                        ],
                                      )
                                    : Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppColors.tealGreen, AppColors.darkNavy],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isAttempted ? Icons.replay : Icons.play_arrow,
                                                color: AppColors.white,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              AppRichText.setTextPoppinsStyle(
                                                context,
                                                isAttempted ? 'Retake Quiz' : 'Start Quiz',
                                                13,
                                                AppColors.white,
                                                FontWeight.w700,
                                                1,
                                                TextAlign.center,
                                                0.0,
                                              ),
                                            ],
                                          ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.greyS600),
        SizedBox(width: 4),
        AppRichText.setTextPoppinsStyle(
          context,
          text,
          12,
          AppColors.greyS600,
          FontWeight.w600,
          1,
          TextAlign.left,
          0.0,
        ),
      ],
    );
  }

  Widget _buildStudyMaterialsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      physics: NeverScrollableScrollPhysics(),
      itemCount: _studyMaterials.length,
      itemBuilder: (context, index) {
        final material = _studyMaterials[index];
        return _buildMaterialCard(material);
      },
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    bool isPDF = material['type'] == 'PDF';
    Color typeColor = isPDF ? AppColors.red : AppColors.purple;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor.withOpacity(0.1),
                  typeColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPDF ? Icons.picture_as_pdf : Icons.play_circle_filled,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        material['title'],
                        16,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        1,
                        TextAlign.left,
                        1.2,
                      ),
                      SizedBox(height: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        material['description'],
                        12,
                        AppColors.greyS600,
                        FontWeight.w500,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppRichText.setTextPoppinsStyle(
                    context,
                    material['type'],
                    11,
                    typeColor,
                    FontWeight.w900,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ),
              ],
            ),
          ),

          // Material Info
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (isPDF) ...[
                      _buildMaterialStat(Icons.description, '${material['pages']} pages'),
                      _buildMaterialStat(Icons.folder, material['size']),
                    ] else ...[
                      _buildMaterialStat(Icons.schedule, material['duration']),
                      _buildMaterialStat(Icons.play_lesson, '${material['lessons']} lessons'),
                    ],
                    _buildMaterialStat(Icons.download, '${material['downloads']} downloads'),
                    _buildMaterialStat(Icons.calendar_today, material['uploadDate']),
                  ],
                ),

                SizedBox(height: 12),

                // Topics
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (material['topics'] as List<String>).map((topic) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greyS1,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: typeColor.withOpacity(0.3)),
                      ),
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        topic,
                        10,
                        AppColors.darkNavy,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.tealGreen, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility, color: AppColors.tealGreen, size: 18),
                            SizedBox(width: 8),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Preview',
                              13,
                              AppColors.tealGreen,
                              FontWeight.w700,
                              1,
                              TextAlign.center,
                              0.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.transparent,
                            shadowColor: AppColors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.tealGreen, AppColors.darkNavy],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download, color: AppColors.white, size: 18),
                                  SizedBox(width: 8),
                                  AppRichText.setTextPoppinsStyle(
                                    context,
                                    'Download',
                                    13,
                                    AppColors.white,
                                    FontWeight.w700,
                                    1,
                                    TextAlign.center,
                                    0.0,
                                  ),
                                ],
                              ),
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
        ],
      ),
    );
  }

  Widget _buildMaterialStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.greyS600),
        SizedBox(width: 4),
        AppRichText.setTextPoppinsStyle(
          context,
          text,
          12,
          AppColors.greyS600,
          FontWeight.w600,
          1,
          TextAlign.left,
          0.0,
        ),
      ],
    );
  }
}

