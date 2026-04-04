import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/ads/banner_ads_helper.dart';
import 'package:tazaquiznew/ads/rewarded_ad_service.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'dart:async';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/mockTestScreen.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/screens/quiz_review_page.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class _DS {
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;

  static const double fsXxs = 9.5;
  static const double fsXs = 10.5;
  static const double fsSm = 11.5;
  static const double fsMd = 13.0;
  static const double fsLg = 15.0;
  static const double fsXl = 17.0;
  static const double fsXxl = 20.0;

  static const double sp4 = 4;
  static const double sp6 = 6;
  static const double sp8 = 8;
  static const double sp10 = 10;
  static const double sp12 = 12;
  static const double sp14 = 14;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;

  static const Color navy = Color(0xFF0D1B3E);
  static const Color navyMid = Color(0xFF1A2F5A);
  static const Color teal = Color(0xFF00BFA5);
  static const Color tealDark = Color(0xFF00897B);
  static const Color gold = Color(0xFFF5A623);
  static const Color red = Color(0xFFE53935);
  static const Color surface = Color(0xFFF4F6FB);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F4);
  static const Color textPri = Color(0xFF0D1B3E);
  static const Color textSec = Color(0xFF6B7A99);
  static const Color textHint = Color(0xFFADB5CC);
}

class MockTestDetailPage extends StatefulWidget {
  final String quizId;

  MockTestDetailPage({required this.quizId});

  @override
  _MockTestDetailPageState createState() => _MockTestDetailPageState();
}

class _MockTestDetailPageState extends State<MockTestDetailPage> with SingleTickerProviderStateMixin {
  final RewardedAdService rewardedAdService = RewardedAdService();
  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  Color get _primary => AppColors.darkNavy;
  Color get _secondary => AppColors.darkNavy.withOpacity(0.85);
  Color get _accent => AppColors.tealGreen;
  Color get _gold => AppColors.lightGold;
  static const Color _bg = Color(0xFFF0F2F8);

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

  bool get _hasFullAccess =>
      (_currentQuiz?.isPurchased ?? false) &&
      (_currentQuiz?.isAccessible ?? false) &&
      (_currentQuiz?.accessStatus ?? false);

  String get _planDisplayName {
    final plan = (_currentQuiz?.effectivePlan ?? '').toLowerCase();
    switch (plan) {
      case 'free':
        return 'Free Plan';
      case 'basic':
        return 'Basic Plan';
      case 'premium':
        return 'Premium Plan';
      case 'full_access':
        return 'Full Access';
      default:
        if (plan.isNotEmpty) {
          return '${plan[0].toUpperCase()}${plan.substring(1)} Plan';
        }
        return 'Your Plan';
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    rewardedAdService.loadAd();
    bannerService.loadAd(() => setState(() => isBannerLoaded = true));
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
      print('Fetching mock test details: $data');
      final responseFuture = await authRepository.get_quizId_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        if (responseData['status'] == true && responseData['data'] != null) {
          _currentQuiz = QuizItem.fromJson(responseData['data']);
          setState(() {
            _isPurchased = _currentQuiz!.isPurchased;
            _isAccessible = _currentQuiz!.accessStatus;
            _attempted = _currentQuiz!.is_attempted;
            _isFree = !_currentQuiz!.isAccessible;
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

  // ✅ UPDATED
  void _handleStartMockTest() {
    if (_currentQuiz == null) return;
    if (!_hasFullAccess) {
      _showAccessDialog();
      return;
    }
    if (_currentQuiz!.dailyLimitExceeded) {
      _showDailyLimitModal();
      return;
    }
    if (_isFree) {
      rewardedAdService.showAd(() => _navigateToMockTest());
    } else {
      _navigateToMockTest();
    }
  }

  void _navigateToMockTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MockTestScreen(
              testTitle: _currentQuiz!.title.toString(),
              subject: _currentQuiz!.difficultyLevel.toString(),
              Quiz_id: widget.quizId.toString(),
              timeLimit: int.parse(_currentQuiz!.timeLimit.toString()),
            ),
      ),
    );
  }

  // ✅ NEW — Daily limit modal
  void _showDailyLimitModal() {
    final hoursLeft = 23 - DateTime.now().hour;
    final minsLeft = 59 - DateTime.now().minute;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFE65100), size: 38),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Limit Reached!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D1B3E)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You've already attempted 2 Mock Tests today.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7A99), height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Come back tomorrow\nto attempt more! 🌅',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFE65100)),
                        const SizedBox(width: 6),
                        Text(
                          'Resets in ${hoursLeft}h ${minsLeft}m',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1B3E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Okay, Got it!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAccessDialog() {
    String message;
    String buttonText;
    bool showResume = false;

    switch (_currentQuiz!.accessError) {
      case 'attempt_pending':
        message = 'You have a pending attempt. Please complete it first.';
        buttonText = 'Resume Attempt';
        showResume = true;
        break;
      case 'upgrade_required':
        message = 'You have used your free attempt this month. Activate to continue!';
        buttonText = 'Activate Now';
        break;
      case 'plan_expired':
        message = 'Your plan has expired. Please renew to regain access!';
        buttonText = 'Renew Plan';
        break;
      case 'purchase_required':
        message = 'This mock test requires a course purchase. Get full access now!';
        buttonText = 'Activate Now';
        break;
      default:
        message = _currentQuiz!.accessMessage ?? 'You do not have access.';
        buttonText = 'Upgrade Plan';
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Access Required', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Text(message, style: const TextStyle(fontSize: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  showResume ? _navigateToMockTest() : _handleSubscribe();
                },
                child: Text(buttonText),
              ),
            ],
          ),
    );
  }

  void _handleSubscribe() {
    if (_currentQuiz == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PricingPage(CourseIds: _currentQuiz!.subscription_id.toString())),
    ).then((value) {
      if (value == true) _getUserData();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primary), strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                'Loading mock test...',
                style: TextStyle(color: _primary.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuiz == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(backgroundColor: _primary, title: const Text('Error')),
        body: const Center(child: Text('Test not found')),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
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
                    _buildAccessBanner(),
                    const SizedBox(height: 10),
                    if (!_hasFullAccess) _buildSubscriptionSection() else _buildCombinedHeader(),
                    const SizedBox(height: 10),

                    _buildStatsRow(),
                    const SizedBox(height: 10),
                    _buildExpectSection(),
                    const SizedBox(height: 10),
                    if (!_hasFullAccess) _buildCombinedHeader() else _buildTestInfoSection(),
                    const SizedBox(height: 10),
                    if (_currentQuiz!.description.isNotEmpty) ...[_buildDescriptionCard(), const SizedBox(height: 10)],
                    if (_currentQuiz!.instruction.isNotEmpty) ...[_buildInstructionsCard(), const SizedBox(height: 10)],
                    _buildImportantInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAccessBanner() {
    final quiz = _currentQuiz!;
    final error = quiz.accessError ?? '';
    final msg = quiz.accessMessage ?? '';

    _AccessBannerCfg cfg;

    if (_hasFullAccess) {
      cfg =
          quiz.isPurchased
              ? _AccessBannerCfg(
                gradient: [const Color(0xFF00897B), const Color(0xFF004D40)],
                icon: Icons.verified_rounded,
                badge: _planDisplayName,
                headline: 'Full Access Unlocked',
                subLine: msg.isNotEmpty ? msg : 'You can attempt this test anytime.',
                statusLabel: 'GRANTED',
                statusColor: const Color(0xFF69F0AE),
                locked: false,
              )
              : _AccessBannerCfg(
                gradient: [const Color(0xFF1976D2), const Color(0xFF0D47A1)],
                icon: Icons.lock_open_rounded,
                badge: _planDisplayName,
                headline: 'Free Test — Open to All',
                subLine: msg.isNotEmpty ? msg : 'This test is free to attempt.',
                statusLabel: 'FREE',
                statusColor: const Color(0xFF82B1FF),
                locked: false,
              );
    } else {
      switch (error) {
        case 'upgrade_required':
          cfg = _AccessBannerCfg(
            gradient: [const Color(0xFFBF360C), const Color(0xFF870000)],
            icon: Icons.lock_clock_rounded,
            badge: _planDisplayName,
            headline: 'Monthly Limit Reached',
            subLine: msg.isNotEmpty ? msg : "You've used all free attempts this month.",
            statusLabel: 'LOCKED',
            statusColor: const Color(0xFFFF6E6E),
            locked: true,
          );
          break;
        case 'plan_expired':
          cfg = _AccessBannerCfg(
            gradient: [const Color(0xFF6A1B9A), const Color(0xFF38006B)],
            icon: Icons.workspace_premium_rounded,
            badge: _planDisplayName,
            headline: 'Plan Expired',
            subLine: msg.isNotEmpty ? msg : 'Renew your plan to regain full access.',
            statusLabel: 'EXPIRED',
            statusColor: const Color(0xFFCE93D8),
            locked: true,
          );
          break;
        case 'purchase_required':
          cfg = _AccessBannerCfg(
            gradient: [const Color(0xFF1A237E), const Color(0xFF0D1340)],
            icon: Icons.shopping_bag_rounded,
            badge: _planDisplayName,
            headline: 'Course Purchase Required',
            subLine: msg.isNotEmpty ? msg : 'Purchase this course to unlock access.',
            statusLabel: 'LOCKED',
            statusColor: const Color(0xFF9FA8DA),
            locked: true,
          );
          break;
        case 'attempt_pending':
          cfg = _AccessBannerCfg(
            gradient: [const Color(0xFF00695C), const Color(0xFF003D33)],
            icon: Icons.pending_actions_rounded,
            badge: _planDisplayName,
            headline: 'Pending Attempt Found',
            subLine: msg.isNotEmpty ? msg : 'Complete your ongoing attempt first.',
            statusLabel: 'PENDING',
            statusColor: const Color(0xFFFFD740),
            locked: true,
          );
          break;
        default:
          cfg = _AccessBannerCfg(
            gradient: [const Color(0xFF263238), const Color(0xFF0D1B2A)],
            icon: Icons.block_rounded,
            badge: _planDisplayName,
            headline: 'Access Restricted',
            subLine: msg.isNotEmpty ? msg : 'You do not have access to this test.',
            statusLabel: 'LOCKED',
            statusColor: const Color(0xFFB0BEC5),
            locked: true,
          );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_DS.r8),
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: cfg.gradient),
        boxShadow: [BoxShadow(color: cfg.gradient.first.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(cfg.icon, color: Colors.white, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cfg.headline,
                    style: const TextStyle(
                      fontSize: _DS.fsSm,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cfg.locked ? _getLockedActionHint() : cfg.subLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.78), fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: cfg.statusColor),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cfg.statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: cfg.statusColor,
                      letterSpacing: 0.7,
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

  String _getLockedActionHint() {
    switch (_currentQuiz?.accessError ?? '') {
      case 'upgrade_required':
        return 'Tap "Activate Now" below to upgrade your plan';
      case 'plan_expired':
        return 'Tap "Activate Now" below to renew your plan';
      case 'purchase_required':
        return 'Tap "Activate Now" below to purchase this course';
      case 'attempt_pending':
        return 'Tap "Resume Attempt" below to continue';
      default:
        return 'Tap the button below to get access';
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 55,
      pinned: true,
      backgroundColor: _primary,
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
        background: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [_primary, _secondary]))),
      ),
    );
  }

  BoxDecoration _cardDecor({double radius = _DS.r16}) => BoxDecoration(
    color: _DS.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _DS.border),
    boxShadow: [BoxShadow(color: _DS.navy.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
  );

  Widget _buildCombinedHeader() {
    final materialName = _currentQuiz?.Material_name ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (materialName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_DS.navy, _DS.navyMid],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(_DS.r16), topRight: Radius.circular(_DS.r16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.library_books_rounded, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COURSE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.55),
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          materialName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: _DS.fsMd,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _DS.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _DS.gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.menu_book_rounded, size: 10, color: _DS.gold),
                        SizedBox(width: 4),
                        Text('Series', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _DS.gold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _attempted
                        ? _buildTag(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'ATTEMPTED',
                          color: const Color(0xFF00897B),
                        )
                        : _buildTag(
                          icon: Icons.assignment_outlined,
                          label: 'NOT ATTEMPTED',
                          color: const Color(0xFF3949AB),
                        ),
                    if (_currentQuiz!.difficultyLevel.isNotEmpty)
                      _buildTag(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: _currentQuiz!.difficultyLevel,
                        color: _DS.navy,
                      ),
                    _isFree
                        ? _buildTag(icon: Icons.lock_open_rounded, label: 'FREE', color: _DS.teal)
                        : _buildTag(icon: Icons.workspace_premium_rounded, label: 'PREMIUM', color: _DS.gold),
                    _buildTag(icon: Icons.assignment_outlined, label: 'MOCK TEST', color: _DS.navy),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _currentQuiz!.Category_name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _DS.textPri,
                    height: 1.35,
                    letterSpacing: -0.1,
                  ),
                ),
                if (_currentQuiz!.instruction.isNotEmpty) ...[
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _DS.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _DS.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔥 NOTICE TITLE
                        Row(
                          children: const [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFF00695C)),
                            SizedBox(width: 6),
                            Text(
                              "Notice",
                              style: TextStyle(
                                fontSize: _DS.fsSm,
                                fontWeight: FontWeight.w700, // bold
                                color: Color(0xFF00695C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        /// 📄 INSTRUCTION TEXT
                        Text(
                          'Test Name : ${_currentQuiz!.title}',
                          style: const TextStyle(
                            fontSize: _DS.fsSm,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF00695C),
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 3),

                        /// 📄 INSTRUCTION TEXT
                        Text(
                          _currentQuiz!.instruction,
                          style: const TextStyle(
                            fontSize: _DS.fsSm,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 87, 104, 137),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_attempted) ...[
                  const SizedBox(height: 12),
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
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'You have already attempted this test',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
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

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                icon: Icons.timer_outlined,
                iconBg: const Color(0xFFFFF8EC),
                iconColor: const Color(0xFFBA7517),
                value: _currentQuiz?.timeLimit.isEmpty == false ? '${_currentQuiz!.timeLimit} min' : '—',
                label: 'Duration',
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                icon: Icons.emoji_events_outlined,
                iconBg: const Color(0xFFE1F5EE),
                iconColor: const Color(0xFF0F6E56),
                value: _currentQuiz?.totalMarks.toString() ?? '—',
                label: 'Total Marks',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.help_outline_rounded,
                iconBg: const Color(0xFFEEF1F9),
                iconColor: const Color(0xFF1A2F5A),
                value: _currentQuiz?.totalQuestions != null ? '${_currentQuiz!.totalQuestions}' : '—',
                label: 'Questions',
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                icon: Icons.verified_outlined,
                iconBg: const Color(0xFFEEEDFE),
                iconColor: const Color(0xFF534AB7),
                value: _currentQuiz?.passing_score != null ? '${_currentQuiz!.passing_score}' : '—',
                label: 'Passing Marks',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primary.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primary, height: 1.1),
                  ),
                  const SizedBox(height: 3),
                  Text(label, style: TextStyle(fontSize: 11, color: AppColors.greyS600, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
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
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _primary, height: 1.3),
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

  Widget _buildTestInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Test Details', isGreen: false),
          const SizedBox(height: 14),
          _buildDetailRow(Icons.all_inclusive_rounded, 'Availability', 'Attempt anytime — no schedule'),
          if (_currentQuiz!.timeLimit.isNotEmpty)
            _buildDetailRow(Icons.timer_outlined, 'Duration', '${_currentQuiz!.timeLimit} Minutes'),
          _buildDetailRow(
            Icons.repeat_rounded,
            'Attempts',
            _attempted ? 'Already attempted once' : 'One attempt allowed',
          ),
          if (_currentQuiz!.totalQuestions > 0)
            _buildDetailRow(Icons.help_outline_rounded, 'Questions', '${_currentQuiz!.totalQuestions} questions'),
          if (_currentQuiz!.totalMarks > 0)
            _buildDetailRow(Icons.emoji_events_outlined, 'Total Marks', '${_currentQuiz!.totalMarks} marks'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_outlined, size: 14, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Designed to simulate actual exam conditions — same pattern, same time pressure.',
                    style: TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                ),
              ],
            ),
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
            decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: _primary, size: 15),
          ),
          const SizedBox(width: 11),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    final error = _currentQuiz?.accessError ?? '';
    final courseName = (_currentQuiz?.Material_name ?? '').isNotEmpty ? _currentQuiz!.Material_name : 'this course';

    String headline;
    String subtitle;
    List<Color> headerGradient;
    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;

    if (error == 'plan_expired') {
      headline = 'Your Plan Has Expired';
      subtitle = 'Renew now and get instant access to "$courseName" and everything you had before';
      headerGradient = [Colors.orange.shade800, Colors.deepOrange.shade900];
      badgeColor = Colors.orange.shade300;
      badgeLabel = 'Plan Expired';
      badgeIcon = Icons.warning_amber_rounded;
    } else if (error == 'upgrade_required') {
      headline = 'Free Attempt Used\nUpgrade to Continue';
      subtitle = "You've used your monthly free attempt for \"$courseName\" — subscribe for unlimited access";
      headerGradient = [_primary, const Color(0xFF1a3a5c)];
      badgeColor = _gold;
      badgeLabel = 'Upgrade Required';
      badgeIcon = Icons.workspace_premium_rounded;
    } else {
      headline = 'Unlock "$courseName"';
      subtitle = 'This mock test is part of "$courseName" — subscribe to get full access';
      headerGradient = [_primary, const Color(0xFF1a3a5c)];
      badgeColor = _gold;
      badgeLabel = 'Purchase Required';
      badgeIcon = Icons.workspace_premium_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: headerGradient),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, color: badgeColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              badgeLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Course name pill
                      // if ((_currentQuiz?.Material_name ?? '').isNotEmpty) ...[
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      //     decoration: BoxDecoration(
                      //       color: Colors.white.withOpacity(0.12),
                      //       borderRadius: BorderRadius.circular(8),
                      //       border: Border.all(color: Colors.white.withOpacity(0.2)),
                      //     ),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         const Icon(Icons.library_books_rounded, size: 11, color: Colors.white),
                      //         const SizedBox(width: 6),
                      //         Text(
                      //           _currentQuiz!.Material_name,
                      //           style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      //   const SizedBox(height: 10),
                      // ],

                      // Headline
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.78),
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What you get with this subscription',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Benefits grid
                  _buildBenefitGrid([
                    _BenefitItem(
                      emoji: '📝',
                      icon: Icons.assignment_rounded,
                      title: 'Mock Tests',
                      desc: 'Attempt all mock tests in "$courseName" — unlimited practice',
                      color: _primary,
                    ),
                    _BenefitItem(
                      emoji: '🎯',
                      icon: Icons.quiz_rounded,
                      title: 'Full Mock Tests',
                      desc: 'Full-length real exam simulation papers for "$courseName"',
                      color: const Color(0xFFE65100),
                    ),
                    _BenefitItem(
                      emoji: '📜',
                      icon: Icons.history_edu_rounded,
                      title: 'Previous Year Papers',
                      desc: 'Solve actual past exam questions (PYPs) for "$courseName"',
                      color: const Color(0xFF00897B),
                    ),
                    _BenefitItem(
                      emoji: '📰',
                      icon: Icons.newspaper_rounded,
                      title: 'Daily Current Affairs',
                      desc: 'Fresh GK & news updates every day',
                      color: const Color(0xFF1565C0),
                    ),
                    _BenefitItem(
                      emoji: '📚',
                      icon: Icons.menu_book_rounded,
                      title: 'Study Material',
                      desc: 'PDFs, notes & video lessons for complete prep',
                      color: const Color(0xFF6A1B9A),
                    ),
                    _BenefitItem(
                      emoji: '🏆',
                      icon: Icons.leaderboard_rounded,
                      title: 'All India Ranking',
                      desc: 'Compare your score with students nationwide',
                      color: _gold,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Bottom highlight box
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_accent.withOpacity(0.08), _primary.withOpacity(0.04)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withOpacity(0.3), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.bolt_rounded, color: _accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'One subscription. Everything included.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mock Tests + Full Mock Tests + PYPs + Study Material + Live Tests — all in one plan.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.greyS600,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitGrid(List<_BenefitItem> items) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildBenefitCard(items[i])),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < items.length ? _buildBenefitCard(items[i + 1]) : const SizedBox()),
          ],
        ),
      );
      if (i + 2 < items.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildBenefitCard(_BenefitItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: item.color.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              const SizedBox(width: 6),
              Text(item.emoji, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _primary, height: 1.2)),
          const SizedBox(height: 4),
          Text(
            item.desc,
            style: TextStyle(fontSize: 9.5, color: AppColors.greyS600, fontWeight: FontWeight.w400, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
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

  Widget _buildInstructionsCard() {
    final lines = _currentQuiz!.instruction.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
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
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(5)),
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

  Widget _buildImportantInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Important Information', isGreen: false),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.touch_app_rounded, 'One attempt only — make every question count'),
          _buildInfoRow(Icons.swap_horiz_rounded, 'Navigate freely — jump to any question anytime'),
          _buildInfoRow(Icons.bookmark_border_rounded, 'Mark for review — revisit flagged questions before submitting'),
          _buildInfoRow(Icons.timer_outlined, 'Timer runs continuously — does not stop even on pause'),
          _buildInfoRow(Icons.wifi_rounded, 'Stable internet connection required throughout the test'),
          _buildInfoRow(Icons.bar_chart_rounded, 'Detailed performance analysis available after submission'),
          _buildInfoRow(Icons.block_rounded, 'Once submitted, the attempt cannot be retaken'),
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
          Icon(icon, size: 14, color: _primary),
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

  Widget _buildSectionHead(IconData icon, String label, {bool isGreen = true}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _primary, size: 15),
        ),
        const SizedBox(width: 9),
        AppRichText.setTextPoppinsStyle(context, label, 13, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0),
      ],
    );
  }

  Widget _buildBottomBar() {
    final quiz = _currentQuiz;
    if (quiz == null) return const SizedBox.shrink();

    String label;
    IconData icon;
    List<Color> colors;
    VoidCallback onTap;

    if (quiz.pendingAttemptId != null && quiz.pendingAttemptId! > 0) {
      label = 'Resume Test';
      icon = Icons.play_circle_outline;
      colors = [_accent, _primary];
      onTap = _navigateToMockTest;
    } else if (_attempted) {
      label = 'View Result';
      icon = Icons.bar_chart_rounded;
      colors = [_DS.teal, _DS.tealDark];

      onTap =
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => QuizReviewPage(
                    attemptId: quiz.completedAttemptId ?? 0, // ✅ attempt_id
                    userId: int.tryParse(_user!.id.toString()) ?? 0,
                    quizTitle: quiz.title,
                    pageType: 4,
                  ),
            ),
          );
    } else if (!_hasFullAccess) {
      final error = quiz.accessError ?? '';
      if (error == 'plan_expired') {
        label = 'Renew Plan Now';
        icon = Icons.refresh_rounded;
        colors = [Colors.orange.shade700, Colors.orange.shade900];
      } else if (error == 'upgrade_required') {
        label = 'Activate Now';
        icon = Icons.workspace_premium_rounded;
        colors = [
          Color(0xFF00C9A7), // Green
          Color(0xFF0D3B66), // Blue
        ];
      } else {
        label = 'Activate Now';
        icon = Icons.workspace_premium_rounded;
        colors = [
          Color(0xFF00C9A7), // Green
          Color(0xFF0D3B66), // Blue
        ];
      }
      onTap = _handleSubscribe;
    } else {
      label = 'Start Mock Test';
      icon = Icons.play_arrow_rounded;
      colors = [_primary, _secondary];
      onTap = _handleStartMockTest;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.1), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasFullAccess && !_attempted)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: _primary.withOpacity(0.5)),
                    const SizedBox(width: 5),
                    Text(
                      'Timer starts as soon as the test begins',
                      style: TextStyle(fontSize: 10, color: _primary.withOpacity(0.6), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5)),
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
                        Icon(icon, color: Colors.white, size: 21),
                        const SizedBox(width: 9),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          label,
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

class _AccessBannerCfg {
  final List<Color> gradient;
  final IconData icon;
  final String badge;
  final String headline;
  final String subLine;
  final String statusLabel;
  final Color statusColor;
  final bool locked;

  const _AccessBannerCfg({
    required this.gradient,
    required this.icon,
    required this.badge,
    required this.headline,
    required this.subLine,
    required this.statusLabel,
    required this.statusColor,
    required this.locked,
  });
}

class _BenefitItem {
  final String emoji;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _BenefitItem({
    required this.emoji,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}
