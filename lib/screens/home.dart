import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/coaching_item_modal.dart';
import 'package:tazaquiznew/models/course_item_modal.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/screens/buyCourse.dart';
import 'package:tazaquiznew/screens/notificationPage.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/screens/testSeries.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:tazaquiznew/widgets/WeeklyProgressWidget.dart';
import 'package:tazaquiznew/widgets/home_banner.dart';
import 'package:tazaquiznew/widgets/home_coaching_profile.dart';
import 'package:tazaquiznew/widgets/home_courses.dart';
import 'package:tazaquiznew/widgets/home_live_test.dart';
import 'package:tazaquiznew/widgets/home_study_material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
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
  // Sections
  HomeSection? quizSection;
  HomeSection? courseSection;
  HomeSection? coachingSection;
  HomeSection? studySection;
  @override
  void initState() {
    super.initState();
    _getUserData();
    get_home_page_data();
    getAppBanner();
  }

  void _getUserData() async {
    // Fetch and set user data here if needed
    _user = await SessionManager.getUser();
    setState(() {});
    getNotificationCount();
  }

  void getAppBanner() async {
    // Fetch app banner data from API if needed
    Authrepository authRepository = Authrepository(Api_Client.dio);

    final responseFuture = await authRepository.fetchAppBanner();

    var jsonResponses = jsonDecode(responseFuture.data);
    _banners = jsonResponses['slider'];
    setState(() {});
    // You can use Authrepository's fetchAppBanner method here
  }

  void getNotificationCount() async {
    // Fetch notification count from API if needed
    Authrepository authRepository = Authrepository(Api_Client.dio);

    final data = {'user_id': _user?.id};
    final responseFuture = await authRepository.fetchNotificationCount(data);
    var jsonResponsesCount = jsonDecode(responseFuture.data);

    setState(() {
      notificationCount = jsonResponsesCount['count'];
    });
    // Handle the response as needed
  }

  void get_home_page_data() async {
    // Fetch home page data from API if needed
    Authrepository authRepository = Authrepository(Api_Client.dio);

    final responseFuture = await authRepository.fetchHomePageData();
    print(responseFuture.statusCode);
    if (responseFuture.statusCode == 200) {
      var jsonResponse = responseFuture.data;
      HomeDataResponse response = HomeDataResponse.fromJson(jsonResponse);
      homePageItemData = response.data;

      liveTests.clear();
      popularCourses.clear();
      coachingProfiles.clear();
      studyMaterials.clear();
      for (var section in homePageItemData) {
        if (section.section == 'quiz') {
          quizSection = section;

          liveTests = section.items.cast<QuizItem>();
        } else if (section.section == 'course') {
          courseSection = section;
          popularCourses = section.items.cast<CourseItem>();
        } else if (section.section == 'coaching') {
          coachingSection = section;
          coachingProfiles = section.items.cast<CoachingItem>();
        } else if (section.section == 'study_material') {
          studySection = section;
          studyMaterials = section.items.cast<StudyMaterialItem>();
        }
      }

      setState(() {});

      // Process the data as needed
    } else {
      // Handle error case
    }

    // Handle the response as needed
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (quizSection == null || quizSection!.items.isEmpty || liveTests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min, // ⭐ IMPORTANT
            children: const [
              SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text("Loading Please wait...", style: TextStyle(fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeBanner(imgLists: _banners),
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatsSection(),

                        Home_live_test(liveTests: liveTests, homeSections: quizSection!),
                        Home_courses(popularCourses: popularCourses, homeSections: courseSection!),
                        CoachingProfileWidget(coachingProfiles: coachingProfiles, homeSections: coachingSection!),
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
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 7, top: 2, bottom: 2),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            '${_user?.username ?? '👋'}',
            15,
            AppColors.darkNavy,
            FontWeight.w700,
            1,
            TextAlign.left,
            0.0,
          ),
          AppRichText.setTextPoppinsStyle(
            context,
            'Ready to learn today?',
            11,
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
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_outlined, color: AppColors.darkNavy, size: 22),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
              },
            ),

            /// Notification Badge
            if (notificationCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.tealGreen, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),

        SizedBox(width: 4),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [WeeklyProgressWidget()]),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 8),
      padding: EdgeInsets.all(15),
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
                  gradient: LinearGradient(colors: [AppColors.lightGold, Color(0xFFFDD835)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 17),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Recent Achievements',
                15,
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
      padding: EdgeInsets.only(top: 12, bottom: 12, left: 8, right: 8),
      decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
