import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/seriesWiseQuizList.dart';
import 'package:tazaquiznew/utils/richText.dart';

class QuizListScreen extends StatefulWidget {
  @override
  _QuizListScreenState createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  String _selectedCategory = 'All';
  bool _isGridView = true;
  String _selectedFilter = 'live';
  final List<String> _categories = ['All', 'Mathematics', 'Science', 'English', 'Physics', 'History'];

  final List<Map<String, dynamic>> _quizzes = [
    {
      'title': 'Advanced Calculus',
      'subtitle': 'Test your skills',
      'category': 'Mathematics',
      'difficulty': 'Advanced',
      'questions': 25,
      'duration': '30 min',
      'participants': 5420,
      'isPremium': false,
      'color1': Color(0xFF1A4D6D),
      'color2': Color(0xFF28A194),
    },
    {
      'title': 'Organic Chemistry',
      'subtitle': 'Master the basics',
      'category': 'Science',
      'difficulty': 'Intermediate',
      'questions': 20,
      'duration': '25 min',
      'participants': 3890,
      'isPremium': true,
      'color1': Color(0xFF28A194),
      'color2': Color(0xFF1A4D6D),
    },
    {
      'title': 'Physics Laws',
      'subtitle': 'Quick revision',
      'category': 'Physics',
      'difficulty': 'Beginner',
      'questions': 15,
      'duration': '20 min',
      'participants': 8920,
      'isPremium': false,
      'color1': Color(0xFF0C3756),
      'color2': Color(0xFF1A4D6D),
    },
    {
      'title': 'English Grammar',
      'subtitle': 'Complete guide',
      'category': 'English',
      'difficulty': 'Intermediate',
      'questions': 30,
      'duration': '35 min',
      'participants': 6750,
      'isPremium': false,
      'color1': Color(0xFF1A4D6D),
      'color2': Color(0xFF0C3756),
    },
    {
      'title': 'World History',
      'subtitle': 'Ancient civilizations',
      'category': 'History',
      'difficulty': 'Advanced',
      'questions': 40,
      'duration': '45 min',
      'participants': 4560,
      'isPremium': true,
      'color1': Color(0xFF28A194),
      'color2': Color(0xFF0C3756),
    },
    {
      'title': 'Algebra Basics',
      'subtitle': 'Foundation course',
      'category': 'Mathematics',
      'difficulty': 'Beginner',
      'questions': 18,
      'duration': '22 min',
      'participants': 7200,
      'isPremium': false,
      'color1': Color(0xFF1A4D6D),
      'color2': Color(0xFF28A194),
    },
  ];

  List<Map<String, dynamic>> get _filteredQuizzes {
    if (_selectedCategory == 'All') return _quizzes;
    return _quizzes.where((quiz) => quiz['category'] == _selectedCategory).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCategoriesSection()),
          _isGridView ? _buildGridView() : _buildListView(),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.quiz, color: AppColors.white, size: 22),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Available Quizzes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.filter_list, color: AppColors.white, size: 22),
                            ),
                            onPressed: _showFilterBottomSheet,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 16),
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategory == _categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = _categories[index];
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppColors.tealGreen.withOpacity(0.3) : AppColors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 12 : 6,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.greyS700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final quiz = _filteredQuizzes[index];
          return _buildGridCard(quiz);
        }, childCount: _filteredQuizzes.length),
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final quiz = _filteredQuizzes[index];
        return _buildListCard(quiz);
      }, childCount: _filteredQuizzes.length),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> quiz) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [quiz['color1'], quiz['color2']],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: quiz['color1'].withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Color(0xFFFFB800), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        'UPCOMING',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white),
                      ),
                    ),
                    if (quiz['isPremium'])
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                        child: Icon(Icons.workspace_premium, color: AppColors.white, size: 14),
                      ),
                  ],
                ),
                Spacer(),
                Text(
                  quiz['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  quiz['subtitle'],
                  style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.8), fontFamily: 'Poppins'),
                ),
                SizedBox(height: 12),

                InkWell(
                  onTap: () {
                    // quiz['isPremium'] ?

                    Navigator.push(context, MaterialPageRoute(builder: (context) => TestSeriesDetailPage()));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: quiz['color1'], size: 16),
                        SizedBox(width: 4),
                        Text(
                          quiz['isPremium'] ? 'Unlock' : 'Join Now',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: quiz['color1']),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> quiz) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [quiz['color1'], quiz['color2']],
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                  ),
                ),
                Center(child: Icon(Icons.quiz, size: 50, color: AppColors.white.withOpacity(0.9))),
                if (quiz['isPremium'])
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                      child: Icon(Icons.workspace_premium, color: AppColors.white, size: 14),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Color(0xFFFFB800), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'UPCOMING',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz['title'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(quiz['subtitle'], style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tealGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          quiz['difficulty'],
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.tealGreen),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.question_answer, size: 12, color: AppColors.greyS500),
                      SizedBox(width: 3),
                      Text('${quiz['questions']}', style: TextStyle(fontSize: 11, color: AppColors.greyS600)),
                      SizedBox(width: 8),
                      Icon(Icons.timer, size: 12, color: AppColors.greyS500),
                      SizedBox(width: 3),
                      Text(quiz['duration'], style: TextStyle(fontSize: 11, color: AppColors.greyS600)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [quiz['color1'], quiz['color2']]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: AppColors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          quiz['isPremium'] ? 'Unlock Quiz' : 'Join Now',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    String tempSelectedFilter = _selectedFilter;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
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
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.filter_list, color: AppColors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Filter Quizzes',
                        20,
                        AppColors.darkNavy,
                        FontWeight.w900,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.greyS600),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.greyS200),

              // Filter options
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Select Quiz Type',
                      16,
                      AppColors.darkNavy,
                      FontWeight.w800,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 8),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Choose one option to filter quizzes',
                      13,
                      AppColors.greyS600,
                      FontWeight.w500,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 20),

                    // Live Quiz Option
                    _buildFilterOption(
                      context: context,
                      icon: Icons.radio_button_checked,
                      title: 'Live Quiz',
                      subtitle: 'Show quizzes that are currently live',
                      isSelected: tempSelectedFilter == 'live',
                      activeColor: AppColors.red,
                      onTap: () {
                        setModalState(() {
                          tempSelectedFilter = 'live';
                        });
                      },
                    ),

                    SizedBox(height: 12),

                    // Upcoming Quiz Option
                    _buildFilterOption(
                      context: context,
                      icon: Icons.schedule,
                      title: 'Upcoming Quiz',
                      subtitle: 'Show quizzes scheduled for later',
                      isSelected: tempSelectedFilter == 'upcoming',
                      activeColor: AppColors.tealGreen,
                      onTap: () {
                        setModalState(() {
                          tempSelectedFilter = 'upcoming';
                        });
                      },
                    ),

                    SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilter(tempSelectedFilter);
                          Navigator.pop(context);
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
                            padding: EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.white, size: 22),
                                SizedBox(width: 10),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  'Apply Filter',
                                  16,
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
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(colors: [activeColor.withOpacity(0.15), activeColor.withOpacity(0.08)])
                  : null,
          color: isSelected ? null : AppColors.greyS1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : AppColors.greyS300!, width: isSelected ? 2.5 : 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.2) : AppColors.greyS200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? activeColor : AppColors.greyS600, size: 26),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    title,
                    15,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 4),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    subtitle,
                    12,
                    AppColors.greyS600,
                    FontWeight.w500,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? activeColor : AppColors.greyS400, width: 2.5),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
