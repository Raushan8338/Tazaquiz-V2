import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/seriesWiseQuizList.dart';
import 'package:tazaquiznew/utils/richText.dart';

class SubjectContentPage extends StatefulWidget {
  @override
  _SubjectContentPageState createState() => _SubjectContentPageState();
}

class _SubjectContentPageState extends State<SubjectContentPage>
    with SingleTickerProviderStateMixin {
       //hyggtt
  late TabController _tabController;
  int _selectedSubjectIndex = 0;

  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Mathematics',
      'icon': Icons.calculate,
      'color': AppColors.tealGreen,
      'totalTests': 45,
      'totalMaterials': 128,
    },
    {
      'name': 'Science',
      'icon': Icons.science,
      'color': AppColors.darkNavy,
      'totalTests': 38,
      'totalMaterials': 96,
    },
    {
      'name': 'English',
      'icon': Icons.book,
      'color': AppColors.oxfordBlue,
      'totalTests': 32,
      'totalMaterials': 84,
    },
    {
      'name': 'Physics',
      'icon': Icons.bolt,
      'color': AppColors.tealGreen,
      'totalTests': 28,
      'totalMaterials': 72,
    },
  ];

  final List<Map<String, dynamic>> _testSeries = [
    {
      'title': 'Algebra Fundamentals',
      'description': 'Master basic algebra concepts',
      'questions': 50,
      'duration': '60 min',
      'difficulty': 'Easy',
      'attempted': true,
      'attempedQuiz': 85,
      'isPremium': false,
    },
    {
      'title': 'Trigonometry Advanced',
      'description': 'Advanced trigonometry problems',
      'questions': 40,
      'duration': '45 min',
      'difficulty': 'Hard',
      'attempted': false,
      'isPremium': true,
    },
    {
      'title': 'Calculus Basics',
      'description': 'Introduction to calculus',
      'questions': 35,
      'duration': '40 min',
      'difficulty': 'Medium',
      'attempted': true,
      'attempedQuiz': 1,
      'isPremium': false,
    },
    {
      'title': 'Geometry Practice',
      'description': 'Comprehensive geometry test',
      'questions': 45,
      'duration': '50 min',
      'difficulty': 'Medium',
      'attempted': false,
      'isPremium': false,
    },

    {
      'title': 'Geometry Practice',
      'description': 'Comprehensive geometry test',
      'questions': 45,
      'duration': '50 min',
      'difficulty': 'Medium',
      'attempted': false,
      'isPremium': false,
    },

     {
      'title': 'Geometry Practice',
      'description': 'Comprehensive geometry test',
      'questions': 45,
      'duration': '50 min',
      'difficulty': 'Medium',
      'attempted': false,
      'isPremium': false,
    },
  ];

  final List<Map<String, dynamic>> _studyMaterials = [
    {
      'title': 'Algebra Complete Guide',
      'description': 'Comprehensive algebra notes',
      'type': 'PDF',
      'pages': 124,
      'size': '2.4 MB',
      'downloads': 1520,
      'rating': 4.8,
      'isPremium': false,
    },
    {
      'title': 'Calculus Video Series',
      'description': 'Video lectures on calculus',
      'type': 'Video',
      'duration': '4h 30m',
      'lessons': 25,
      'downloads': 2340,
      'rating': 4.9,
      'isPremium': true,
    },
    {
      'title': 'Trigonometry Formula Sheet',
      'description': 'All important formulas',
      'type': 'PDF',
      'pages': 8,
      'size': '0.8 MB',
      'downloads': 3420,
      'rating': 4.7,
      'isPremium': false,
    },
    {
      'title': 'Geometry Practice Problems',
      'description': '500+ solved problems',
      'type': 'PDF',
      'pages': 256,
      'size': '5.2 MB',
      'downloads': 980,
      'rating': 4.6,
      'isPremium': true,
    },
    {
      'title': 'Geometry Practice Problems',
      'description': '500+ solved problems',
      'type': 'PDF',
      'pages': 256,
      'size': '5.2 MB',
      'downloads': 980,
      'rating': 4.6,
      'isPremium': true,
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
                _buildSubjectSelector(),
                _buildStatsCards(),
                _buildTabBar(),
             
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTestSeriesTab(),
                _buildStudyMaterialsTab(),
                   SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Learning Resources',
                    20,
                    AppColors.white,
                    FontWeight.w900,
                    1,
                    TextAlign.left,
                    1.2,
                  ),
                  SizedBox(height: 4),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Test Series & Study Materials',
                    14,
                    AppColors.lightGold,
                    FontWeight.w500,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
       
      ],
    );
  }

  Widget _buildSubjectSelector() {
    return Container(
      height: 120,
      margin: EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
       
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final isSelected = _selectedSubjectIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSubjectIndex = index;
              });
            },
            child: Container(
              width: 100,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [subject['color'], subject['color'].withOpacity(0.7)],
                      )
                    : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.transparent : AppColors.greyS300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? subject['color'].withOpacity(0.3)
                        : AppColors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 15 : 10,
                    offset: Offset(0, isSelected ? 8 : 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.white.withOpacity(0.2)
                          : subject['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      subject['icon'],
                      color: isSelected ? AppColors.white : subject['color'],
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    subject['name'],
                    12,
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
        },
      ),
    );
  }

  Widget _buildStatsCards() {
    final selectedSubject = _subjects[_selectedSubjectIndex];
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.quiz,
              '${selectedSubject['totalTests']}',
              'Test Series',
              AppColors.tealGreen,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.greyS300,
          ),
          Expanded(
            child: _buildStatItem(
              Icons.library_books,
              '${selectedSubject['totalMaterials']}',
              'Materials',
              AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        AppRichText.setTextPoppinsStyle(
          context,
          value,
          20,
          color,
          FontWeight.w900,
          1,
          TextAlign.center,
          0.0,
        ),
        SizedBox(height: 2),
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
                Text('Test Series'),
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

  Widget _buildTestSeriesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      shrinkWrap: true,
      itemCount: _testSeries.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final test = _testSeries[index];
        return _buildTestCard(test);
      },
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {

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
          // Header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.tealGreen, AppColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.quiz, color: AppColors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppRichText.setTextPoppinsStyle(
                              context,
                              test['title'],
                              16,
                              AppColors.darkNavy,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              1.2,
                            ),
                          ),
                          if (test['isPremium'])
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 12, color: AppColors.darkNavy),
                                  SizedBox(width: 4),
                                  AppRichText.setTextPoppinsStyle(
                                    context,
                                    'PRO',
                                    10,
                                    AppColors.darkNavy,
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
                      SizedBox(height: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        test['description'],
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
    
         
    
          SizedBox(height: 12),
    
          if (test['attempted'])
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightGold),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.tealGreen, size: 20),
                  SizedBox(width: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Attemped Qize: ${test['attempedQuiz']}',
                    13,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
               
        
                ],
              ),
            ),
    
          SizedBox(height: 16),
    
          // Action Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestSeriesDetailPage()));
                },
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
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'View Quizes',
                          14,
                          AppColors.white,
                          FontWeight.w700,
                          1,
                          TextAlign.center,
                          0.0,
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: AppColors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTestStat(IconData icon, String text) {
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
      shrinkWrap: true,
      itemCount: _studyMaterials.length,
      physics: NeverScrollableScrollPhysics(),
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
          // Header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPDF ? Icons.picture_as_pdf : Icons.play_circle_filled,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppRichText.setTextPoppinsStyle(
                              context,
                              material['title'],
                              16,
                              AppColors.darkNavy,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              1.2,
                            ),
                          ),
                          if (material['isPremium'])
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock, size: 12, color: AppColors.darkNavy),
                                  SizedBox(width: 4),
                                  AppRichText.setTextPoppinsStyle(
                                    context,
                                    'PRO',
                                    10,
                                    AppColors.darkNavy,
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
              ],
            ),
          ),

          // Stats Row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
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
                _buildMaterialStat(Icons.download, '${material['downloads']}'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: AppColors.lightGold),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '${material['rating']}',
                      12,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
          ),

          SizedBox(height: 16),
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

