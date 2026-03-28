import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
  bool _isPurchased = false;
  int _product_sub_id = 0;
  int _isPremium = 0;
  bool _isAccessible = false;
  bool _isFree = false;
  StudyMaterialDetailsItem? _currentMaterial;

  bool _descExpanded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    await fetchStudyCategory(_user!.id);
    if (!mounted) return;
    _fadeController.forward();
    setState(() {});
  }

  Future<List<StudyMaterialDetailsItem>> fetchStudyCategory(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'material_id': widget.contentId.toString(),
        'user_id': userid.toString(),
        'page_API_call': widget.page_API_call,
      };

      final responseFuture = await authRepository.get_study_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        final List list = responseData['data'] ?? [];

        _studyMaterials_new = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();

        if (_studyMaterials_new.isNotEmpty) {
          _currentMaterial = _studyMaterials_new.first;
          _isPurchased = _currentMaterial!.isPurchased;
          _isAccessible = _currentMaterial!.isAccessible;
          _isFree = !_currentMaterial!.isPaid;
          _isPremium = _currentMaterial!.is_premium ?? 0;
          _product_sub_id = _currentMaterial!.subscription_id ?? 0;
        }

        setState(() => _isLoading = false);
        return _studyMaterials_new;
      } else {
        setState(() => _isLoading = false);
        return [];
      }
    } catch (e) {
      print('Error fetching study details: $e');
      setState(() => _isLoading = false);
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => StudyMaterialPurchaseHistoryScreen()));
  }

  void _handleSubscribe() {
    if (_currentMaterial == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => PricingPage())).then((value) {
      if (value == true) _getUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F8),
        appBar: AppBar(
          backgroundColor: AppColors.darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
              ),
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen))),
      );
    }

    if (_currentMaterial == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F8),
        appBar: AppBar(
          backgroundColor: AppColors.darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Error', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text('Course not found')),
      );
    }

    final bool canStart = _isPurchased || _isAccessible || _isFree;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
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
        title: Text(
          _currentMaterial!.Material_name,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildHeroBanner(canStart),
                const SizedBox(height: 14),
                if (canStart) _buildAccessBanner(),
                if (canStart) const SizedBox(height: 12),
                if (!canStart) _buildWhatYouGetSection(),
                if (!canStart) const SizedBox(height: 12),
                if (_currentMaterial!.description.isNotEmpty) ...[_buildDescriptionCard(), const SizedBox(height: 12)],
                _buildInstructorCard(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(canStart),
    );
  }

  Widget _buildHeroBanner(bool canStart) {
    final String? thumbUrl = _currentMaterial!.thumbnail;
    final bool hasThumb = thumbUrl != null && thumbUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkNavy, Color(0xFF0D2137)],
        ),
      ),
      child: Stack(
        children: [
          if (hasThumb)
            Positioned.fill(
              child: Image.network(
                thumbUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.62),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          if (hasThumb)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.darkNavy.withOpacity(0.85)],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.white.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentMaterial!.contentType.toUpperCase() == 'PDF'
                                ? Icons.picture_as_pdf
                                : Icons.video_library,
                            size: 11,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _currentMaterial!.contentType.toUpperCase() == 'PDF' ? 'PDF MATERIAL' : 'VIDEO LECTURE',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (canStart)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.55)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              _isFree ? 'FREE COURSE' : 'ENROLLED',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AppRichText.setTextPoppinsStyle(
                  context,
                  _currentMaterial!.Material_name,
                  22,
                  Colors.white,
                  FontWeight.w800,
                  4,
                  TextAlign.left,
                  1.3,
                ),
                const SizedBox(height: 8),
                if (_currentMaterial!.subscription_description.isNotEmpty)
                  AppRichText.setTextPoppinsStyle(
                    context,
                    _currentMaterial!.subscription_description,
                    12,
                    Colors.white,
                    FontWeight.w400,
                    10,
                    TextAlign.left,
                    1.5,
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildHeroStat('⚡', 'Live Quizzes', 'Monthly'),
                    const SizedBox(width: 10),
                    _buildHeroStat('📝', 'Mock Tests', 'Unlimited'),
                    const SizedBox(width: 10),
                    _buildHeroStat('📚', 'Study Material', 'Full Access'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.tealGreen)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      _isFree
                          ? [AppColors.tealGreen, AppColors.darkNavy]
                          : [const Color(0xFF0D7B5F), AppColors.darkNavy],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFree ? Icons.celebration_outlined : Icons.verified_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isFree ? 'Free Content' : 'Course Purchased',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    _isFree
                        ? 'This Course\nIs Completely FREE!'
                        : _isPurchased
                        ? 'Course Already\nPurchased!'
                        : 'Included In\nYour Plan!',
                    17,
                    Colors.white,
                    FontWeight.w800,
                    2,
                    TextAlign.left,
                    1.3,
                  ),
                  const SizedBox(height: 6),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    _isFree
                        ? 'Start now — no charges at all!'
                        : _isPurchased
                        ? 'Your access is fully unlocked'
                        : 'This is included in your current plan',
                    12,
                    Colors.white.withOpacity(0.85),
                    FontWeight.w400,
                    1,
                    TextAlign.left,
                    0,
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'You have access to all of this:',
                    12,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    1,
                    TextAlign.left,
                    0,
                  ),
                  const SizedBox(height: 14),
                  _buildCheckItem(
                    Icons.picture_as_pdf_outlined,
                    _currentMaterial!.contentType.toUpperCase() == 'PDF' ? 'PDF Material' : 'Video Lecture',
                    'You have full access to this content',
                    AppColors.tealGreen,
                  ),
                  _buildCheckItem(
                    Icons.history_edu_outlined,
                    'Previous Year Papers',
                    'Last 5 years question papers',
                    AppColors.tealGreen,
                  ),
                  _buildCheckItem(
                    Icons.bar_chart_rounded,
                    'Performance Analytics',
                    'Track your topic-wise weak areas',
                    AppColors.darkNavy,
                  ),
                  _buildCheckItem(
                    Icons.leaderboard_outlined,
                    'All India Ranking',
                    'Compare with students nationwide',
                    AppColors.tealGreen,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.tealGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school_outlined, color: AppColors.tealGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Tap "Start Learning" to view all your courses!',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatYouGetSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkNavy, Color(0xFF0D3B2E)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.white, size: 13),
                        SizedBox(width: 5),
                        Text(
                          'Premium Course',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'One Course,\nEverything Included!',
                    20,
                    Colors.white,
                    FontWeight.w800,
                    2,
                    TextAlign.left,
                    1.3,
                  ),
                  const SizedBox(height: 6),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Activate and get unlimited access',
                    12,
                    Colors.white.withOpacity(0.65),
                    FontWeight.w400,
                    1,
                    TextAlign.left,
                    0,
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'This package includes:',
                    12,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    1,
                    TextAlign.left,
                    0,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureTile(
                          emoji: '📝',
                          title: 'Mock Tests',
                          subtitle: 'Unlimited\nattempts',
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFeatureTile(
                          emoji: '⚡',
                          title: 'Live Quizzes',
                          subtitle: 'Monthly\naccess',
                          color: AppColors.tealGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem(
                    Icons.history_edu_outlined,
                    'Previous Year Papers',
                    'Last 5 years question papers',
                    AppColors.tealGreen,
                  ),
                  _buildCheckItem(
                    Icons.picture_as_pdf_outlined,
                    'Study PDFs & Notes',
                    'Chapter-wise detailed notes',
                    AppColors.tealGreen,
                  ),
                  _buildCheckItem(
                    Icons.video_library_outlined,
                    'Video Lectures',
                    'Video lessons by expert teachers',
                    AppColors.darkNavy,
                  ),
                  _buildCheckItem(
                    Icons.bar_chart_rounded,
                    'Performance Analytics',
                    'Track your topic-wise weak areas',
                    AppColors.darkNavy,
                  ),
                  _buildCheckItem(
                    Icons.leaderboard_outlined,
                    'All India Ranking',
                    'Compare with students nationwide',
                    AppColors.tealGreen,
                  ),
                  _buildCheckItem(
                    Icons.update_rounded,
                    'Regular Updates',
                    'New content added every week',
                    AppColors.darkNavy,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.tealGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_outlined, color: AppColors.tealGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Everything unlimited for the course validity — no hidden charges!',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.greyS600, height: 1.4, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final text = _currentMaterial!.description;
    final bool isLong = text.length > 200;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.white, size: 15),
              ),
              const SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                context,
                'About This Course',
                13,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: (!isLong || _descExpanded) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Stack(
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  text,
                  12,
                  AppColors.greyS700,
                  FontWeight.w400,
                  4,
                  TextAlign.left,
                  1.5,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withOpacity(0.0), Colors.white],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            secondChild: AppRichText.setTextPoppinsStyle(
              context,
              text,
              12,
              AppColors.greyS700,
              FontWeight.w400,
              999,
              TextAlign.left,
              1.5,
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _descExpanded ? 'Read Less  ' : 'Read More  ',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tealGreen),
                  ),
                  Icon(
                    _descExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.tealGreen,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructorCard() {
    final name = _currentMaterial!.coaching_name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'I';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructor',
                  style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                ),
                if (_currentMaterial!.coaching_bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Html(data: _currentMaterial!.coaching_bio),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: AppColors.tealGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Instructor',
                      style: TextStyle(fontSize: 10, color: AppColors.tealGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool canStart) {
    final String btnLabel = canStart ? 'Start Learning' : 'Activate Now';
    final IconData btnIcon = canStart ? Icons.play_circle_filled : Icons.workspace_premium;
    const List<Color> btnColors = [AppColors.tealGreen, AppColors.darkNavy];
    const Color textColor = AppColors.white;

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
            gradient: const LinearGradient(colors: btnColors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: btnColors.first.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => canStart ? _handleStartLearning() : _handleSubscribe(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(btnIcon, color: textColor, size: 21),
                    const SizedBox(width: 9),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      btnLabel,
                      15,
                      textColor,
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
}
