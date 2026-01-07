import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/attempedQuizHistory.dart';
import 'package:tazaquiznew/screens/help&SupportPage.dart';
import 'package:tazaquiznew/screens/paymentHistory.dart';
import 'package:tazaquiznew/screens/splash.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';
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
    _user = await SessionManager.getUser();
    setState(() {});
  }

  final Map<String, dynamic> _statistics = {'coursesEnrolled': 8, 'testsCompleted': 45, 'totalXP': 12450, 'rank': 42};

  Future<void> handleLogout(BuildContext context) async {
    await SessionManager.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => SplashScreen()), (route) => false);
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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
                _buildRegisteredInfo(),
                _buildStatsCards(),
                _buildQuickActions(),
                _buildAccountSettings(),
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.orange]),
                          border: Border.all(color: AppColors.white, width: 3),
                        ),
                        child: Center(
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            _getInitials(_user?.username),
                            24,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppRichText.setTextPoppinsStyle(
                              context,
                              _user?.username ?? 'Student',
                              18,
                              AppColors.white,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                            SizedBox(height: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Member since ${_user?.createdAt ?? 'N/A'}',
                              11,
                              AppColors.white.withOpacity(0.75),
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
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisteredInfo() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.greyS200, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, size: 14, color: AppColors.greyS600),
              SizedBox(width: 8),
              Expanded(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  _user?.email ?? 'Not provided',
                  12,
                  AppColors.greyS700,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: AppColors.greyS600),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                context,
                _user?.phone ?? 'Not provided',
                12,
                AppColors.greyS700,
                FontWeight.w500,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 15, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, _user?.email ?? 'Not provided'),
          SizedBox(height: 12),
          _buildInfoRow(Icons.phone_outlined, _user?.phone ?? 'Not provided'),
          SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today_outlined, 'Joined ${_user?.createdAt ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.1), shape: BoxShape.circle),
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
            2,
            TextAlign.left,
            0.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Courses', '${_statistics['coursesEnrolled']}', Icons.school_outlined, [
              AppColors.tealGreen,
              AppColors.tealGreen.withOpacity(0.7),
            ]),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildStatCard('Tests Done', '${_statistics['testsCompleted']}', Icons.quiz_outlined, [
              AppColors.oxfordBlue,
              AppColors.darkNavy,
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.25), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  value,
                  24,
                  AppColors.white,
                  FontWeight.w800,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  label,
                  12,
                  AppColors.white.withOpacity(0.9),
                  FontWeight.w600,
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

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Quick Actions',
            18,
            AppColors.darkNavy,
            FontWeight.w800,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionButton('My Courses', Icons.play_circle_outline, AppColors.oxfordBlue, () {})),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton('Quiz History', Icons.history, AppColors.tealGreen, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QuizHistoryPage()));
                }),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Study Materials', Icons.book, AppColors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StudyMaterialPurchaseHistoryScreen()),
                  );
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton('All Payments', Icons.payment, AppColors.darkNavy, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentHistoryPage()));
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 8),
            Flexible(
              child: AppRichText.setTextPoppinsStyle(
                context,
                title,
                13,
                color,
                FontWeight.w700,
                1,
                TextAlign.center,
                0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Settings',
            18,
            AppColors.darkNavy,
            FontWeight.w800,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 16),
          _buildSettingItem(Icons.share, 'Refer and Earn', () {}),
          Divider(height: 28, color: AppColors.greyS300),
          _buildSettingItem(Icons.policy, 'Privacy Policy', () {}),
          Divider(height: 28, color: AppColors.greyS300),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ContactUsPage()));
            },
            child: _buildSettingItem(Icons.help_outline, 'Help & Support', () {}),
          ),
          Divider(height: 28, color: AppColors.greyS300),
          _buildSettingItem(Icons.logout, 'Logout', () async {
            await handleLogout(context);
          }, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLogout ? AppColors.red.withOpacity(0.1) : AppColors.tealGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: isLogout ? AppColors.red : AppColors.tealGreen),
            ),
            SizedBox(width: 14),
            Expanded(
              child: AppRichText.setTextPoppinsStyle(
                context,
                title,
                15,
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
      ),
    );
  }
}
