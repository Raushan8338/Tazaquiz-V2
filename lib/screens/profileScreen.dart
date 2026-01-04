import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/help&SupportPage.dart';
import 'package:tazaquiznew/screens/splash.dart';
import 'package:tazaquiznew/testpage.dart' hide ContactUsPage;
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class StudentProfilePage extends StatefulWidget {
  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  UserModel? _user;
  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    // Fetch and set user data here if needed
    _user = await SessionManager.getUser();
    setState(() {});
  }

  final Map<String, dynamic> _statistics = {
    'coursesEnrolled': 8,
    'testsCompleted': 45,
    'totalXP': 12450,
    'rank': 42,
    'averageScore': 82.5,
    'studyHours': 124,
  };

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'title': 'Completed Mathematics Test',
      'score': 85,
      'date': '2 hours ago',
      'icon': Icons.quiz,
      'color': AppColors.green,
    },
    {'title': 'Downloaded Physics Notes', 'date': '5 hours ago', 'icon': Icons.download, 'color': AppColors.blue},
    {
      'title': 'Earned Achievement Badge',
      'badge': 'Top Performer',
      'date': '1 day ago',
      'icon': Icons.emoji_events,
      'color': AppColors.orange,
    },
    {'title': 'Started Chemistry Course', 'date': '2 days ago', 'icon': Icons.play_circle, 'color': AppColors.purple},
  ];

  final List<Map<String, dynamic>> _achievements = [
    {'title': 'Top Scorer', 'description': 'Scored 90+ in 5 tests', 'icon': Icons.emoji_events, 'earned': true},
    {'title': 'Quick Learner', 'description': 'Complete 10 courses', 'icon': Icons.speed, 'earned': true},
    {
      'title': 'Streak Master',
      'description': '7 day login streak',
      'icon': Icons.local_fire_department,
      'earned': false,
    },
    {'title': 'Subject Expert', 'description': 'Master one subject', 'icon': Icons.star, 'earned': false},
  ];

  Future<void> handleLogout(BuildContext context) async {
    await SessionManager.logout(); // only once

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => SplashScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: AppBar(
        title: AppRichText.setTextPoppinsStyle(
          context,
          'My Profile',
          20,
          AppColors.white,
          FontWeight.w900,
          1,
          TextAlign.left,
          0.0,
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildStatsGrid(),
                _buildQuickActions(),
                _buildRecentActivity(),
                _buildAchievements(),
                _buildAccountSettings(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildAppBar() {
  //   return SliverAppBar(
  //     expandedHeight: 120,
  //     pinned: true,
  //     backgroundColor: AppColors.darkNavy,
  //     flexibleSpace: FlexibleSpaceBar(
  //       background: Container(
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //             colors: [AppColors.darkNavy, AppColors.tealGreen],
  //           ),
  //         ),
  //         child: SafeArea(
  //           child: Padding(
  //             padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 AppRichText.setTextPoppinsStyle(
  //                   context,
  //                   'My Profile',
  //                   20,
  //                   AppColors.white,
  //                   FontWeight.w900,
  //                   1,
  //                   TextAlign.left,
  //                   0.0,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //     actions: [
  //       // IconButton(
  //       //   icon: Container(
  //       //     padding: EdgeInsets.all(8),
  //       //     decoration: BoxDecoration(
  //       //       color: AppColors.white.withOpacity(0.2),
  //       //       borderRadius: BorderRadius.circular(10),
  //       //     ),
  //       //     child: Icon(Icons.edit, color: AppColors.white, size: 20),
  //       //   ),
  //       //   onPressed: () {},
  //       // ),
  //       // IconButton(
  //       //   icon: Container(
  //       //     padding: EdgeInsets.all(8),
  //       //     decoration: BoxDecoration(
  //       //       color: AppColors.white.withOpacity(0.2),
  //       //       borderRadius: BorderRadius.circular(10),
  //       //     ),
  //       //     child: Icon(Icons.settings, color: AppColors.white, size: 20),
  //       //   ),
  //       //   onPressed: () {},
  //       // ),
  //       // SizedBox(width: 8),
  //     ],
  //   );
  // }

  Widget _buildProfileHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  border: Border.all(color: AppColors.lightGold, width: 3),
                ),
                child: Center(
                  child: AppRichText.setTextPoppinsStyle(
                    context,
                    '${_user?.username}'.substring(0, 1),
                    32,
                    AppColors.white,
                    FontWeight.w900,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '${_user?.username}',
                      20,
                      AppColors.darkNavy,
                      FontWeight.w900,
                      2,
                      TextAlign.left,
                      1.2,
                    ),
                    // SizedBox(height: 4),
                    // Container(
                    //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.lightGold.withOpacity(0.3),
                    //     borderRadius: BorderRadius.circular(6),
                    //   ),
                    //   child: AppRichText.setTextPoppinsStyle(
                    //     context,
                    //     _studentData['class'],
                    //     11,
                    //     AppColors.darkNavy,
                    //     FontWeight.w700,
                    //     1,
                    //     TextAlign.left,
                    //     0.0,
                    //   ),
                    //),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 16, color: AppColors.greyS600),
                        SizedBox(width: 4),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'STD + ${_user?.referalId}',
                          12,
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.verified_user, color: AppColors.tealGreen, size: 24),
              ),
            ],
          ),

          SizedBox(height: 20),
          Divider(),
          SizedBox(height: 16),

          _buildInfoRow(Icons.email, '${_user?.email}'),
          _buildInfoRow(Icons.phone, '${_user?.phone}'),
          _buildInfoRow(Icons.calendar_today, 'Enrolled: ${_user?.createdAt}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.tealGreen),
        ),
        SizedBox(width: 12),
        Expanded(
          child: AppRichText.setTextPoppinsStyle(
            context,
            text,
            13,
            AppColors.darkNavy,
            FontWeight.w600,
            1,
            TextAlign.left,
            0.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
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
        boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Performance Overview',
            18,
            AppColors.white,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
            padding: EdgeInsets.zero,
            children: [
              _buildStatCard('Courses', '${_statistics['coursesEnrolled']}', Icons.school),
              _buildStatCard('Tests', '${_statistics['testsCompleted']}', Icons.quiz),
              _buildStatCard('Rank', '#${_statistics['rank']}', Icons.leaderboard),
              _buildStatCard('Avg Score', '${_statistics['averageScore']}%', Icons.analytics),
              _buildStatCard('XP Points', '${_statistics['totalXP']}', Icons.stars),
              _buildStatCard('Study Hrs', '${_statistics['studyHours']}h', Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.lightGold, size: 24),
          SizedBox(height: 8),
          AppRichText.setTextPoppinsStyle(
            context,
            value,
            16,
            AppColors.white,
            FontWeight.w900,
            1,
            TextAlign.center,
            0.0,
          ),
          SizedBox(height: 2),
          AppRichText.setTextPoppinsStyle(
            context,
            label,
            10,
            AppColors.white.withOpacity(0.9),
            FontWeight.w600,
            1,
            TextAlign.center,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: AppRichText.setTextPoppinsStyle(
              context,
              'Quick Actions',
              18,
              AppColors.darkNavy,
              FontWeight.w900,
              1,
              TextAlign.left,
              0.0,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionCard('My Courses', Icons.school, AppColors.tealGreen, () {})),
              SizedBox(width: 12),
              Expanded(child: _buildActionCard('Certificates', Icons.card_membership, AppColors.darkNavy, () {})),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionCard('Test History', Icons.history, AppColors.oxfordBlue, () {})),
              SizedBox(width: 12),
              Expanded(child: _buildActionCard('Downloads', Icons.download, AppColors.tealGreen, () {})),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.white, size: 28),
            ),
            SizedBox(height: 12),
            AppRichText.setTextPoppinsStyle(
              context,
              title,
              13,
              AppColors.darkNavy,
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

  Widget _buildRecentActivity() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history, color: AppColors.white, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Recent Activity',
                18,
                AppColors.darkNavy,
                FontWeight.w900,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),

          SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recentActivity.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => Divider(height: 24),
            itemBuilder: (context, index) {
              final activity = _recentActivity[index];
              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: activity['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(activity['icon'], color: activity['color'], size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          activity['title'],
                          14,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          5,
                          TextAlign.left,
                          1.2,
                        ),
                        SizedBox(height: 2),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          activity['date'],
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
                  if (activity['score'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        '${activity['score']}%',
                        13,
                        AppColors.green,
                        FontWeight.w900,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.orange]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 20),
                  ),
                  SizedBox(width: 12),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Achievements',
                    18,
                    AppColors.darkNavy,
                    FontWeight.w900,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  '2/4 Earned',
                  11,
                  AppColors.tealGreen,
                  FontWeight.w700,
                  1,
                  TextAlign.center,
                  0.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient:
                      achievement['earned']
                          ? LinearGradient(
                            colors: [AppColors.lightGold.withOpacity(0.2), AppColors.lightGold.withOpacity(0.1)],
                          )
                          : null,
                  color: achievement['earned'] ? null : AppColors.greyS1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: achievement['earned'] ? AppColors.lightGold : AppColors.greyS300, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      achievement['icon'],
                      color: achievement['earned'] ? AppColors.tealGreen : AppColors.greyS400,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      achievement['title'],
                      13,
                      achievement['earned'] ? AppColors.darkNavy : AppColors.greyS600,
                      FontWeight.w700,
                      2,
                      TextAlign.center,
                      1.2,
                    ),
                    SizedBox(height: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      achievement['description'],
                      10,
                      AppColors.greyS600,
                      FontWeight.w500,
                      3,
                      TextAlign.center,
                      1.3,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.oxfordBlue, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.settings, color: AppColors.white, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Account Settings',
                18,
                AppColors.darkNavy,
                FontWeight.w900,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildSettingItem(Icons.lock, 'Change Password', () {}),
          Divider(height: 24),
          _buildSettingItem(Icons.notifications, 'Notification Settings', () {}),
          Divider(height: 24),
          _buildSettingItem(Icons.privacy_tip, 'Privacy Policy', () {}),
          Divider(height: 24),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ContactUsPage()));
            },
            child: _buildSettingItem(Icons.help_outline, 'Help & Support', () {}),
          ),
          Divider(height: 24),
          _buildSettingItem(Icons.logout, 'Logout', () async {
            await handleLogout(context);
          }, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLogout ? AppColors.red.withOpacity(0.1) : AppColors.greyS1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: isLogout ? AppColors.red : AppColors.tealGreen),
          ),
          SizedBox(width: 12),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              title,
              14,
              isLogout ? AppColors.red : AppColors.darkNavy,
              FontWeight.w600,
              1,
              TextAlign.left,
              0.0,
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyS400),
        ],
      ),
    );
  }
}
