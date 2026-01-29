import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tazaquiz/API/api_client.dart';
import 'package:tazaquiz/authentication/AuthRepository.dart';
import 'package:tazaquiz/constants/app_colors.dart';
import 'package:tazaquiz/models/coaching_item_modal.dart';
import 'package:tazaquiz/models/course_item_modal.dart';
import 'package:tazaquiz/models/home_page_modal.dart';
import 'package:tazaquiz/models/login_response_model.dart';
import 'package:tazaquiz/models/quizItem_modal.dart';
import 'package:tazaquiz/models/studyMaterial_modal.dart';
import 'package:tazaquiz/screens/notificationPage.dart';
import 'package:tazaquiz/utils/richText.dart';
import 'package:tazaquiz/utils/session_manager.dart';
import 'package:tazaquiz/widgets/WeeklyProgressWidget.dart';
import 'package:tazaquiz/widgets/homePage_shimmer_progress.dart';
import 'package:tazaquiz/widgets/home_banner.dart';
import 'package:tazaquiz/widgets/home_coaching_profile.dart';
import 'package:tazaquiz/widgets/home_courses.dart';
import 'package:tazaquiz/widgets/home_live_test.dart';
import 'package:tazaquiz/widgets/home_study_material.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _bannerTimer;

  List _banners = [];
  List<QuizItem> liveTests = [];
  List<CourseItem> popularCourses = [];
  List<CoachingItem> coachingProfiles = [];
  List<StudyMaterialItem> studyMaterials = [];

  UserModel? _user;
  int notificationCount = 0;

  List<HomeSection> homePageItemData = [];

  HomeSection? quizSection;
  HomeSection? courseSection;
  HomeSection? coachingSection;
  HomeSection? studySection;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  /// 🔄 Load everything
  Future<void> _loadHome() async {
    await _getUserData();
    await get_home_page_data();
    await getAppBanner();
  }

  /// 🔄 Pull to refresh
  Future<void> _refreshHome() async {
    await _loadHome();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    getNotificationCount();
  }

  Future<void> getAppBanner() async {
    final authRepository = Authrepository(Api_Client.dio);
    final response = await authRepository.fetchAppBanner();
    final jsonResponses = jsonDecode(response.data);
    _banners = jsonResponses['slider'] ?? [];
    setState(() {});
  }

  Future<void> getNotificationCount() async {
    final authRepository = Authrepository(Api_Client.dio);
    final data = {'user_id': _user?.id};
    final response = await authRepository.fetchNotificationCount(data);
    final jsonResponses = jsonDecode(response.data);

    setState(() {
      notificationCount = jsonResponses['count'] ?? 0;
    });
  }

  Future<void> get_home_page_data() async {
    final authRepository = Authrepository(Api_Client.dio);
    final response = await authRepository.fetchHomePageData();

    if (response.statusCode == 200) {
      HomeDataResponse res = HomeDataResponse.fromJson(response.data);
      homePageItemData = res.data;

      liveTests.clear();
      popularCourses.clear();
      coachingProfiles.clear();
      studyMaterials.clear();

      for (var section in homePageItemData) {
        switch (section.section) {
          case 'quiz':
            quizSection = section;
            liveTests = section.items.cast<QuizItem>();
            break;
          case 'course':
            courseSection = section;
            popularCourses = section.items.cast<CourseItem>();
            break;
          case 'coaching':
            coachingSection = section;
            coachingProfiles = section.items.cast<CoachingItem>();
            break;
          case 'study_material':
            studySection = section;
            studyMaterials = section.items.cast<StudyMaterialItem>();
            break;
        }
      }
      setState(() {});
    }
  }

  Widget greetingWidget(BuildContext context) {
    // Determine greeting
    final hour = DateTime.now().hour;
    String greeting = 'Hello';
    IconData icon = Icons.wb_sunny; // Default sun

    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny;
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_sunny_outlined;
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
      icon = Icons.nights_stay;
    } else {
      greeting = 'Good Night';
      icon = Icons.nights_stay_outlined;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.orangeAccent, // Stylish color
          size: 16,
        ),
        const SizedBox(width: 6),
        AppRichText.setTextPoppinsStyle(
          context,
          greeting,
          12, // Font size
          Colors.grey.shade600, // Text color
          FontWeight.w500,
          1,
          TextAlign.left,
          0,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (quizSection == null || liveTests.isEmpty) {
      return const Center(child: QuizShimmerUI());
    }

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHome,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    HomeBanner(imgLists: _banners),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _buildStatsSection(),

                          if (quizSection != null && liveTests.isNotEmpty)
                            Home_live_test(liveTests: liveTests, homeSections: quizSection!),

                          if (courseSection != null && popularCourses.isNotEmpty)
                            Home_courses(popularCourses: popularCourses, homeSections: courseSection!),

                          if (coachingSection != null && coachingProfiles.isNotEmpty)
                            CoachingProfileWidget(coachingProfiles: coachingProfiles, homeSections: coachingSection!),

                          if (studySection != null && studyMaterials.isNotEmpty)
                            HomeStudyMaterials(studyMaterials: studyMaterials, homeSections: studySection!),

                          _buildAchievementsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 APP BAR
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(6), child: Image.asset('assets/images/logo.png')),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            _user?.username ?? "👋",
            15,
            AppColors.darkNavy,
            FontWeight.w700,
            1,
            TextAlign.left,
            0,
          ),
          greetingWidget(context),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage()));
              },
            ),
            if (notificationCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: AppColors.tealGreen,
                  child: Text(notificationCount.toString(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(child: WeeklyProgressWidget());
  }
  

  /// 🏆 ACHIEVEMENTS
  Widget _buildAchievementsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, Color(0xFFFDD835)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events, size: 18, color: AppColors.darkNavy),
              ),
              const SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Recent Achievements',
                15,
                AppColors.darkNavy,
                FontWeight.w800,
                1,
                TextAlign.left,
                0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _achievementItem(
            title: 'First Test Completed',
            time: 'Pending',
            icon: Icons.check_circle,
            color: AppColors.tealGreen,
          ),
          const SizedBox(height: 12),
          _achievementItem(
            title: 'Week Streak Master',
            time: 'Pending',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _achievementItem(title: 'Top 10% Scorer', time: 'Pending', icon: Icons.star, color: AppColors.lightGold),
        ],
      ),
    );
  }

  Widget _achievementItem({required String title, required String time, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  title,
                  13,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0,
                ),
                const SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  time,
                  11,
                  AppColors.greyS600,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
