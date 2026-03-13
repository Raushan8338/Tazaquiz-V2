import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/ads/banner_ads_helper.dart';
import 'package:tazaquiznew/ads/rewarded_ad_service.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/screens/mockTestScreen.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

// ─── MOCK TEST COLORS ─────────────────────────────────────────────────────────
// Deep Blue / Indigo theme — professional exam feel
const _mockPrimary = Color(0xFF1a237e); // Deep Indigo
const _mockSecondary = Color(0xFF283593); // Medium Indigo
const _mockAccent = Color(0xFF5C6BC0); // Lighter Indigo
const _mockGold = Color(0xFFFFC107); // Amber
const _mockBg = Color(0xFFF0F2FF); // Light indigo tint bg

class MockTestDetailPage extends StatefulWidget {
  final String quizId;
  final bool is_subscribed;

  MockTestDetailPage({required this.quizId, required this.is_subscribed});

  @override
  _MockTestDetailPageState createState() => _MockTestDetailPageState();
}

class _MockTestDetailPageState extends State<MockTestDetailPage> with SingleTickerProviderStateMixin {
  final RewardedAdService rewardedAdService = RewardedAdService();
  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;
  UserModel? _user;
  bool _isLoading = true;
  bool _isPurchased = false;
  int _product_sub_id = 0;
  int _isPremium = 0;
  bool _attempted = false;
  bool _isAccessible = false;
  bool _isFree = false;
  QuizItem? _currentQuiz;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    rewardedAdService.loadAd();
    bannerService.loadAd(() {
      setState(() => isBannerLoaded = true);
    });
    _getUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    bannerService.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    await fetchQuizDetails(_user!.id);
    if (!mounted) return;
    _fadeController.forward();
    setState(() {});
  }

  Future<void> fetchQuizDetails(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'quiz_id': widget.quizId.toString(), 'user_id': userid.toString()};

      final responseFuture = await authRepository.get_quizId_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        if (responseData['status'] == true && responseData['data'] != null) {
          _currentQuiz = QuizItem.fromJson(responseData['data']);
          setState(() {
            _isPurchased = _currentQuiz!.isPurchased;
            _isAccessible = widget.is_subscribed == true ? true : _currentQuiz!.isAccessible;
            _attempted = _currentQuiz!.is_attempted;
            _isFree = _currentQuiz!.price == 0 || !_currentQuiz!.isPaid;
            _isPremium = _currentQuiz!.is_premium;
            _product_sub_id = _currentQuiz!.subscription_id;
          });
        }
        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching mock test details: $e');
      setState(() => _isLoading = false);
    }
  }

  // ─── HANDLERS ────────────────────────────────────────────────────────────────

  void _handleStartMockTest() {
    if (_currentQuiz == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MockTestScreen(
              testTitle: _currentQuiz!.title.toString(),
              subject: _currentQuiz!.difficultyLevel.toString(),
              Quiz_id: widget.quizId.toString(),
            ),
      ),
    );
  }

  void _handleSubscribe() {
    if (_currentQuiz == null) return;
    // String subsCategory;
    // String sendProductId;
    // if (_isPremium == 1) {
    //   subsCategory = 'QUIZ';
    //   sendProductId = widget.quizId;
    // } else {
    //   subsCategory = 'Subscription';
    //   sendProductId = _product_sub_id.toString();
    // }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PricingPage()),
    ).then((value) {
      if (value == true) _getUserData();
    });
  }

  // ─── DIFFICULTY COLOR ─────────────────────────────────────────────────────
  Color _getDifficultyColor() {
    switch (_currentQuiz?.difficultyLevel.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFF9A825);
      case 'hard':
        return const Color(0xFFC62828);
      default:
        return _mockAccent;
    }
  }

  // ─── FORMAT DATE ──────────────────────────────────────────────────────────
  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw.trim().replaceAll(' ', 'T'));
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  $h:$m $ap';
    } catch (_) {
      return raw;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _mockBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_mockPrimary), strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                'Loading mock test...',
                style: TextStyle(color: _mockPrimary.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_currentQuiz == null) {
      return Scaffold(
        backgroundColor: _mockBg,
        appBar: AppBar(backgroundColor: _mockPrimary, title: const Text('Error')),
        body: const Center(child: Text('Test not found')),
      );
    }

    final bool canStart = _isPurchased || _isAccessible || _isFree;

    return Scaffold(
      backgroundColor: _mockBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // ── Access Banner ──
                    if (canStart) _buildAccessBanner(),
                    if (canStart) const SizedBox(height: 10),

                    // ── Course/Material Info ──
                    _buildCourseInfo(),
                    const SizedBox(height: 10),

                    // ── Mock Header Card ──
                    _buildMockHeader(),
                    const SizedBox(height: 10),

                    // ── Stats Row ──
                    _buildStatsRow(),
                    const SizedBox(height: 10),

                    // ── What to Expect ──
                    _buildExpectSection(),
                    const SizedBox(height: 10),

                    // ── Banner Ad ──
                    if (isBannerLoaded && bannerService.bannerAd != null) _buildBannerAd(),

                    // ── Main Section ──
                    if (!canStart) _buildSubscriptionSection() else _buildTestInfoSection(),
                    const SizedBox(height: 10),

                    // ── Description ──
                    if (_currentQuiz!.description.isNotEmpty) ...[_buildDescriptionCard(), const SizedBox(height: 10)],

                    // ── Instructions ──
                    if (_currentQuiz!.instruction.isNotEmpty) ...[_buildInstructionsCard(), const SizedBox(height: 10)],

                    // ── Important Info ──
                    _buildImportantInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(canStart),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 55,
      pinned: true,
      backgroundColor: _mockPrimary,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: AppRichText.setTextPoppinsStyle(
        context,
        _currentQuiz?.title ?? '',
        12,
        AppColors.white,
        FontWeight.w700,
        2,
        TextAlign.left,
        1.2,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_mockPrimary, _mockSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // ─── ACCESS BANNER ───────────────────────────────────────────────────────────

  Widget _buildAccessBanner() {
    String message;
    String subtitle;
    IconData icon;

    if (_isFree) {
      message = '🎉 Yeh Mock Test bilkul FREE hai!';
      subtitle = 'Kisi subscription ki zaroorat nahi';
      icon = Icons.celebration_outlined;
    } else if (_isPurchased) {
      message = '✅ Access Unlocked!';
      subtitle = 'Aap is mock test ke liye subscribe hain';
      icon = Icons.verified;
    } else {
      message = '🔓 Aapke plan mein included hai!';
      subtitle = 'Full access available';
      icon = Icons.lock_open_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_mockPrimary, _mockSecondary]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  message,
                  12,
                  AppColors.white,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0,
                ),
                const SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  subtitle,
                  10,
                  AppColors.white.withOpacity(0.8),
                  FontWeight.w400,
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

  // ─── COURSE INFO ─────────────────────────────────────────────────────────────

  Widget _buildCourseInfo() {
    final materialName = _currentQuiz?.Material_name ?? '';
    if (materialName.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _mockPrimary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _mockPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.library_books_outlined, color: _mockPrimary, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATERIAL NAME',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.greyS600,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                AppRichText.setTextPoppinsStyle(
                  context,
                  materialName,
                  13,
                  _mockPrimary,
                  FontWeight.w700,
                  2,
                  TextAlign.left,
                  1.2,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: _mockPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              '📚 MOCK',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _mockPrimary, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOCK HEADER CARD ────────────────────────────────────────────────────────

  Widget _buildMockHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.1), blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Colored top strip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_mockPrimary, _mockSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _buildTag(
                      icon: Icons.assignment_outlined,
                      label: 'MOCK TEST',
                      color: Colors.white,
                      bgColor: Colors.white.withOpacity(0.2),
                    ),
                    if (_currentQuiz!.difficultyLevel.isNotEmpty)
                      _buildTag(
                        icon: Icons.signal_cellular_alt,
                        label: _currentQuiz!.difficultyLevel.toUpperCase(),
                        color: _mockGold,
                        bgColor: _mockGold.withOpacity(0.2),
                      ),
                    if (_isFree)
                      _buildTag(
                        icon: Icons.lock_open,
                        label: 'FREE',
                        color: const Color(0xFF69F0AE),
                        bgColor: const Color(0xFF69F0AE).withOpacity(0.2),
                      )
                    else
                      _buildTag(
                        icon: Icons.workspace_premium,
                        label: 'PREMIUM',
                        color: _mockGold,
                        bgColor: _mockGold.withOpacity(0.2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                AppRichText.setTextPoppinsStyle(
                  context,
                  _currentQuiz!.Category_name,
                  20,
                  Colors.white,
                  FontWeight.w800,
                  3,
                  TextAlign.left,
                  1.3,
                ),
              ],
            ),
          ),

          // ── Bottom section of header card ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Series / Course
                if (_currentQuiz!.subscription_description.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.folder_open_outlined, size: 12, color: AppColors.greyS600),
                      const SizedBox(width: 5),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Series / Course',
                        10,
                        AppColors.greyS600,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _mockPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _mockPrimary.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 13, color: _mockAccent),
                        const SizedBox(width: 7),
                        Expanded(
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            _currentQuiz!.subscription_description,
                            11,
                            _mockPrimary,
                            FontWeight.w600,
                            2,
                            TextAlign.left,
                            1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Attempted badge
                if (_attempted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF43A047).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Aapne yeh test pehle attempt kiya hai',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({required IconData icon, required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ─── STATS ROW ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatBox('❓', _currentQuiz?.totalQuestions.toString() ?? '—', 'Questions'),
          const SizedBox(width: 10),
          _buildStatBox('⏱️', _currentQuiz?.timeLimit.isEmpty == false ? _currentQuiz!.timeLimit : '—', 'Minutes'),
          const SizedBox(width: 10),
          _buildStatBox('🏆', _currentQuiz?.totalMarks.toString() ?? '—', 'Marks'),
        ],
      ),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _mockPrimary.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _mockPrimary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9.5, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── WHAT TO EXPECT ──────────────────────────────────────────────────────────
  // Mock test mein kya alag milta hai — yeh section live detail mein nahi tha

  Widget _buildExpectSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mockPrimary.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.featured_play_list_outlined, 'Mock Test Features'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFeatureTile('🗂️', 'Question\nPalette', 'Jump to any question')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('🔖', 'Mark for\nReview', 'Flag & revisit later')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('⏸️', 'Pause &\nResume', 'Pick up where left')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildFeatureTile('📊', 'Detailed\nAnalysis', 'Topic-wise breakdown')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('✏️', 'Change\nAnswers', 'Edit before submit')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('📈', 'Track\nProgress', 'Compare attempts')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _mockPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _mockPrimary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _mockPrimary, height: 1.3),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.5, color: AppColors.greyS600, fontWeight: FontWeight.w400, height: 1.3),
          ),
        ],
      ),
    );
  }

  // ─── BANNER AD ───────────────────────────────────────────────────────────────

  Widget _buildBannerAd() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: bannerService.bannerAd!.size.height.toDouble(),
          width: bannerService.bannerAd!.size.width.toDouble(),
          child: AdWidget(ad: bannerService.bannerAd!),
        ),
      ),
    );
  }

  // ─── TEST INFO SECTION (available) ───────────────────────────────────────────
  // Schedule cards ki jagah yeh — mock test kab available hai

  Widget _buildTestInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Test Details', isGreen: false),
          const SizedBox(height: 14),

          // Availability
          _buildDetailRow(Icons.calendar_today_outlined, 'Available', 'Anytime — apni speed pe lo'),

          if (_currentQuiz!.startDateTime.isNotEmpty)
            _buildDetailRow(
              Icons.play_circle_outline,
              'Start Date',
              _formatDateTime(_currentQuiz!.startDateTime).split('  •  ').first,
            ),

          if (_currentQuiz!.endDateTime.isNotEmpty)
            _buildDetailRow(
              Icons.stop_circle_outlined,
              'End Date',
              _formatDateTime(_currentQuiz!.endDateTime).split('  •  ').first,
            ),

          if (_currentQuiz!.timeLimit.isNotEmpty)
            _buildDetailRow(Icons.timer_outlined, 'Duration', '${_currentQuiz!.timeLimit} Minutes'),

          _buildDetailRow(
            Icons.repeat_rounded,
            'Attempts',
            _attempted ? 'Ek baar attempt ho chuka hai' : 'Ek attempt allowed',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _mockPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: _mockPrimary, size: 15),
          ),
          const SizedBox(width: 11),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _mockPrimary)),
        ],
      ),
    );
  }

  // ─── SUBSCRIPTION SECTION ────────────────────────────────────────────────────
  // Same design as live — sirf text mock-specific hai

  Widget _buildSubscriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_mockPrimary, _mockSecondary],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -15,
                    right: -15,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: _mockGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _mockGold.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, color: _mockGold, size: 15),
                            const SizedBox(width: 6),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Premium Mock Test',
                              12,
                              _mockGold,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Unlock Full Mock Test\nSeries Access',
                        16,
                        AppColors.white,
                        FontWeight.w800,
                        2,
                        TextAlign.left,
                        1.3,
                      ),
                      const SizedBox(height: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Real exam pattern, unlimited practice',
                        11,
                        AppColors.white.withOpacity(0.7),
                        FontWeight.w400,
                        1,
                        TextAlign.left,
                        0,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '₹299',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '₹599  •  50% OFF',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '3 Months',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        Text('Full Access', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Benefits
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildBenefit(
                    Icons.assignment_outlined,
                    'Full Mock Test Series',
                    'Real exam pattern ke saath unlimited practice',
                    _mockPrimary,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.analytics_outlined,
                    'Detailed Performance Analysis',
                    'Topic-wise weak areas identify karo',
                    _mockAccent,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.compare_arrows_rounded,
                    'Answers Compare & Review',
                    'Galat answers ke solutions dekhो',
                    _mockPrimary,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.leaderboard_outlined,
                    'All India Rank',
                    'Nationwide students ke saath compare karo',
                    _mockAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _mockPrimary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  title,
                  12,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0,
                ),
                const SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  subtitle,
                  10,
                  AppColors.greyS600,
                  FontWeight.w400,
                  2,
                  TextAlign.left,
                  1.2,
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: _mockPrimary, size: 16),
        ],
      ),
    );
  }

  // ─── DESCRIPTION CARD ────────────────────────────────────────────────────────

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.description_outlined, 'Description'),
          const SizedBox(height: 10),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentQuiz!.description,
            12,
            AppColors.greyS700,
            FontWeight.w400,
            10,
            TextAlign.left,
            1.5,
          ),
        ],
      ),
    );
  }

  // ─── INSTRUCTIONS CARD ────────────────────────────────────────────────────────

  Widget _buildInstructionsCard() {
    final lines = _currentQuiz!.instruction.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.format_list_bulleted_outlined, 'Instructions'),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            AppRichText.setTextPoppinsStyle(
              context,
              _currentQuiz!.instruction,
              12,
              AppColors.greyS700,
              FontWeight.w400,
              10,
              TextAlign.left,
              1.5,
            )
          else
            ...lines.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(color: _mockPrimary, borderRadius: BorderRadius.circular(5)),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        e.value.trim(),
                        12,
                        AppColors.greyS700,
                        FontWeight.w400,
                        5,
                        TextAlign.left,
                        1.5,
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

  // ─── IMPORTANT INFO ───────────────────────────────────────────────────────────
  // Live mein "single attempt, wifi, leaderboard" tha
  // Mock mein — alag aur zyada useful info

  Widget _buildImportantInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Zaroori Baatein', isGreen: false),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.touch_app_rounded, 'Sirf ek attempt allowed hai — dhyan se attempt karo'),
          _buildInfoRow(Icons.swap_horiz_rounded, 'Koi bhi question pe jaao — koi order nahi'),
          _buildInfoRow(Icons.bookmark_border_rounded, 'Review ke liye mark karo, submit se pehle wapas aao'),
          _buildInfoRow(Icons.wifi_rounded, 'Stable internet connection zaroori hai'),
          _buildInfoRow(Icons.bar_chart_rounded, 'Submit ke baad detailed analysis milegi'),
          _buildInfoRow(Icons.timer_outlined, 'Timer chalta rahega — pause pe bhi time count hoga'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _mockPrimary),
          const SizedBox(width: 9),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              text,
              11,
              AppColors.greyS700,
              FontWeight.w500,
              2,
              TextAlign.left,
              0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION HEAD ─────────────────────────────────────────────────────────────

  Widget _buildSectionHead(IconData icon, String label, {bool isGreen = true}) {
    final Color headColor = isGreen ? _mockPrimary : _mockSecondary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: headColor.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: headColor, size: 15),
        ),
        const SizedBox(width: 9),
        AppRichText.setTextPoppinsStyle(context, label, 13, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0),
      ],
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool canStart) {
    String btnLabel;
    IconData btnIcon;
    List<Color> btnColors;
    VoidCallback? onTap;

    if (_attempted) {
      btnLabel = 'Already Attempted';
      btnIcon = Icons.check_circle_outline;
      btnColors = [Colors.grey.shade500, Colors.grey.shade700];
      onTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aapne yeh test pehle attempt kar liya hai'),
            backgroundColor: Colors.grey.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      };
    } else if (canStart) {
      btnLabel = 'Start Mock Test';
      btnIcon = Icons.play_arrow_rounded;
      btnColors = [_mockPrimary, _mockSecondary];
      onTap = () {
        if (_isFree) {
          rewardedAdService.showAd(() => _handleStartMockTest());
        } else {
          _handleStartMockTest();
        }
      };
    } else {
      btnLabel = 'Subscribe Now';
      btnIcon = Icons.workspace_premium_rounded;
      btnColors = [_mockPrimary, _mockAccent];
      onTap = _handleSubscribe;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.1), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Small hint text above button
            if (!_attempted && canStart)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: _mockPrimary.withOpacity(0.5)),
                    const SizedBox(width: 5),
                    Text(
                      'Timer shuru hoga test start hone ke baad',
                      style: TextStyle(fontSize: 10, color: _mockPrimary.withOpacity(0.6), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            // Main CTA button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: btnColors),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: btnColors.first.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(btnIcon, color: Colors.white, size: 21),
                        const SizedBox(width: 9),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          btnLabel,
                          15,
                          AppColors.white,
                          FontWeight.w800,
                          1,
                          TextAlign.center,
                          0,
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
    );
  }
}
