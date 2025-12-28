import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/buyCourse.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/screens/testSeries.dart';
import 'package:tazaquiznew/utils/richText.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentBannerIndex = 0;
  int _selectedNavIndex = 0;
  PageController _bannerController = PageController();
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Master New Skills',
      'subtitle': 'Learn from expert instructors',
      'color1': Color(0xFF003161),
      'color2': Color(0xFF016A67),
      'icon': Icons.school,
    },
    {
      'title': 'Live Test Series',
      'subtitle': 'Compete in real-time challenges',
      'color1': Color(0xFF016A67),
      'color2': Color(0xFF000B58),
      'icon': Icons.quiz,
    },
    {
      'title': 'Track Progress',
      'subtitle': 'Monitor your learning journey',
      'color1': Color(0xFF000B58),
      'color2': Color(0xFF003161),
      'icon': Icons.analytics,
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Mathematics', 'icon': Icons.calculate, 'courses': 45},
    {'name': 'Science', 'icon': Icons.science, 'courses': 38},
    {'name': 'English', 'icon': Icons.book, 'courses': 32},
    {'name': 'Physics', 'icon': Icons.bolt, 'courses': 28},
  ];

  final List<Map<String, dynamic>> _popularCourses = [
    {
      'title': 'Complete Mathematics',
      'instructor': 'Dr. Sarah Johnson',
      'rating': 4.8,
      'students': 12450,
      'price': 2499,
      'image': 'math',
    },
    {
      'title': 'Science Fundamentals',
      'instructor': 'Prof. Mike Chen',
      'rating': 4.6,
      'students': 8920,
      'price': 1999,
      'image': 'science',
    },
    {
      'title': 'English Grammar',
      'instructor': 'Lisa Williams',
      'rating': 4.7,
      'students': 6750,
      'price': 1499,
      'image': 'english',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerAutoPlay();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_currentBannerIndex < _banners.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      _bannerController.animateToPage(
        _currentBannerIndex,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBannerSlider(),
                  _buildStatsSection(),
                  _buildCategoriesSection(),
                  _buildPopularCoursesSection(),
                  _buildLiveTestsSection(),
                  _buildAchievementsSection(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.white,
      elevation: 0,
     // leading: Drawer(),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Hello, Student 👋',
            18,
            AppColors.darkNavy,
            FontWeight.w700,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 2),
          AppRichText.setTextPoppinsStyle(
            context,
            'Ready to learn today?',
            13,
            AppColors.greyS600,
            FontWeight.w500,
            1,
            TextAlign.left,
            0.0,
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.greyS1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.notifications_outlined, color: AppColors.darkNavy, size: 22),
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.tealGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBannerSlider() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth / 2.5; // Ratio 1:2.5

    return Column(
      children: [
        Container(
          height: bannerHeight,
          margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [banner['color1'], banner['color2']],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: banner['color1'].withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.lightGold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(banner['icon'], color: AppColors.darkNavy, size: 25),
                          ),
                          SizedBox(height: 16),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            banner['title'],
                            18,
                            AppColors.white,
                            FontWeight.w900,
                            1,
                            TextAlign.left,
                            1.2,
                          ),
                          SizedBox(height: 5),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            banner['subtitle'],
                            12,
                            AppColors.lightGold,
                            FontWeight.w600,
                            1,
                            TextAlign.left,
                            1.4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: _currentBannerIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: _currentBannerIndex == index
                    ? LinearGradient(
                        colors: [AppColors.tealGreen, AppColors.darkNavy],
                      )
                    : null,
                color: _currentBannerIndex == index ? null : AppColors.greyS300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
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
          AppRichText.setTextPoppinsStyle(
            context,
            'Your Progress',
            18,
            AppColors.darkNavy,
            FontWeight.w800,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('12', 'Courses', Icons.school, AppColors.tealGreen),
              _buildStatCard('45', 'Tests', Icons.quiz, AppColors.darkNavy),
              _buildStatCard('2,450', 'XP', Icons.stars, AppColors.oxfordBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 10),
        AppRichText.setTextPoppinsStyle(
          context,
          value,
          18,
          color,
          FontWeight.w900,
          1,
          TextAlign.center,
          0.0,
        ),
        SizedBox(height: 4),
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          12,
          AppColors.greyS600,
          FontWeight.w600,
          1,
          TextAlign.center,
          0.0,
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Categories',
                    20,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 4),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Explore by subject',
                    13,
                    AppColors.greyS600,
                    FontWeight.w500,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  'View All →',
                  13,
                  AppColors.tealGreen,
                  FontWeight.w700,
                  1,
                  TextAlign.right,
                  0.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return InkWell(
                onTap: () =>      Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectContentPage())),
                child: Container(
                  width: 130,
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.tealGreen, AppColors.darkNavy],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category['icon'], color: AppColors.white, size: 24),
                      ),
                      SizedBox(height: 10),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        category['name'],
                        13,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        2,
                        TextAlign.center,
                        0.0,
                      ),
                      SizedBox(height: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '${category['courses']} courses',
                        10,
                        AppColors.greyS600,
                        FontWeight.w500,
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
        ),
      ],
    );
  }

  Widget _buildPopularCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    '🔥 Popular Courses',
                    20,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 4),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Most loved by students',
                    13,
                    AppColors.greyS600,
                    FontWeight.w500,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  'View All →',
                  13,
                  AppColors.tealGreen,
                  FontWeight.w700,
                  1,
                  TextAlign.right,
                  0.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _popularCourses.length,
            itemBuilder: (context, index) {
              final course = _popularCourses[index];
              return InkWell(
                onTap: (){
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyCoursePage()));
                        },
                child: _buildCourseCard(course));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Container(
      width: 210,
      margin: EdgeInsets.only(right: 16),
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
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealGreen, AppColors.darkNavy],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.school, size: 48, color: AppColors.lightGold),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  course['title'],
                  13,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  2,
                  TextAlign.left,
                  1.2,
                ),
                SizedBox(height: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  course['instructor'],
                  11,
                  AppColors.greyS600,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.lightGold),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '${course['rating']}',
                      12,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(width: 8),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '(${course['students']})',
                      11,
                      AppColors.greyS600,
                      FontWeight.w500,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                AppRichText.setTextPoppinsStyle(
                  context,
                  '₹${course['price']}',
                  16,
                  AppColors.tealGreen,
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
    );
  }

  Widget _buildLiveTestsSection() {
    return InkWell(
      onTap: (){
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveTestSeriesPage()));
      },
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkNavy.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'LIVE',
                          11,
                          AppColors.white,
                          FontWeight.w900,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Test Starting Soon',
                    20,
                    AppColors.white,
                    FontWeight.w900,
                    1,
                    TextAlign.left,
                    1.2,
                  ),
                  SizedBox(height: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Mathematics • 234 joined',
                    13,
                    AppColors.lightGold,
                    FontWeight.w600,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      'Join Now',
                      14,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      1,
                      TextAlign.center,
                      0.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.bolt, size: 48, color: AppColors.lightGold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightGold, Color(0xFFFDD835)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Recent Achievements',
                18,
                AppColors.darkNavy,
                FontWeight.w800,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildAchievementItem('First Test Completed', '2 days ago', Icons.check_circle, AppColors.tealGreen),
          SizedBox(height: 12),
          _buildAchievementItem('Week Streak Master', '5 days ago', Icons.local_fire_department, Colors.orange),
          SizedBox(height: 12),
          _buildAchievementItem('Top 10% Scorer', '1 week ago', Icons.star, AppColors.lightGold),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyS1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  title,
                  14,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  time,
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
    );
  }

}

