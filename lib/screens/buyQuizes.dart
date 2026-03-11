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
import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizDetailPage extends StatefulWidget {
  final String quizId;
  final bool is_subscribed;

  QuizDetailPage({required this.quizId, required this.is_subscribed});

  @override
  _QuizDetailPageState createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> with SingleTickerProviderStateMixin {
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
  bool _isLive = false;
  QuizItem? _currentQuiz;
  Timer? _countdownTimer;
  Timer? _pulseTimer;
  int _remainingSeconds = 0;
  bool _livePulse = true;
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
    _startPulse();
  }

  void _startPulse() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() => _livePulse = !_livePulse);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseTimer?.cancel();
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
            _isLive = _currentQuiz!.isLive;
            _isPremium = _currentQuiz!.is_premium;
            _product_sub_id = _currentQuiz!.subscription_id;
            _remainingSeconds = _currentQuiz!.startsInSeconds;
          });
          if (_remainingSeconds > 0) _startCountdown();
        }
        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching quiz details: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _countdownTimer?.cancel();
          _isLive = true;
        }
      });
    });
  }

  String _getCountdownText() {
    if (_remainingSeconds <= 0) return "LIVE NOW!";
    int h = _remainingSeconds ~/ 3600;
    int m = (_remainingSeconds % 3600) ~/ 60;
    int s = _remainingSeconds % 60;
    if (h > 0) return "${h}h ${m}m ${s}s";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  void _handleStartQuiz() {
    if (_currentQuiz == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LiveTestScreen(
              testTitle: _currentQuiz!.title.toString(),
              subject: _currentQuiz!.difficultyLevel.toString(),
              Quiz_id: widget.quizId.toString(),
            ),
      ),
    );
  }

  void _handleSubscribe() {
    if (_currentQuiz == null) return;
    String susb_category;
    String send_product_id;
    if (_isPremium == 1) {
      susb_category = 'QUIZ';
      send_product_id = widget.quizId;
    } else {
      susb_category = 'Subscription';
      send_product_id = _product_sub_id.toString();
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutPage(contentType: susb_category, contentId: send_product_id)),
    ).then((value) {
      if (value == true) _getUserData();
    });
  }

  // ─── STATUS HELPERS ──────────────────────────────────────────────────────────

  Color _getStatusColor() {
    switch (_currentQuiz?.quizStatus.toLowerCase()) {
      case 'live':
        return const Color(0xFFE53935);
      case 'upcoming':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF6B7280);
      default:
        return AppColors.tealGreen;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentQuiz?.quizStatus.toLowerCase()) {
      case 'live':
        return Icons.radio_button_checked;
      case 'upcoming':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F8),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen), strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                'Loading quiz...',
                style: TextStyle(color: AppColors.greyS600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuiz == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F8),
        appBar: AppBar(backgroundColor: AppColors.darkNavy, title: const Text('Error')),
        body: const Center(child: Text('Quiz not found')),
      );
    }

    final bool canStartQuiz = _isPurchased || _isAccessible || _isFree;
    final bool isAvailable = _isLive && canStartQuiz;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // ── Status Banner ──
                    if (canStartQuiz) _buildStatusBanner(),
                    if (canStartQuiz) const SizedBox(height: 10),

                    // ── Live Banner ──
                    if (_isLive && canStartQuiz) _buildLiveBanner(),
                    if (_isLive && canStartQuiz) const SizedBox(height: 10),

                    // ── Course Info ──
                    _buildCourseInfo(),
                    const SizedBox(height: 10),

                    // ── Quiz Header ──
                    _buildQuizHeader(),
                    const SizedBox(height: 10),

                    // ── Stats Row ──
                    _buildStatsRow(),
                    const SizedBox(height: 10),

                    // ── Banner Ad ──
                    if (isBannerLoaded && bannerService.bannerAd != null) _buildBannerAd(),

                    // ── Main Section ──
                    if (!canStartQuiz) _buildSubscriptionSection() else _buildScheduleSection(),
                    const SizedBox(height: 10),

                    // ── Description ──
                    if (_currentQuiz!.description.isNotEmpty) ...[_buildDescriptionCard(), const SizedBox(height: 10)],

                    // ── Instructions ──
                    if (_currentQuiz!.instruction.isNotEmpty) ...[_buildInstructionsCard(), const SizedBox(height: 10)],

                    // ── Info Card ──
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(canStartQuiz, isAvailable),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 55,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
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
      flexibleSpace: FlexibleSpaceBar(background: Container(color: AppColors.darkNavy)),
    );
  }

  // ─── STATUS BANNER ───────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    String message;
    String subtitle;
    IconData icon;
    List<Color> colors;

    if (_isFree) {
      message = '🎉 This Quiz is FREE!';
      subtitle = 'No subscription required';
      icon = Icons.celebration_outlined;
      colors = [AppColors.tealGreen, AppColors.darkNavy];
    } else if (_isPurchased) {
      message = '✅ You are subscribed!';
      subtitle = 'Full access unlocked';
      icon = Icons.verified;
      colors = [AppColors.tealGreen, AppColors.darkNavy];
    } else {
      message = '🔓 Accessible for you!';
      subtitle = 'Included in your plan';
      icon = Icons.lock_open_rounded;
      colors = [AppColors.lightGold, AppColors.lightGoldS2];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
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

  // ─── LIVE BANNER ─────────────────────────────────────────────────────────────

  Widget _buildLiveBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red.shade600, Colors.red.shade900]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: AnimatedOpacity(
              opacity: _livePulse ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 400),
              child: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  '🔴  LIVE NOW! Join Immediately',
                  12,
                  AppColors.white,
                  FontWeight.w800,
                  1,
                  TextAlign.left,
                  0,
                ),
                const SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Test has started — don\'t miss it!',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: AppRichText.setTextPoppinsStyle(
              context,
              'JOIN',
              10,
              AppColors.white,
              FontWeight.w800,
              1,
              TextAlign.center,
              0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── COURSE INFO ─────────────────────────────────────────────────────────────

  Widget _buildCourseInfo() {
    // Material_name = label ke neeche dikhne wali value (e.g. "GK Intermediate - Set 2")
    // Original code se same — koi variable change nahi
    final materialName = _currentQuiz?.Material_name ?? '';
    if (materialName.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGold.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.library_books_outlined, color: AppColors.lightGold, size: 17),
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
                  materialName, // ← sirf Material_name, original jaisa
                  13,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  2,
                  TextAlign.left,
                  1.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DATETIME FORMATTER ──────────────────────────────────────────────────────
  // "2026-03-12 10:00:00" → "12 Mar 2026  •  10:00 AM"
  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw.trim().replaceAll(' ', 'T'));
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  $h:$m $ampm';
    } catch (_) {
      return raw;
    }
  }

  // ─── QUIZ HEADER ─────────────────────────────────────────────────────────────

  Widget _buildQuizHeader() {
    // Original jaisa — Category_name card title mein, title appbar mein
    final quizTitle = _currentQuiz!.Category_name;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags row
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              _buildTag(
                icon: _getStatusIcon(),
                label: _currentQuiz!.quizStatus.toUpperCase(),
                color: _getStatusColor(),
              ),
              if (_currentQuiz!.difficultyLevel.isNotEmpty)
                _buildTag(
                  icon: Icons.signal_cellular_alt,
                  label: _currentQuiz!.difficultyLevel,
                  color: AppColors.tealGreen,
                ),
              if (_isFree)
                _buildTag(icon: Icons.lock_open, label: 'FREE', color: AppColors.tealGreen)
              else
                _buildTag(icon: Icons.workspace_premium, label: 'PREMIUM', color: AppColors.lightGold),
            ],
          ),
          const SizedBox(height: 12),

          // Quiz Title
          AppRichText.setTextPoppinsStyle(
            context,
            quizTitle,
            20,
            AppColors.darkNavy,
            FontWeight.w800,
            3,
            TextAlign.left,
            1.3,
          ),
          const SizedBox(height: 12),

          // Series label + name
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.darkNavy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkNavy.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 13, color: AppColors.tealGreen),
                  const SizedBox(width: 7),
                  Expanded(
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      _currentQuiz!.subscription_description,
                      11,
                      AppColors.darkNavy,
                      FontWeight.w600,
                      2,
                      TextAlign.left,
                      1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Countdown — full width pill
          if (_remainingSeconds > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 16),
                  const SizedBox(width: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Starts in  ',
                    12,
                    const Color(0xFFB45309).withOpacity(0.7),
                    FontWeight.w500,
                    1,
                    TextAlign.left,
                    0,
                  ),
                  Text(
                    _getCountdownText(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
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
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9.5, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
          ],
        ),
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

  // ─── SUBSCRIPTION SECTION ────────────────────────────────────────────────────

  Widget _buildSubscriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
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
                  colors: [Color(0xFF0B1340), Color(0xFF1a3a5c)],
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
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tealGreen.withOpacity(0.1)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.lightGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.lightGold.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, color: AppColors.lightGold, size: 15),
                            const SizedBox(width: 6),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Premium Quiz',
                              12,
                              AppColors.lightGold,
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
                        'Unlock This Test &\nFull Test Series',
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
                        'One subscription, unlimited access',
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
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00a387)])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹299',
                        style: const TextStyle(
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
                    Icons.all_inclusive,
                    'Unlimited Quiz Access',
                    'Attempt all quizzes without limits',
                    AppColors.lightGold,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.menu_book,
                    'Complete Study Material',
                    'PDFs, videos, notes & practice sets',
                    AppColors.tealGreen,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.school,
                    'Expert Guidance',
                    'Learn from experienced teachers',
                    AppColors.lightGold,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.bar_chart,
                    'Performance Analytics',
                    'Track progress with detailed reports',
                    AppColors.tealGreen,
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
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF0B1340).withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
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
          Icon(Icons.check_circle, color: AppColors.tealGreen, size: 16),
        ],
      ),
    );
  }

  // ─── SCHEDULE SECTION ────────────────────────────────────────────────────────

  Widget _buildScheduleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.access_time_rounded, 'Quiz Schedule', isGreen: true),
          const SizedBox(height: 14),

          // Start time card
          _buildScheduleCard(
            icon: Icons.play_circle_outline_rounded,
            label: 'Starts At',
            rawDateTime: _currentQuiz!.startDateTime,
            color: AppColors.tealGreen,
            bgColor: AppColors.tealGreen.withOpacity(0.07),
          ),

          if (_currentQuiz!.endDateTime.isNotEmpty) ...[
            const SizedBox(height: 10),
            // End time card
            _buildScheduleCard(
              icon: Icons.stop_circle_outlined,
              label: 'Ends At',
              rawDateTime: _currentQuiz!.endDateTime,
              color: const Color(0xFFE53935),
              bgColor: const Color(0xFFE53935).withOpacity(0.06),
            ),
          ],

          if (_currentQuiz!.timeLimit.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Duration card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGold.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.lightGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.timer_outlined, color: AppColors.lightGold, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentQuiz!.timeLimit} Minutes',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.lightGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⏱ Timed Test',
                      style: TextStyle(fontSize: 10, color: AppColors.lightGold, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required IconData icon,
    required String label,
    required String rawDateTime,
    required Color color,
    required Color bgColor,
  }) {
    String formatted = _formatDateTime(rawDateTime);
    // Split into date and time parts for better display
    List<String> parts = formatted.split('  •  ');
    String datePart = parts.isNotEmpty ? parts[0] : formatted;
    String timePart = parts.length > 1 ? parts[1] : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(datePart, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkNavy)),
            ],
          ),
          const Spacer(),
          if (timePart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(timePart, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHead(IconData icon, String label, {bool isGreen = true}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isGreen ? [AppColors.tealGreen, AppColors.darkNavy] : [AppColors.lightGold, AppColors.lightGoldS2],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 9),
        AppRichText.setTextPoppinsStyle(context, label, 13, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.tealGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  label,
                  11,
                  AppColors.greyS600,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0,
                ),
                Flexible(
                  child: AppRichText.setTextPoppinsStyle(
                    context,
                    value,
                    11,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    1,
                    TextAlign.right,
                    0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DESCRIPTION ─────────────────────────────────────────────────────────────

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.description_outlined, 'About This Quiz'),
          const SizedBox(height: 10),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentQuiz!.description,
            12,
            AppColors.greyS700,
            FontWeight.w400,
            10,
            TextAlign.left,
            1.6,
          ),
        ],
      ),
    );
  }

  // ─── INSTRUCTIONS ────────────────────────────────────────────────────────────

  Widget _buildInstructionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.rule_rounded, 'Instructions', isGreen: false),
          const SizedBox(height: 10),
          _buildInstructionItems(),
        ],
      ),
    );
  }

  Widget _buildInstructionItems() {
    final text = _currentQuiz!.instruction;
    final liRegex = RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true);
    final matches = liRegex.allMatches(text);

    if (matches.isEmpty) {
      return AppRichText.setTextPoppinsStyle(
        context,
        _removeHtmlTags(text),
        12,
        AppColors.greyS700,
        FontWeight.w400,
        10,
        TextAlign.left,
        1.5,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          matches.map((match) {
            final clean = _removeHtmlTags(match.group(1) ?? '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.tealGreen, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      clean,
                      11,
                      AppColors.greyS700,
                      FontWeight.w400,
                      10,
                      TextAlign.left,
                      1.45,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _removeHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ─── INFO CARD ───────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Important Information', isGreen: false),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.touch_app_rounded, 'Single attempt only — make it count'),
          _buildInfoRow(Icons.wifi_rounded, 'Stable internet connection required'),
          _buildInfoRow(Icons.leaderboard_rounded, 'Instant results & live leaderboard'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.tealGreen),
          const SizedBox(width: 9),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              text,
              11,
              AppColors.greyS700,
              FontWeight.w500,
              1,
              TextAlign.left,
              0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool canStartQuiz, bool isAvailable) {
    // ── UPCOMING (canStart but not live yet) → show countdown + Remind Me ──
    if (!_attempted && canStartQuiz && !isAvailable && _remainingSeconds > 0) {
      return _buildRemindMeBar();
    }

    // Button config for other states
    String btnLabel;
    IconData btnIcon;
    List<Color> btnColors;
    List<Color> shadowColors;

    if (_attempted) {
      btnLabel = 'Already Attempted';
      btnIcon = Icons.check_circle_outline;
      btnColors = [Colors.grey.shade500, Colors.grey.shade700];
      shadowColors = [Colors.grey.withOpacity(0.2)];
    } else if (isAvailable) {
      btnLabel = 'Start Quiz Now';
      btnIcon = Icons.play_arrow_rounded;
      btnColors = [Colors.red.shade600, Colors.red.shade900];
      shadowColors = [Colors.red.withOpacity(0.35)];
    } else {
      // Not accessible → Subscribe
      btnLabel = 'Subscribe Now';
      btnIcon = Icons.workspace_premium_rounded;
      btnColors = [AppColors.tealGreen, AppColors.darkNavy];
      shadowColors = [AppColors.tealGreen.withOpacity(0.3)];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: btnColors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: shadowColors.first, blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (_attempted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('You have already attempted this quiz'),
                      backgroundColor: AppColors.greyS600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }
                if (isAvailable) {
                  if (_isFree) {
                    rewardedAdService.showAd(() => _handleStartQuiz());
                  } else {
                    _handleStartQuiz();
                  }
                } else {
                  _handleSubscribe();
                }
              },
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
      ),
    );
  }

  Widget _buildRemindMeBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Timer row ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Quiz starts in  ',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFB45309).withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _getCountdownText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Remind Me full-width button ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0B1340), Color(0xFF00C9A7)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🔔 Reminder set! We\'ll notify you before the quiz starts.'),
                        backgroundColor: AppColors.tealGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 9),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Remind Me',
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
