import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee_text/marquee_direction.dart';
import 'package:marquee_text/marquee_text.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/coaching_item_modal.dart';
import 'package:tazaquiznew/models/course_item_modal.dart';
import 'package:tazaquiznew/models/daily_news_modal.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/screens/blog_Page.dart';
import 'package:tazaquiznew/screens/home_daily_current_affairs.dart';
import 'package:tazaquiznew/screens/home_streak_widget.dart';
import 'package:tazaquiznew/screens/notificationPage.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:tazaquiznew/widgets/WeeklyProgressWidget.dart';
import 'package:tazaquiznew/widgets/homePage_shimmer_progress.dart';
import 'package:tazaquiznew/widgets/home_banner.dart';
import 'package:tazaquiznew/widgets/home_coaching_profile.dart';
import 'package:tazaquiznew/widgets/home_courses.dart';
import 'package:tazaquiznew/widgets/home_live_test.dart';
import 'package:tazaquiznew/widgets/mock_test.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _banners = [];
  List<QuizItem> liveTests = [];
  List<CourseItem> popularCourses = [];
  List<CoachingItem> coachingProfiles = [];

  UserModel? _user;
  int notificationCount = 0;
  int userStreakDays = 3;
  List<QuizItem> mockTests = []; // 👈 add karo

  List<HomeSection> homePageItemData = [];
  HomeSection? quizSection;
  HomeSection? courseSection;
  HomeSection? coachingSection;
  DailyNewsModel? dailyNews;
  String _quizTitle = 'Aaj Ka Quiz';
  String _quizSubtitle = 'Current Affairs + GK + Science';
  int _quizTotalQuestions = 0;
  int _quizTimeMinutes = 0;
  bool _quizAlreadyDone = false;
  String noticeMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    await _getUserData();
    await get_home_page_data();
    await getAppBanner();
    await getNewsPoints();
    await fetchNoticeBoard();
  }

  Future<void> _refreshHome() async => await _loadHome();

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    getNotificationCount();
    await getDailyQuizCheckHome();
  }

  Future<void> fetchNoticeBoard() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final responseFuture = await authRepository.fetchNoticeBord();
    final Map<String, dynamic> apiResponse =
        responseFuture.data is String ? jsonDecode(responseFuture.data) : responseFuture.data;

    // if (apiResponse['success'] == true) {
    setState(() {
      noticeMessage = apiResponse['message'] ?? '';
    });
    print("Notice Board Message:");
    // }
  }

  Future<void> getDailyQuizCheckHome() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'user_id': _user?.id};
    final responseFuture = await authRepository.fetchDailyQuizCheckHome(data);
    final Map<String, dynamic> apiResponse =
        responseFuture.data is String ? jsonDecode(responseFuture.data) : responseFuture.data;

    if (apiResponse['success'] == true) {
      final d = apiResponse['data'];
      setState(() {
        _quizTitle = d['title'] ?? 'Aaj Ka Quiz';
        _quizSubtitle = d['subtitle'] ?? '';
        _quizTotalQuestions = d['total_questions'] ?? 0;
        _quizTimeMinutes = d['time_minutes'] ?? 0;
        _quizAlreadyDone = d['already_done'] ?? false;
      });
    }
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

  Future<void> getNewsPoints() async {
    final authRepository = Authrepository(Api_Client.dio);

    final response = await authRepository.fetchDailyNewsPoints();

    var jsonResponses = response.data;

    setState(() {
      dailyNews = DailyNewsModel.fromJson(jsonResponses);
    });

    print(dailyNews!.points.length);
  }

  Future<void> get_home_page_data() async {
    final authRepository = Authrepository(Api_Client.dio);
    final response = await authRepository.fetchHomePageData();

    if (response.statusCode == 200) {
      HomeDataResponse res = HomeDataResponse.fromJson(response.data);
      homePageItemData = res.data;

      liveTests.clear();
      mockTests.clear(); // 👈 add karo
      popularCourses.clear();
      coachingProfiles.clear();

      for (var section in homePageItemData) {
        switch (section.section) {
          case 'quiz':
            quizSection = section;
            final allQuizzes = section.items.cast<QuizItem>();
            liveTests = allQuizzes.where((q) => q.pageType != 4).toList();
            mockTests = allQuizzes.where((q) => q.pageType == 4).toList();
          case 'course':
            courseSection = section;
            popularCourses = section.items.cast<CourseItem>();
            break;
          case 'coaching':
            coachingSection = section;
            coachingProfiles = section.items.cast<CoachingItem>();
            break;
        }
      }
      setState(() {});
    }
  }

  /// ⏰ Greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _getMotivation() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Subah ka quiz diya kya? 🎯';
    if (hour >= 12 && hour < 17) return 'Aaj kuch naya seekho! 💡';
    if (hour >= 17 && hour < 21) return 'Kal ki taiyari aaj karo! 📚';
    return 'Kal phir milenge!';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Icons.wb_sunny_rounded;
    if (hour >= 12 && hour < 17) return Icons.wb_sunny_outlined;
    if (hour >= 17 && hour < 21) return Icons.nights_stay_rounded;
    return Icons.nights_stay_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (quizSection == null || liveTests.isEmpty) {
      return const Center(child: QuizShimmerUI());
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.greyS1,
        body: RefreshIndicator(
          onRefresh: _refreshHome,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              /// ── Gradient AppBar ──
              _buildAppBar(),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Banner
                    HomeBanner(imgLists: _banners),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          (noticeMessage == null || noticeMessage.isEmpty)
                              ? SizedBox.shrink()
                              : SizedBox(
                                height: 17, // give it a fixed height
                                child: MarqueeText(
                                  text: TextSpan(
                                    text: noticeMessage,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEE2929),
                                      fontSize: 12,
                                    ),
                                  ),
                                  speed: 20,
                                  textDirection: TextDirection.ltr,
                                  marqueeDirection: MarqueeDirection.rtl,
                                ),
                              ),

                          /// Weekly Progress
                          WeeklyProgressWidget(),

                          /// Streak
                          HomeStreakWidget(
                            streakDays: _quizTitle,
                            todayChallengeName: _quizSubtitle,
                            totalQuestions: _quizTotalQuestions,
                            durationMinutes: _quizTimeMinutes,
                            checkattempted: _quizAlreadyDone,
                            onStartQuiz: () {},
                          ),

                          /// Current Affairs
                          HomeDailyCurrentAffairs(dailyNews: dailyNews),

                          /// Mock Tests
                          if (mockTests.isNotEmpty) HomeMockTest(mockTests: mockTests, homeSections: quizSection!),

                          /// Live Tests
                          if (liveTests.isNotEmpty) Home_live_test(liveTests: liveTests, homeSections: quizSection!),

                          /// Popular Courses
                          if (courseSection != null && popularCourses.isNotEmpty)
                            Home_courses(popularCourses: popularCourses, homeSections: courseSection!),

                          /// Coaching
                          if (coachingSection != null && coachingProfiles.isNotEmpty)
                            CoachingProfileWidget(coachingProfiles: coachingProfiles, homeSections: coachingSection!),

                          /// Achievements
                          _buildAchievementsSection(),

                          const SizedBox(height: 24),
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

  // ─────────────────────────────────────────────
  /// 🏆 Achievements
  // ─────────────────────────────────────────────
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
                  gradient: LinearGradient(colors: [AppColors.lightGold, const Color(0xFFFDD835)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events, size: 18, color: AppColors.darkNavy),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Achievements',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
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
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkNavy)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.greyS600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  /// 🎨 Gradient AppBar
  // ─────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: AppColors.white,
      leading: Padding(padding: const EdgeInsets.all(6), child: Image.asset('assets/images/logo.png')),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _user?.username ?? '👋 Hello!',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getGreetingIcon(), color: Colors.orangeAccent, size: 13),
              const SizedBox(width: 5),
              Text(
                _getGreeting(),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),

              Text("•", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(width: 6),

              const SizedBox(width: 6),

              Text(
                _getMotivation(),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      actions: [
        /// 🔔 Notification
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: AppColors.darkNavy, size: 24),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage()));
              },
            ),
            if (notificationCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(color: AppColors.tealGreen, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
