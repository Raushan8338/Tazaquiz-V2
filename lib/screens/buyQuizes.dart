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
import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
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
  static const Color indigo = Color(0xFF6366F1); // ✅ missed color
  static const Color surface = Color(0xFFF4F6FB);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F4);
  static const Color textPri = Color(0xFF0D1B3E);
  static const Color textSec = Color(0xFF6B7A99);
  static const Color textHint = Color(0xFFADB5CC);
}

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
  bool _hasError = false;
  String _errorType = '';
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

  bool get _hasFullAccess =>
      (_currentQuiz?.isPurchased ?? false) &&
      (_currentQuiz?.isAccessible ?? false) &&
      (_currentQuiz?.accessStatus ?? false);

  bool get _shouldShowAds => !widget.is_subscribed && !_hasFullAccess;

  // ✅ Helper — quizStatus shortcuts
  bool get _isMissed => (_currentQuiz?.quizStatus.toLowerCase() ?? '') == 'missed';
  bool get _isEnded => (_currentQuiz?.quizStatus.toLowerCase() ?? '') == 'ended';

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
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    rewardedAdService.loadAd();
    _getUserData();
    _startPulse();
  }

  void _startPulse() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorType = '';
      });
    }

    try {
      _user = await SessionManager.getUser();

      if (_user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _user = await SessionManager.getUser();
      }

      if (_user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorType = 'session';
          });
        }
        return;
      }

      await fetchQuizDetails(_user!.id);

      if (!mounted) return;
      _fadeController.forward();
      setState(() {});
    } catch (e) {
      print('getUserData error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'unknown';
        });
      }
    }
  }

  Color get _primary => AppColors.darkNavy;
  Color get _secondary => AppColors.darkNavy.withOpacity(0.85);
  Color get _accent => AppColors.tealGreen;
  Color get _gold => AppColors.lightGold;
  static const Color _bg = Color(0xFFF0F2F8);

  Future<void> fetchQuizDetails(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'quiz_id': widget.quizId.toString(), 'user_id': userid.toString()};

      final responseFuture = await authRepository
          .get_quizId_wise_details(data)
          .timeout(const Duration(seconds: 15), onTimeout: () => throw TimeoutException('Request timed out'));

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        if (responseData['status'] == true && responseData['data'] != null) {
          _currentQuiz = QuizItem.fromJson(responseData['data']);
          setState(() {
            _isPurchased = _currentQuiz!.isPurchased;
            _isAccessible = _currentQuiz!.accessStatus;
            _attempted = _currentQuiz!.is_attempted;
            _isFree = !_currentQuiz!.isAccessible;
            _isLive = _currentQuiz!.isLive;
            _isPremium = _currentQuiz!.is_premium;
            _product_sub_id = _currentQuiz!.subscription_id;
            _remainingSeconds = _currentQuiz!.startsInSeconds;
          });
          if (_remainingSeconds > 0) _startCountdown();
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorType = 'server';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'server';
        });
      }
    } on TimeoutException {
      print('Quiz fetch timed out');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'timeout';
        });
      }
    } catch (e) {
      print('Error fetching quiz details: $e');
      final msg = e.toString().toLowerCase();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType =
              msg.contains('socket') || msg.contains('network') || msg.contains('connection')
                  ? 'no_internet'
                  : 'unknown';
        });
      }
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
    if (_remainingSeconds < 86400) {
      int h = _remainingSeconds ~/ 3600;
      int m = (_remainingSeconds % 3600) ~/ 60;
      int s = _remainingSeconds % 60;
      if (h > 0) return "${h}h ${m}m ${s}s";
      if (m > 0) return "${m}m ${s}s";
      return "${s}s";
    } else {
      try {
        final startDt = DateTime.parse(_currentQuiz!.startDateTime.trim().replaceAll(' ', 'T'));
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final h = startDt.hour % 12 == 0 ? 12 : startDt.hour % 12;
        final m = startDt.minute.toString().padLeft(2, '0');
        final ampm = startDt.hour >= 12 ? 'PM' : 'AM';
        return '${startDt.day} ${months[startDt.month - 1]}, $h:$m $ampm';
      } catch (_) {
        return _currentQuiz!.startDateTime;
      }
    }
  }

  String _getCountdownLabel() => _remainingSeconds < 86400 ? 'Starts in  ' : 'Starts on  ';

  void _handleStartQuiz() {
    if (_currentQuiz == null) return;
    if (!_hasFullAccess) {
      _showAccessDialog();
      return;
    }
    // ✅ Daily limit check
    if (_currentQuiz!.dailyLimitExceeded) {
      _showDailyLimitModal();
      return;
    }
    if (_isFree && _shouldShowAds) {
      rewardedAdService.showAd(() => _navigateToQuiz());
    } else {
      _navigateToQuiz();
    }
  }

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
                    "You've already attempted 2 Quizzes today.",
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

  void _navigateToQuiz() {
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
      case 'course_mismatch':
        message = 'This test belongs to a different course. Upgrade your plan!';
        buttonText = 'Upgrade Plan';
        break;
      case 'upgrade_required':
        message = 'You have used all your attempts for this month. Upgrade to continue!';
        buttonText = 'Activate Now';
        break;
      case 'plan_expired':
        message = 'Your plan has expired. Please renew to regain access!';
        buttonText = 'Renew Plan';
        break;
      default:
        message = _currentQuiz!.accessMessage ?? 'You do not have access.';
        buttonText = 'Upgrade Plan';
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.r16)),
            backgroundColor: _DS.card,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: _DS.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.lock_outline_rounded, color: _DS.red, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Access Required',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _DS.textPri),
                ),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 13.5, color: _DS.textSec, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: _DS.textSec, fontSize: 13)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  showResume ? _navigateToQuiz() : _handleSubscribe();
                },
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
    );
  }

  void _handleSubscribe() {
    if (_currentQuiz == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => PricingPage())).then((value) {
      if (value == true) _getUserData();
    });
  }

  // ✅ FIXED: Added missed + ended cases
  Color _getStatusColor() {
    switch (_currentQuiz?.quizStatus.toLowerCase()) {
      case 'live':
        return _DS.red;
      case 'upcoming':
        return _DS.gold;
      case 'missed':
        return _DS.indigo; // ✅ indigo for missed/assessment
      case 'ended':
        return _DS.textSec; // ✅ grey for ended
      default:
        return _DS.teal;
    }
  }

  // ✅ FIXED: Added missed + ended icons
  IconData _getStatusIcon() {
    switch (_currentQuiz?.quizStatus.toLowerCase()) {
      case 'live':
        return Icons.radio_button_checked;
      case 'upcoming':
        return Icons.schedule_rounded;
      case 'missed':
        return Icons.assignment_late_outlined; // ✅ assessment icon
      case 'ended':
        return Icons.check_circle_rounded;
      default:
        return Icons.circle;
    }
  }

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

  BoxDecoration _cardDecor({double radius = _DS.r16}) => BoxDecoration(
    color: _DS.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _DS.border),
    boxShadow: [BoxShadow(color: _DS.navy.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
  );

  TextStyle get _labelStyle =>
      const TextStyle(fontSize: _DS.fsXs, fontWeight: FontWeight.w600, color: _DS.textSec, letterSpacing: 0.4);

  TextStyle get _valueStyle => const TextStyle(fontSize: _DS.fsMd, fontWeight: FontWeight.w700, color: _DS.textPri);

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _DS.surface,
        appBar: AppBar(
          backgroundColor: _DS.navy,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Test Details',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_DS.teal), strokeWidth: 2.5),
              ),
              const SizedBox(height: 14),
              const Text(
                'Loading test details...',
                style: TextStyle(color: _DS.textSec, fontSize: _DS.fsMd, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError || _currentQuiz == null) {
      return _buildErrorScreen();
    }

    final bool canStartQuiz = _hasFullAccess;

    return Scaffold(
      backgroundColor: _DS.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildAccessBanner(),
                    const SizedBox(height: 12),

                    // ✅ Live banner only for live status
                    if (_isLive && canStartQuiz) ...[_buildLiveBanner(), const SizedBox(height: 12)],

                    // ✅ Assessment banner for missed status
                    if (_isMissed && _hasFullAccess) ...[_buildAssessmentBanner(), const SizedBox(height: 12)],

                    _buildCombinedHeader(),
                    const SizedBox(height: 12),

                    _buildStatsRow(),
                    const SizedBox(height: 12),

                    if (!canStartQuiz) _buildSubscriptionSection() else _buildScheduleSection(),
                    const SizedBox(height: 12),

                    if (_currentQuiz!.description.isNotEmpty) ...[_buildDescriptionCard(), const SizedBox(height: 12)],

                    if (_currentQuiz!.instruction.isNotEmpty) ...[_buildInstructionsCard(), const SizedBox(height: 12)],

                    _buildInfoCard(),
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

  Widget _buildErrorScreen() {
    IconData errorIcon;
    String headline;
    String subtext;
    Color iconColor;
    Color iconBg;

    switch (_errorType) {
      case 'no_internet':
        errorIcon = Icons.wifi_off_rounded;
        headline = 'No Internet Connection';
        subtext = 'Please check your internet and try again.';
        iconColor = const Color(0xFF1565C0);
        iconBg = const Color(0xFFE3F2FD);
        break;
      case 'timeout':
        errorIcon = Icons.timer_off_rounded;
        headline = 'Server Not Responding';
        subtext = 'Connection is slow or server is busy.\nPlease try again in a moment.';
        iconColor = const Color(0xFFE65100);
        iconBg = const Color(0xFFFFF3E0);
        break;
      case 'server':
        errorIcon = Icons.cloud_off_rounded;
        headline = 'Could Not Load Test';
        subtext = 'Something went wrong on the server.\nPlease try again.';
        iconColor = const Color(0xFF6A1B9A);
        iconBg = const Color(0xFFF3E5F5);
        break;
      case 'session':
        errorIcon = Icons.person_off_rounded;
        headline = 'Session Expired';
        subtext = 'Please reopen the app or logout\nand login again.';
        iconColor = _DS.red;
        iconBg = const Color(0xFFFFEBEE);
        break;
      default:
        errorIcon = Icons.error_outline_rounded;
        headline = 'Something Went Wrong';
        subtext = 'Could not load the test.\nPlease try again.';
        iconColor = _DS.textSec;
        iconBg = const Color(0xFFF4F6FB);
    }

    return Scaffold(
      backgroundColor: _DS.surface,
      appBar: AppBar(
        backgroundColor: _DS.navy,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Test Details',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(errorIcon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 24),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: _DS.fsXl,
                  fontWeight: FontWeight.w800,
                  color: _DS.textPri,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: _DS.fsMd,
                  color: _DS.textSec,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    shadowColor: _DS.teal.withOpacity(0.3),
                  ),
                  onPressed: _getUserData,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: _DS.fsLg, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: _DS.border),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(fontSize: _DS.fsMd, color: _DS.textSec, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 52,
      pinned: true,
      backgroundColor: _DS.navy,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _currentQuiz?.title ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
      flexibleSpace: FlexibleSpaceBar(background: Container(color: _DS.navy)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ACCESS BANNER — ✅ FIXED: added missed + ended cases
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAccessBanner() {
    final quiz = _currentQuiz!;
    final error = quiz.accessError ?? '';
    final msg = quiz.accessMessage ?? '';

    _AccessBannerCfg cfg;

    if (_hasFullAccess) {
      // ✅ Missed — attempted but expired
      if (_isMissed) {
        cfg = _AccessBannerCfg(
          gradient: [const Color(0xFF4527A0), const Color(0xFF311B92)],
          icon: Icons.assignment_late_outlined,
          badge: _planDisplayName,
          headline: 'Assessment Available',
          subLine: 'This quiz expired — attempt it now as an assessment.',
          statusLabel: 'ASSESSMENT',
          statusColor: const Color(0xFFB39DDB),
          locked: false,
        );
      }
      // ✅ Ended — user already attempted
      else if (_isEnded) {
        cfg = _AccessBannerCfg(
          gradient: [const Color(0xFF37474F), const Color(0xFF263238)],
          icon: Icons.check_circle_rounded,
          badge: _planDisplayName,
          headline: 'Test Completed',
          subLine: 'You have already attempted this test.',
          statusLabel: 'DONE',
          statusColor: const Color(0xFF80CBC4),
          locked: false,
        );
      }
      // Full access — purchased
      else if (quiz.isPurchased) {
        cfg = _AccessBannerCfg(
          gradient: [const Color(0xFF00897B), const Color(0xFF004D40)],
          icon: Icons.verified_rounded,
          badge: _planDisplayName,
          headline: 'Full Access Unlocked',
          subLine: msg.isNotEmpty ? msg : 'You can attempt this test anytime.',
          statusLabel: 'GRANTED',
          statusColor: const Color(0xFF69F0AE),
          locked: false,
        );
      }
      // Free test
      else {
        cfg = _AccessBannerCfg(
          gradient: [const Color(0xFF1976D2), const Color(0xFF0D47A1)],
          icon: Icons.lock_open_rounded,
          badge: _planDisplayName,
          headline: 'Free Test — Open to All',
          subLine: msg.isNotEmpty ? msg : 'This test is free to attempt.',
          statusLabel: 'FREE',
          statusColor: const Color(0xFF82B1FF),
          locked: false,
        );
      }
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

  // ═══════════════════════════════════════════════════════════════════════
  //  LIVE BANNER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLiveBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _DS.red,
        borderRadius: BorderRadius.circular(_DS.r12),
        boxShadow: [BoxShadow(color: _DS.red.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _livePulse ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 450),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'LIVE NOW — Join immediately, test has started!',
              style: TextStyle(color: Colors.white, fontSize: _DS.fsMd, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'JOIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: _DS.fsXs,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Assessment banner for missed quizzes
  Widget _buildAssessmentBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4527A0), Color(0xFF6366F1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(_DS.r12),
        boxShadow: [BoxShadow(color: _DS.indigo.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_late_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Quiz expired — attempt it now as an Assessment!',
              style: TextStyle(color: Colors.white, fontSize: _DS.fsMd, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'ATTEMPT',
              style: TextStyle(
                color: Colors.white,
                fontSize: _DS.fsXs,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COMBINED HEADER
  // ═══════════════════════════════════════════════════════════════════════
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
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 10, color: _DS.gold),
                        const SizedBox(width: 4),
                        const Text(
                          'Series',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _DS.gold),
                        ),
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
                    _buildTag(
                      icon: _getStatusIcon(),
                      label:
                          _isMissed
                              ? 'ASSESSMENT' // ✅ show ASSESSMENT not MISSED
                              : _currentQuiz!.quizStatus.toUpperCase(),
                      color: _getStatusColor(),
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

                if (_currentQuiz!.subscription_description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _DS.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _DS.border),
                    ),
                    child: Text(
                      _currentQuiz!.subscription_description,
                      style: const TextStyle(
                        fontSize: _DS.fsSm,
                        fontWeight: FontWeight.w400,
                        color: _DS.textSec,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                if (_remainingSeconds > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFBD038), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 14),
                            const SizedBox(width: 7),
                            Text(
                              _getCountdownLabel(),
                              style: const TextStyle(
                                fontSize: _DS.fsMd,
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _getCountdownText(),
                          style: const TextStyle(
                            fontSize: _DS.fsLg,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                            letterSpacing: 0.2,
                          ),
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

  // ═══════════════════════════════════════════════════════════════════════
  //  STATS GRID
  // ═══════════════════════════════════════════════════════════════════════
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

  Widget _buildBannerAd() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_DS.r12),
        child: SizedBox(
          height: bannerService.bannerAd!.size.height.toDouble(),
          width: bannerService.bannerAd!.size.width.toDouble(),
          child: AdWidget(ad: bannerService.bannerAd!),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    final error = _currentQuiz?.accessError ?? '';
    return error == 'upgrade_required' ? _buildFreeUserSection() : _buildPremiumSection();
  }

  Widget _buildFreeUserSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_DS.r20),
        boxShadow: [BoxShadow(color: _DS.navy.withOpacity(0.14), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_DS.r20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_DS.navy, Color(0xFF1A3A5C)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _DS.teal.withOpacity(0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_clock_rounded, color: _DS.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free Attempt Used — Upgrade to Continue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Subscribe for unlimited monthly attempts.',
                          style: TextStyle(
                            fontSize: _DS.fsXs,
                            color: Colors.white.withOpacity(0.68),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              color: _DS.card,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('WHAT YOU GET AFTER SUBSCRIBING'),
                  const SizedBox(height: 14),
                  _buildBenefitGrid([
                    _BenefitEntry(
                      emoji: '📝',
                      icon: Icons.quiz_outlined,
                      title: 'Unlimited Mock Tests',
                      desc: 'Full-length exam-pattern tests every day',
                      color: _DS.navy,
                    ),
                    _BenefitEntry(
                      emoji: '📰',
                      icon: Icons.newspaper_rounded,
                      title: 'Daily Current Affairs',
                      desc: 'Fresh GK & news updates daily',
                      color: const Color(0xFF1565C0),
                    ),
                    _BenefitEntry(
                      emoji: '🧩',
                      icon: Icons.psychology_outlined,
                      title: 'Practice Quizzes',
                      desc: 'Topic-wise quizzes for concept clarity',
                      color: _DS.teal,
                    ),
                    _BenefitEntry(
                      emoji: '📚',
                      icon: Icons.menu_book_rounded,
                      title: 'Study Material',
                      desc: 'PDFs, notes & video lessons',
                      color: const Color(0xFFE65100),
                    ),
                    _BenefitEntry(
                      emoji: '📊',
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      desc: 'Track weak areas & progress',
                      color: const Color(0xFF6A1B9A),
                    ),
                    _BenefitEntry(
                      emoji: '🏆',
                      icon: Icons.leaderboard_rounded,
                      title: 'All India Rank',
                      desc: 'Compare score nationwide',
                      color: _DS.gold,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_DS.teal.withOpacity(0.09), _DS.navy.withOpacity(0.04)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _DS.teal.withOpacity(0.28), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _DS.teal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: _DS.teal, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'One plan. Everything included.',
                                style: TextStyle(fontSize: _DS.fsMd, fontWeight: FontWeight.w800, color: _DS.textPri),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Subscribe once and unlock your full exam preparation toolkit.',
                                style: TextStyle(
                                  fontSize: _DS.fsXs,
                                  color: _DS.textSec,
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

            Container(
              color: _DS.card,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: _DS.border),
                  const SizedBox(height: 8),
                  _buildSectionLabel("THIS MONTH'S USAGE"),
                  const SizedBox(height: 12),
                  _buildUsageRow(
                    icon: Icons.assignment_outlined,
                    label: 'Mock Test',
                    used: 1,
                    total: 1,
                    color: _DS.red,
                  ),
                  const SizedBox(height: 10),
                  _buildUsageRow(
                    icon: Icons.quiz_outlined,
                    label: 'Live / Upcoming Test',
                    used: 1,
                    total: 1,
                    color: _DS.red,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _DS.teal.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _DS.teal.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: _DS.teal, size: 16),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Upgrade to Basic — get unlimited attempts for your course!',
                            style: TextStyle(
                              fontSize: _DS.fsSm,
                              color: _DS.textPri,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
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

  Widget _buildBenefitGrid(List<_BenefitEntry> items) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildBenefitEntryCard(items[i])),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < items.length ? _buildBenefitEntryCard(items[i + 1]) : const SizedBox()),
          ],
        ),
      );
      if (i + 2 < items.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildBenefitEntryCard(_BenefitEntry item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: item.color.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
                child: Icon(item.icon, color: item.color, size: 15),
              ),
              const SizedBox(width: 6),
              Text(item.emoji, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _DS.textPri, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            item.desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: _DS.textSec, fontWeight: FontWeight.w400, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(color: _DS.teal, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: _labelStyle.copyWith(fontSize: 10, color: _DS.textSec, letterSpacing: 0.6)),
      ],
    );
  }

  Widget _buildUsageRow({
    required IconData icon,
    required String label,
    required int used,
    required int total,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: _DS.fsMd, color: _DS.textPri, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$used / $total',
                    style: TextStyle(fontSize: _DS.fsMd, color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: used / total,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSection() {
    final error = _currentQuiz?.accessError ?? '';
    final message =
        error == 'plan_expired'
            ? 'Your plan has expired.\nRenew to regain access.'
            : 'This test is not in\nyour current course.';
    final subtitle =
        error == 'plan_expired'
            ? 'Renew your plan — access will be restored immediately.'
            : 'Go Premium — unlimited access to all courses.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_DS.r20),
        border: Border.all(color: _DS.border),
        boxShadow: [BoxShadow(color: _DS.navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_DS.r20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_DS.navy, Color(0xFF1A3A5C)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _DS.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _DS.gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: _DS.gold, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'Upgrade Required',
                          style: TextStyle(fontSize: _DS.fsXs, fontWeight: FontWeight.w700, color: _DS.gold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: _DS.fsXl,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle, style: TextStyle(fontSize: _DS.fsSm, color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
            Container(
              color: _DS.card,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBenefit(
                    Icons.all_inclusive_rounded,
                    'Unlimited Test Access',
                    'Attempt all tests without limits',
                    _DS.gold,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.menu_book_rounded,
                    'Complete Study Material',
                    'PDFs, videos, notes & practice sets',
                    _DS.teal,
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit(Icons.school_rounded, 'Expert Guidance', 'Learn from experienced teachers', _DS.gold),
                  const SizedBox(height: 8),
                  _buildBenefit(
                    Icons.bar_chart_rounded,
                    'Performance Analytics',
                    'Track your progress with detailed reports',
                    _DS.teal,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DS.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: _DS.fsMd, fontWeight: FontWeight.w700, color: _DS.textPri),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: _DS.fsXs, color: _DS.textSec, height: 1.35)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: _DS.teal, size: 15),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.calendar_today_rounded, 'Test Schedule'),
          const SizedBox(height: 14),
          _buildScheduleRow(
            icon: Icons.play_circle_outline_rounded,
            label: 'Start',
            rawDateTime: _currentQuiz!.startDateTime,
            color: _DS.teal,
          ),
          if (_currentQuiz!.endDateTime.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildScheduleRow(
              icon: Icons.stop_circle_outlined,
              label: 'End',
              rawDateTime: _currentQuiz!.endDateTime,
              color: _DS.red,
            ),
          ],
          if (_currentQuiz!.timeLimit.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildScheduleRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              rawDateTime: '',
              color: _DS.gold,
              overrideValue: '${_currentQuiz!.timeLimit} min',
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _DS.teal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _DS.teal.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_outlined, size: 14, color: _DS.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Designed to simulate actual exam conditions — same pattern, same time pressure.',
                    style: TextStyle(fontSize: _DS.fsSm, color: _DS.textPri, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required IconData icon,
    required String label,
    required String rawDateTime,
    required Color color,
    String? overrideValue,
  }) {
    String dateText = '';
    String timeText = '';

    if (overrideValue != null) {
      dateText = overrideValue;
    } else if (rawDateTime.isNotEmpty) {
      final formatted = _formatDateTime(rawDateTime);
      final parts = formatted.split('  •  ');
      dateText = parts.isNotEmpty ? parts[0] : formatted;
      timeText = parts.length > 1 ? parts[1] : '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: _DS.fsMd, fontWeight: FontWeight.w600, color: _DS.textSec)),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                dateText,
                style: const TextStyle(fontSize: _DS.fsMd, fontWeight: FontWeight.w800, color: _DS.textPri),
              ),
              if (timeText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    timeText,
                    style: TextStyle(fontSize: _DS.fsXs, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHead(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: _DS.navy.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _DS.navy, size: 14),
        ),
        const SizedBox(width: 9),
        Text(label, style: const TextStyle(fontSize: _DS.fsMd, fontWeight: FontWeight.w700, color: _DS.textPri)),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.description_outlined, 'About This Test'),
          const SizedBox(height: 12),
          Text(
            _currentQuiz!.description,
            style: const TextStyle(fontSize: _DS.fsMd, color: _DS.textSec, fontWeight: FontWeight.w400, height: 1.65),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.rule_rounded, 'Instructions'),
          const SizedBox(height: 12),
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
      return Text(
        _removeHtmlTags(text),
        style: const TextStyle(fontSize: _DS.fsMd, color: _DS.textSec, fontWeight: FontWeight.w400, height: 1.6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          matches.map((match) {
            final clean = _removeHtmlTags(match.group(1) ?? '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: _DS.teal, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      clean,
                      style: const TextStyle(
                        fontSize: _DS.fsMd,
                        color: _DS.textSec,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                      ),
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

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Important Information'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.touch_app_rounded, 'Single attempt only — make every answer count'),
          _buildInfoRow(Icons.wifi_rounded, 'Stable internet connection required throughout'),
          _buildInfoRow(Icons.leaderboard_rounded, 'Instant results & live All India Ranking after test'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _DS.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: _DS.fsSm, color: _DS.textSec, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BOTTOM BAR — ✅ FIXED: missed + ended cases added
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBottomBar() {
    final quiz = _currentQuiz;
    if (quiz == null) return const SizedBox.shrink();

    // 1. Resume pending attempt
    if (quiz.pendingAttemptId != null && quiz.pendingAttemptId! > 0) {
      return _buildActionBar(
        label: 'Resume Attempt',
        icon: Icons.play_circle_outline_rounded,
        colors: [_DS.teal, _DS.tealDark],
        shadowColor: _DS.teal.withOpacity(0.3),
        onTap: _navigateToQuiz,
      );
    }

    // 2. Already attempted (ended status — user completed it)
    if (quiz.is_attempted) {
      return _buildActionBar(
        label: 'Already Attempted',
        icon: Icons.check_circle_outline_rounded,
        colors: [Colors.grey.shade500, Colors.grey.shade700],
        shadowColor: Colors.grey.withOpacity(0.2),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You have already attempted this test'),
              backgroundColor: _DS.textSec,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      );
    }

    // 3. No access — show activate plan
    if (!_hasFullAccess) {
      return _buildActionBar(
        label: 'Activate Plan',
        icon: Icons.workspace_premium_rounded,
        colors: [_DS.teal, _DS.navy],
        shadowColor: _DS.teal.withOpacity(0.3),
        onTap: _handleSubscribe,
      );
    }

    // 4. Has access — check quiz status
    switch (quiz.quizStatus.toLowerCase()) {
      case 'live':
        return _buildActionBar(
          label: 'Join Test Now',
          icon: Icons.play_arrow_rounded,
          colors: [_DS.red, const Color(0xFF870000)],
          shadowColor: _DS.red.withOpacity(0.35),
          onTap: _handleStartQuiz,
        );

      case 'upcoming':
        return _buildRemindMeBar();

      // ✅ FIXED: missed — allow attempt as assessment
      case 'missed':
        return _buildActionBar(
          label: 'Attempt Now',
          icon: Icons.assignment_late_outlined,
          colors: [_DS.indigo, const Color(0xFF4527A0)],
          shadowColor: _DS.indigo.withOpacity(0.35),
          onTap: _handleStartQuiz,
        );

      // ✅ FIXED: ended — quiz over, cannot attempt
      case 'ended':
      default:
        return _buildActionBar(
          label: 'Test Ended',
          icon: Icons.lock_clock_rounded,
          colors: [Colors.grey.shade500, Colors.grey.shade700],
          shadowColor: Colors.grey.withOpacity(0.2),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This test has ended'))),
        );
    }
  }

  Widget _buildActionBar({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _DS.card,
        border: Border(top: BorderSide(color: _DS.border)),
        boxShadow: [BoxShadow(color: _DS.navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 14, offset: const Offset(0, 5))],
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
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 9),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: _DS.fsLg,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _DS.card,
        border: Border(top: BorderSide(color: _DS.border)),
        boxShadow: [BoxShadow(color: _DS.navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBD038), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 14),
                  const SizedBox(width: 7),
                  Text(
                    _getCountdownLabel(),
                    style: const TextStyle(fontSize: _DS.fsMd, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _getCountdownText(),
                    style: const TextStyle(
                      fontSize: _DS.fsLg,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_DS.navy, _DS.teal]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _DS.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Reminder set! We'll notify you before the test starts."),
                        backgroundColor: _DS.teal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 9),
                        Text(
                          'Remind Me',
                          style: TextStyle(
                            fontSize: _DS.fsLg,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
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

// ═══════════════════════════════════════════════════════════════════════════
//  Config classes
// ═══════════════════════════════════════════════════════════════════════════
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

class _BenefitEntry {
  final String emoji;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _BenefitEntry({
    required this.emoji,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}
