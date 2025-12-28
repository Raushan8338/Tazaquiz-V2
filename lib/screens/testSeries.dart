import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'dart:async';

import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/utils/richText.dart';

class LiveTestSeriesPage extends StatefulWidget {
  @override
  _LiveTestSeriesPageState createState() => _LiveTestSeriesPageState();
}

class _LiveTestSeriesPageState extends State<LiveTestSeriesPage> with SingleTickerProviderStateMixin {
   //hyggtt
  late TabController _tabController;
  int _selectedFilter = 0;

  final List<String> _filters = ['All', 'Live Now', 'Upcoming', 'Completed'];

  final List<Map<String, dynamic>> _testSeries = [
    {
      'title': 'Advanced Mathematics Championship',
      'subject': 'Mathematics',
      'status': 'live',
      'participants': 1234,
      'duration': '60 min',
      'questions': 30,
      'difficulty': 'Hard',
      'prize': '₹10,000',
      'startTime': '10:00 AM',
      'endTime': '11:00 AM',
      'timeLeft': {'hours': 0, 'minutes': 15, 'seconds': 30},
    },
    {
      'title': 'Science Quiz Battle',
      'subject': 'Science',
      'status': 'upcoming',
      'participants': 856,
      'duration': '45 min',
      'questions': 25,
      'difficulty': 'Medium',
      'prize': '₹5,000',
      'startTime': '2:00 PM',
      'endTime': '2:45 PM',
      'timeLeft': {'hours': 3, 'minutes': 45, 'seconds': 0},
    },
    {
      'title': 'General Knowledge Sprint',
      'subject': 'GK',
      'status': 'upcoming',
      'participants': 2341,
      'duration': '30 min',
      'questions': 40,
      'difficulty': 'Easy',
      'prize': '₹3,000',
      'startTime': '4:00 PM',
      'endTime': '4:30 PM',
      'timeLeft': {'hours': 5, 'minutes': 50, 'seconds': 0},
    },
    {
      'title': 'Physics Mastery Challenge',
      'subject': 'Physics',
      'status': 'completed',
      'participants': 1892,
      'duration': '50 min',
      'questions': 28,
      'difficulty': 'Hard',
      'prize': '₹8,000',
      'winner': 'Rahul Sharma',
      'yourRank': 42,
    },
    {
      'title': 'English Grammar Test',
      'subject': 'English',
      'status': 'live',
      'participants': 678,
      'duration': '40 min',
      'questions': 35,
      'difficulty': 'Medium',
      'prize': '₹4,000',
      'startTime': '10:30 AM',
      'endTime': '11:10 AM',
      'timeLeft': {'hours': 0, 'minutes': 25, 'seconds': 45},
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                _buildFeaturedBanner(),
                _buildStatsSection(),
                _buildFilterSection(),
                _buildTestSeriesList(),
                SizedBox(height: 20),
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
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      // actions: [
      //   IconButton(
      //     icon: Container(
      //       padding: EdgeInsets.all(8),
      //       decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      //       child: Icon(Icons.notifications_outlined, color: AppColors.white, size: 20),
      //     ),
      //     onPressed: () {},
      //   ),
      //   IconButton(
      //     icon: Container(
      //       padding: EdgeInsets.all(8),
      //       decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      //       child: Icon(Icons.filter_list, color: AppColors.white, size: 20),
      //     ),
      //     onPressed: () => _showFilterSheet(),
      //   ),
      // ],
       
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
                top: -20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: 60, right: 60, top: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.bolt, color: AppColors.darkNavy, size: 24),
                          ),
                          SizedBox(width: 12),
                          AppRichText.setTextPoppinsStyle(
                              context,
                              'Live Test Series',
                              24,
                              AppColors.white,
                              FontWeight.w900,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          
                        ],
                      ),
                      SizedBox(height: 6),
                      
                      
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

  Widget _buildFeaturedBanner() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightGold, AppColors.lightGoldS2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.lightGold.withOpacity(0.5), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.darkNavy, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.star, color: AppColors.lightGold, size: 14),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                              context,
                              'FEATURED',
                              10,
                              AppColors.white,
                              FontWeight.w900,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                   
                  ],
                ),
              ),
              Spacer(),
              Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 32),
            ],
          ),
          SizedBox(height: 16),
          AppRichText.setTextPoppinsStyle(
              context,
              'Weekly Championship',
              20,
              AppColors.darkNavy,
              FontWeight.w900,
              1,
              TextAlign.left,
              0.0,
            ),
         
          SizedBox(height: 8),
          AppRichText.setTextPoppinsStyle(
              context,
              'Win exciting prizes worth ₹500',
              14,
              AppColors.tealGreen,
              FontWeight.w600,
              1,
              TextAlign.left,
              0.0,
            ),
         
          SizedBox(height: 16),
          Row(
            children: [
              _buildBannerStat(Icons.people, '5,234', 'Players'),
              SizedBox(width: 20),
              _buildBannerStat(Icons.calendar_today, 'Sunday', '8:00 PM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.darkNavy.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.darkNavy, size: 18),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRichText.setTextPoppinsStyle(
              context,
              value,
              14,
              AppColors.darkNavy,
              FontWeight.w700,
              1,
              TextAlign.left,
              0.0,
            ),
            AppRichText.setTextPoppinsStyle(
              context,
              label,
              11,
              AppColors.tealGreen,
              FontWeight.normal,
              1,
              TextAlign.left,
              0.0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(Icons.trending_up, '2,450', 'Your Rank', AppColors.tealGreen)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.emoji_events, '15', 'Tests Won', AppColors.darkNavy)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.star, '12,340', 'Total XP', AppColors.oxfordBlue)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          AppRichText.setTextPoppinsStyle(
              context,
              value,
              18,
              color,
              FontWeight.w900,
              1,
              TextAlign.left,
              0.0,
            ),
          AppRichText.setTextPoppinsStyle(
              context,
              label,
              11,
              AppColors.greyS600,
              FontWeight.normal,
              1,
              TextAlign.center,
              0.0,
            ),
          
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))
                  else
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  _filters[index],
                  14,
                  isSelected ? AppColors.white : AppColors.greyS700,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0.0,
                ),
               
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestSeriesList() {
    return Column(
      children: _testSeries.map((test) {
        if (_selectedFilter == 1 && test['status'] != 'live') return SizedBox.shrink();
        if (_selectedFilter == 2 && test['status'] != 'upcoming') return SizedBox.shrink();
        if (_selectedFilter == 3 && test['status'] != 'completed') return SizedBox.shrink();

        if (test['status'] == 'live') {
          return _buildLiveTestCard(test);
        } else if (test['status'] == 'upcoming') {
          return _buildUpcomingTestCard(test);
        } else {
          return _buildCompletedTestCard(test);
        }
      }).toList(),
    );
  }

  Widget _buildLiveTestCard(Map<String, dynamic> test) {
    return InkWell(
      onTap: (){
         Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveTestScreen()));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                            ),
                            SizedBox(width: 6),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'LIVE NOW',
                              14,
                              AppColors.white,
                              FontWeight.w900,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                           
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.bolt, color: AppColors.darkNavy, size: 24),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  AppRichText.setTextPoppinsStyle(
                              context,
                              test['title'],
                              18,
                              AppColors.white,
                              FontWeight.w800,
                              2,
                              TextAlign.left,
                              0.0,
                            ),
                 
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AppRichText.setTextPoppinsStyle(
                              context,
                              test['subject'],
                              11,
                              AppColors.lightGold,
                              FontWeight.w600,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                    
                      ),
                      SizedBox(width: 8),
                      AppRichText.setTextPoppinsStyle(
                            context,
                            '${test['questions']} Questions • ${test['duration']}',
                            12,
                            AppColors.white.withOpacity(0.8),
                            FontWeight.normal,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                     
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppRichText.setTextPoppinsStyle(
                            context,
                            'Time Left',
                            11,
                            AppColors.white.withOpacity(0.7),
                            FontWeight.normal,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                            SizedBox(height: 4),
                            AppRichText.setTextPoppinsStyle(
                            context,
                            '${test['timeLeft']['minutes'].toString().padLeft(2, '0')}:${test['timeLeft']['seconds'].toString().padLeft(2, '0')}',
                            24,
                            AppColors.lightGold,
                            FontWeight.w900,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                           
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: AppColors.lightGold, size: 16),
                                SizedBox(width: 4),
                                AppRichText.setTextPoppinsStyle(
                                    context,
                                    '${test['participants']} playing',
                                    12,
                                    AppColors.white,
                                    FontWeight.w600,
                                    1,
                                    TextAlign.left,
                                    0.0,
                                  ),
                               
                              ],
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(8)),
                              child:  AppRichText.setTextPoppinsStyle(
                                context,
                                'Join Now',
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTestCard(Map<String, dynamic> test) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.tealGreen, size: 14),
                    SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'UPCOMING',
                      11,
                      AppColors.tealGreen,
                      FontWeight.w900,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                   
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 14),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                                context,
                                test['prize'],
                                11,
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
          SizedBox(height: 16),
          AppRichText.setTextPoppinsStyle(
                              context,
                              test['title'],
                              18,
                              AppColors.darkNavy,
                              FontWeight.w800,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
         
          SizedBox(height: 8),
          Row(
            children: [
              _buildTestInfoChip(Icons.subject, test['subject'], AppColors.tealGreen),
              SizedBox(width: 8),
              _buildTestInfoChip(Icons.quiz, '${test['questions']} Q', AppColors.darkNavy),
              SizedBox(width: 8),
              _buildTestInfoChip(Icons.timer, test['duration'], AppColors.oxfordBlue),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                              context,
                              'Starts In',
                              11,
                              AppColors.greyS600,
                              FontWeight.normal,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCountdownBox(test['timeLeft']['hours'].toString(), 'HRS'),
                          SizedBox(width: 4),
                          AppRichText.setTextPoppinsStyle(
                          context,
                          ':',
                          11,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                       
                          SizedBox(width: 4),
                          _buildCountdownBox(test['timeLeft']['minutes'].toString().padLeft(2, '0'), 'MIN'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                        context,
                        '${test['participants']} registered',
                        11,
                        AppColors.white,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                      
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active, size: 14, color: AppColors.white),
                              SizedBox(width: 6),
                              AppRichText.setTextPoppinsStyle(
                                context,
                                'Remind Me',
                                12,
                                AppColors.white,
                                FontWeight.w700,
                                1,
                                TextAlign.left,
                                0.0,
                              ),
                             
                            ],
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

  Widget _buildCompletedTestCard(Map<String, dynamic> test) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyS200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.greyS200, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.greyS600, size: 14),
                    SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                              context,
                              'COMPLETED',
                              11,
                              AppColors.greyS600,
                              FontWeight.w900,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                  
                  ],
                ),
              ),
              AppRichText.setTextPoppinsStyle(
                            context,
                            test['prize'],
                            14,
                            AppColors.tealGreen,
                            FontWeight.w700,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
            
            ],
          ),
          SizedBox(height: 16),
          AppRichText.setTextPoppinsStyle(
                        context,
                        test['title'],
                        18,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
          
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.lightGold, size: 20),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                      context,
                      'Winner: ${test['winner']}',
                      13,
                      AppColors.darkNavy,
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
             
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Your Rank',
                        11,
                        AppColors.greyS600,
                        FontWeight.normal,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                      SizedBox(height: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '#${test['yourRank']}',
                        24,
                        AppColors.tealGreen,
                        FontWeight.w900,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
               
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.visibility_outlined, size: 16, color: AppColors.darkNavy),
                  label: AppRichText.setTextPoppinsStyle(
                        context,
                        'View Results',
                        12,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
              
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.darkNavy, width: 2),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          AppRichText.setTextPoppinsStyle(
                        context,
                        text,
                        11,
                        color,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
          
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppRichText.setTextPoppinsStyle(
                        context,
                        value,
                        18,
                        AppColors.white,
                        FontWeight.w900,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
        
        ),
        SizedBox(height: 4),
        AppRichText.setTextPoppinsStyle(
                        context,
                        label,
                        9,
                        AppColors.greyS600,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
    
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              AppRichText.setTextPoppinsStyle(
                        context,
                        'Filter Tests',
                        20,
                        AppColors.darkNavy,
                        FontWeight.w800,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
              
                IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            SizedBox(height: 20),
            _buildFilterOption('All Subjects', true),
            _buildFilterOption('Mathematics', false),
            _buildFilterOption('Science', false),
            _buildFilterOption('English', false),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            _buildFilterOption('Easy', false),
            _buildFilterOption('Medium', false),
            _buildFilterOption('Hard', false),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.transparent,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Apply Filters',
                        16,
                        AppColors.white,
                        FontWeight.w700,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String text, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.tealGreen.withOpacity(0.1) : AppColors.greyS1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.tealGreen : AppColors.transparent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppRichText.setTextPoppinsStyle(
                        context,
                        text,
                        14,
                        AppColors.darkNavy,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
        
          if (isSelected) Icon(Icons.check_circle, color: AppColors.tealGreen, size: 20),
        ],
      ),
    );
  }
}
