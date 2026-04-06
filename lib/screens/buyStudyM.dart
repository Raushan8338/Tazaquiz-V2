import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/ads/banner_ads_helper.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/screens/PDFViewerPage.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/study_material_details_item.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class BuyCoursePage extends StatefulWidget {
  final String contentId;
  final String page_API_call;

  BuyCoursePage({required this.contentId, required this.page_API_call});

  @override
  _BuyCoursePageState createState() => _BuyCoursePageState();
}

class _BuyCoursePageState extends State<BuyCoursePage> with SingleTickerProviderStateMixin {
  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;
  UserModel? _user;
  List<StudyMaterialDetailsItem> _studyMaterials_new = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorType = '';
  bool _isPurchased = false;
  int _product_sub_id = 0;
  int _isPremium = 0;
  bool _isAccessible = false;
  bool _isFree = false;
  StudyMaterialDetailsItem? _currentMaterial;
  bool _descExpanded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _navy = Color(0xFF0A1628);
  static const _green = Color(0xFF1D9E75);
  static const _greenMid = Color(0xFF0F6E56);
  static const _greenLight = Color(0xFFE8F8F2);
  static const _greenBorder = Color(0xFF9FE1CB);
  static const _bg = Color(0xFFF0F3F8);
  static const _cardBg = Colors.white;
  static const _textMuted = Color(0xFF6B7A99);
  Color get _gold => AppColors.lightGold;
  Color get _primary => AppColors.darkNavy;
  static const _borderCol = Color(0xFFE4E9F4);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorType = '';
      });
    try {
      _user = await SessionManager.getUser();
      if (_user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _user = await SessionManager.getUser();
      }
      if (_user == null) {
        if (mounted)
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorType = 'session';
          });
        return;
      }
      await fetchStudyCategory(_user!.id);
      if (!mounted) return;
      _fadeController.forward();
      setState(() {});
    } catch (e) {
      print('getUserData error: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'unknown';
        });
    }
  }

  Future<List<StudyMaterialDetailsItem>> fetchStudyCategory(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'material_id': widget.contentId.toString(),
        'user_id': userid.toString(),
        'page_API_call': widget.page_API_call,
      };
      final responseFuture = await authRepository
          .get_study_wise_details(data)
          .timeout(const Duration(seconds: 15), onTimeout: () => throw TimeoutException('Request timed out'));

      if (responseFuture.statusCode == 200) {
        final List list = responseFuture.data['data'] ?? [];
        _studyMaterials_new = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();
        if (_studyMaterials_new.isNotEmpty) {
          _currentMaterial = _studyMaterials_new.first;
          _isPurchased = _currentMaterial!.isPurchased;
          _isAccessible = _currentMaterial!.isAccessible;
          _isFree = !_currentMaterial!.isPaid;
          _isPremium = _currentMaterial!.is_premium ?? 0;
          _product_sub_id = _currentMaterial!.subscription_id ?? 0;
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
        return _studyMaterials_new;
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'server';
        });
        return [];
      }
    } on TimeoutException {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'timeout';
        });
      return [];
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType =
              (msg.contains('socket') || msg.contains('network') || msg.contains('connection'))
                  ? 'no_internet'
                  : 'unknown';
        });
      return [];
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    bannerService.dispose();
    super.dispose();
  }

  void _handleStartLearning() {
    if (_currentMaterial == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => StudyMaterialPurchaseHistoryScreen()));
  }

  void _handleSubscribe() {
    if (_currentMaterial == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PricingPage(CourseIds: _currentMaterial!.subscription_id.toString())),
    ).then((v) {
      if (v == true) _getUserData();
    });
  }

  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    if (_hasError || _currentMaterial == null) return _errorScreen();

    final bool canStart = _isPurchased || _isAccessible || _isFree;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(title: _currentMaterial!.Material_name),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _heroBanner(canStart),
                const SizedBox(height: 16),
                if (canStart) ...[_accessBanner(), const SizedBox(height: 16)],
                if (!canStart) ...[_whatYouGetSection(), const SizedBox(height: 16)],
                if (_currentMaterial!.description.isNotEmpty) ...[_descriptionCard(), const SizedBox(height: 16)],
                _instructorCard(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(canStart),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar({String title = 'Course Details'}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_navy, Color(0xFF0D4B3B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Banner ───────────────────────────────────────────────────────
  Widget _heroBanner(bool canStart) {
    final String? thumbUrl = _currentMaterial!.thumbnail;
    final bool hasThumb = thumbUrl != null && thumbUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, Color(0xFF0D2137)],
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          if (hasThumb)
            Positioned.fill(
              child: Image.network(
                thumbUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.60),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_navy.withOpacity(hasThumb ? 0.35 : 0.0), _navy.withOpacity(0.97)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _heroBadge(
                      icon:
                          _currentMaterial!.contentType.toUpperCase() == 'PDF'
                              ? Icons.picture_as_pdf_outlined
                              : Icons.video_library_outlined,
                      label: 'Complete Course',
                    ),
                    if (canStart) ...[
                      const SizedBox(width: 8),
                      _heroBadge(
                        icon: Icons.verified_rounded,
                        label: _isFree ? 'FREE COURSE' : 'ENROLLED',
                        accent: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _currentMaterial!.Material_name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.22,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (_currentMaterial!.subscription_description.isNotEmpty)
                  Text(
                    _currentMaterial!.subscription_description,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.58), height: 1.5),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _heroStat('⚡', 'Live Test', 'Unlimited'),
                    const SizedBox(width: 8),
                    _heroStat('📝', 'Mock Tests', 'Unlimited'),
                    const SizedBox(width: 8),
                    _heroStat('📚', 'PYPs', 'Upto 10 Years'),
                    const SizedBox(width: 8),
                    _heroStat('📚', 'Study Material', 'Full Access'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge({required IconData icon, required String label, bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? _green.withOpacity(0.28) : Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent ? _green.withOpacity(0.75) : Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _green)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.65),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Access Banner ─────────────────────────────────────────────────────
  Widget _accessBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.18), blurRadius: 28, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isFree ? [_green, _greenMid] : [const Color(0xFF0D7B5F), _navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isFree ? Icons.celebration_outlined : Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isFree ? 'Free Content' : 'Course Purchased',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isFree
                                ? 'This Course\nIs Completely FREE!'
                                : _isPurchased
                                ? 'Course Already\nPurchased!'
                                : 'Included In\nYour Plan!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isFree
                                ? 'Start now — no charges at all!'
                                : _isPurchased
                                ? 'Your access is fully unlocked'
                                : 'This is included in your current plan',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.72)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: Icon(
                        _isFree ? Icons.lock_open_rounded : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: _cardBg,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You have access to all of this:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy),
                    ),
                    const SizedBox(height: 14),
                    _checkItem(
                      Icons.picture_as_pdf_outlined,
                      _currentMaterial!.contentType.toUpperCase() == 'PDF' ? 'PDF Material' : 'Complete Course',
                      'You have full access to this content',
                      _green,
                    ),
                    _checkItem(
                      Icons.history_edu_outlined,
                      'Previous Year Papers',
                      'Last 5 years question papers',
                      _green,
                    ),
                    _checkItem(
                      Icons.bar_chart_rounded,
                      'Performance Analytics',
                      'Track your topic-wise weak areas',
                      _navy,
                    ),
                    _checkItem(
                      Icons.leaderboard_outlined,
                      'All India Ranking',
                      'Compare with students nationwide',
                      _green,
                    ),
                    const SizedBox(height: 14),
                    _infoBox(icon: Icons.school_outlined, text: 'Tap "Start Learning" to view all your courses!'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── What You Get ──────────────────────────────────────────────────────
  Widget _whatYouGetSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.18), blurRadius: 28, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navy, Color(0xFF0D3B2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withOpacity(0.28)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.workspace_premium, color: Colors.white, size: 11),
                                SizedBox(width: 5),
                                Text(
                                  'Premium Course',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'One Course,\nEverything Included!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Activate and get unlimited access',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      ),
                      child: const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
              Container(
                color: _cardBg,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This package includes:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy),
                    ),
                    const SizedBox(height: 14),
                    _buildBenefitGrid([
                      _BenefitItem(
                        emoji: '📝',
                        icon: Icons.assignment_rounded,
                        title: 'Mock Tests',
                        desc: 'Attempt all mock tests in "${_currentMaterial!.Material_name}" — unlimited practice',
                        color: _primary,
                      ),
                      _BenefitItem(
                        emoji: '🎯',
                        icon: Icons.quiz_rounded,
                        title: 'Full Mock Tests',
                        desc: 'Full-length real exam simulation papers for "${_currentMaterial!.Material_name}"',
                        color: const Color(0xFFE65100),
                      ),
                      _BenefitItem(
                        emoji: '📜',
                        icon: Icons.history_edu_rounded,
                        title: 'Previous Year Papers',
                        desc: 'Solve actual past exam questions (PYPs) for "${_currentMaterial!.Material_name}"',
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
                    _checkItem(
                      Icons.history_edu_outlined,
                      'Previous Year Papers',
                      'Last 5 years question papers',
                      _green,
                    ),
                    _checkItem(
                      Icons.picture_as_pdf_outlined,
                      'Study PDFs & Notes',
                      'Chapter-wise detailed notes',
                      _green,
                    ),
                    _checkItem(
                      Icons.video_library_outlined,
                      'Complete Course',
                      'Complete Course by expert teachers',
                      _navy,
                    ),
                    _checkItem(
                      Icons.bar_chart_rounded,
                      'Performance Analytics',
                      'Track your topic-wise weak areas',
                      _navy,
                    ),
                    _checkItem(
                      Icons.leaderboard_outlined,
                      'All India Ranking',
                      'Compare with students nationwide',
                      _green,
                    ),
                    _checkItem(Icons.update_rounded, 'Regular Updates', 'New content added every week', _navy),
                    const SizedBox(height: 14),
                    _infoBox(
                      icon: Icons.verified_outlined,
                      text: 'Everything unlimited for the course validity — no hidden charges!',
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
              TranslatedText(item.emoji, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _primary, height: 1.2)),
          const SizedBox(height: 4),
          TranslatedText(
            item.desc,
            style: TextStyle(fontSize: 9.5, color: AppColors.greyS600, fontWeight: FontWeight.w400, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Description Card ──────────────────────────────────────────────────
  Widget _descriptionCard() {
    final text = _currentMaterial!.description;
    final bool isLong = text.length > 200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_green, _navy]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text(
                  'About This Course',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: (!isLong || _descExpanded) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Stack(
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    text,
                    12.5,
                    AppColors.greyS700,
                    FontWeight.w400,
                    4,
                    TextAlign.left,
                    1.6,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0), Colors.white],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              secondChild: AppRichText.setTextPoppinsStyle(
                context,
                text,
                12.5,
                AppColors.greyS700,
                FontWeight.w400,
                999,
                TextAlign.left,
                1.6,
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _descExpanded ? 'Read Less' : 'Read More',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _green),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _descExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: _green,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Instructor Card ───────────────────────────────────────────────────
  Widget _instructorCard() {
    final name = _currentMaterial!.coaching_name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'I';
    final profileIcon = _currentMaterial!.profile_icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient:
                    (profileIcon == null || profileIcon.isEmpty) ? const LinearGradient(colors: [_green, _navy]) : null,
                image:
                    (profileIcon != null && profileIcon.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(profileIcon), fit: BoxFit.cover)
                        : null,
              ),
              child:
                  (profileIcon == null || profileIcon.isEmpty)
                      ? Center(
                        child: Text(
                          initial,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructor',
                    style: TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 3),
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navy)),
                  if (_currentMaterial!.coaching_bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Html(data: _currentMaterial!.coaching_bio),
                  ],
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_rounded, size: 12, color: _green),
                        SizedBox(width: 5),
                        Text(
                          'Verified Instructor',
                          style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w700),
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

  // ── Bottom Bar ────────────────────────────────────────────────────────
  Widget _bottomBar(bool canStart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_green, _navy]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _green.withOpacity(0.38), blurRadius: 18, offset: const Offset(0, 7))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => canStart ? _handleStartLearning() : _handleSubscribe(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canStart ? Icons.play_circle_filled : Icons.workspace_premium,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        canStart ? 'Start Learning' : 'Activate Now',
                        style: const TextStyle(
                          fontSize: 16,
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
      ),
    );
  }

  // ── Error Screen ──────────────────────────────────────────────────────
  Widget _errorScreen() {
    IconData errorIcon;
    String headline, subtext;
    Color iconColor, iconBg;
    switch (_errorType) {
      case 'no_internet':
        errorIcon = Icons.wifi_off_rounded;
        headline = 'No internet connection';
        subtext = 'Please check your connection\nand try again.';
        iconColor = const Color(0xFF1565C0);
        iconBg = const Color(0xFFE3F2FD);
        break;
      case 'timeout':
        errorIcon = Icons.timer_off_rounded;
        headline = 'Connection timed out';
        subtext = 'Server took too long to respond.\nPlease try again.';
        iconColor = const Color(0xFFE65100);
        iconBg = const Color(0xFFFFF3E0);
        break;
      case 'server':
        errorIcon = Icons.cloud_off_rounded;
        headline = 'Course could not be loaded';
        subtext = 'There was an issue fetching data.\nPlease try again.';
        iconColor = const Color(0xFF6A1B9A);
        iconBg = const Color(0xFFF3E5F5);
        break;
      case 'session':
        errorIcon = Icons.person_off_rounded;
        headline = 'Session expired';
        subtext = 'Please reopen the app\nor log in again.';
        iconColor = const Color(0xFFE53935);
        iconBg = const Color(0xFFFFEBEE);
        break;
      default:
        errorIcon = Icons.error_outline_rounded;
        headline = 'Something went wrong';
        subtext = 'We could not load the course.\nPlease try again.';
        iconColor = const Color(0xFF6B7A99);
        iconBg = const Color(0xFFF4F6FB);
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
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
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _navy, height: 1.3),
              ),
              const SizedBox(height: 10),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textMuted, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _getUserData,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Try Again', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
                      side: const BorderSide(color: _borderCol),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ════════════════════════════════════════════════════════════════════

  Widget _featureTile({required String emoji, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          TranslatedText(
            subtitle,
            style: const TextStyle(fontSize: 10, color: _textMuted, height: 1.4, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 2),
                TranslatedText(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, color: color, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _greenBorder.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _green.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: _green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: _navy.withOpacity(0.8), fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
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
