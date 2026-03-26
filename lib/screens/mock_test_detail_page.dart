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
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

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

  Color get _mockPrimary => AppColors.darkNavy;
  Color get _mockSecondary => AppColors.darkNavy.withOpacity(0.85);
  Color get _mockAccent => AppColors.tealGreen;
  Color get _mockGold => AppColors.lightGold;
  static Color _mockBg = Color(0xFFF0F2F8);

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
    _fadeController = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
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
       print('Fetching quiz details with data: $data');
      final responseFuture = await authRepository.get_quizId_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        if (responseData['status'] == true && responseData['data'] != null) {
          _currentQuiz = QuizItem.fromJson(responseData['data']);
          setState(() {
            _isPurchased = _currentQuiz!.isPurchased;
            _isAccessible = _currentQuiz!.accessStatus;
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

  void _handleStartMockTest() {
    if (_currentQuiz == null) return;

    if (!_currentQuiz!.accessStatus) {
      _showAccessDialog();
      return;
    }

    // ── CHANGED: Free users jinka attempt already ho chuka hai ──
    // unhe seedha subscription page pe bhejo — no rewarded ad
    if (_isFree && _attempted) {
      _handleSubscribe();
      return;
    }

    // Pehli baar free test de raha hai → rewarded ad dikhao
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
        message = 'You can only access mock tests from your enrolled course. Upgrade your plan!';
        buttonText = 'Upgrade Plan';
        break;
      case 'upgrade_required':
        // ── CHANGED: seedha subscribe page pe le jao ──
        Navigator.pop(context);
        _handleSubscribe();
        return;
      case 'plan_expired':
        message = 'Your plan has expired. Renew your subscription to regain access to all mock tests.';
        buttonText = 'Renew Now';
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
            title: Text('Access Required', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Text(message, style: TextStyle(fontSize: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mockPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (showResume) {
                    _navigateToMockTest();
                  } else {
                    _handleSubscribe();
                  }
                },
                child: Text(buttonText),
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

  Color _getDifficultyColor() {
    switch (_currentQuiz?.difficultyLevel.toLowerCase()) {
      case 'easy':
        return Color(0xFF2E7D32);
      case 'medium':
        return Color(0xFFF9A825);
      case 'hard':
        return Color(0xFFC62828);
      default:
        return _mockAccent;
    }
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw.trim().replaceAll(' ', 'T'));
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        backgroundColor: _mockBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_mockPrimary), strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Loading mock test...',
                style: TextStyle(color: _mockPrimary.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuiz == null) {
      return Scaffold(
        backgroundColor: _mockBg,
        appBar: AppBar(backgroundColor: _mockPrimary, title: Text('Error')),
        body: Center(child: Text('Test not found')),
      );
    }

    final bool canStart = _currentQuiz!.accessStatus;

    return Scaffold(
      backgroundColor: _mockBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    SizedBox(height: 14),
                    if (canStart) _buildAccessBanner(),
                    if (canStart) SizedBox(height: 10),
                    _buildCourseInfo(),
                    SizedBox(height: 10),
                    _buildMockHeader(),
                    SizedBox(height: 10),
                    _buildStatsRow(),
                    SizedBox(height: 10),
                    _buildExpectSection(),
                    SizedBox(height: 10),
                    if (isBannerLoaded && bannerService.bannerAd != null) _buildBannerAd(),
                    if (!canStart) _buildSubscriptionSection() else _buildTestInfoSection(),
                    SizedBox(height: 10),
                    if (_currentQuiz!.description.isNotEmpty) ...[_buildDescriptionCard(), SizedBox(height: 10)],
                    if (_currentQuiz!.instruction.isNotEmpty) ...[_buildInstructionsCard(), SizedBox(height: 10)],
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 55,
      pinned: true,
      backgroundColor: _mockPrimary,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
          decoration: BoxDecoration(gradient: LinearGradient(colors: [_mockPrimary, _mockSecondary])),
        ),
      ),
    );
  }

  Widget _buildAccessBanner() {
    String message;
    String subtitle;
    IconData icon;

    // ── CHANGED: FREE badge logic hataya ──
    // Sirf purchased/plan-included status dikhao
    if (_isPurchased) {
      message = '✅ Access Unlocked!';
      subtitle = 'You are subscribed to this mock test';
      icon = Icons.verified;
    } else {
      message = '🔓 Included in your plan!';
      subtitle = 'Full access available';
      icon = Icons.lock_open_rounded;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_mockPrimary, _mockSecondary]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.35), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          SizedBox(width: 12),
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
                SizedBox(height: 2),
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

  Widget _buildCourseInfo() {
    final materialName = _currentQuiz?.Material_name ?? '';
    if (materialName.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _mockPrimary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.06), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: _mockPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.library_books_outlined, color: _mockPrimary, size: 17),
          ),
          SizedBox(width: 11),
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
                SizedBox(height: 3),
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
            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: _mockPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(
              '📚 MOCK',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _mockPrimary, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.1), blurRadius: 18, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                    // ── CHANGED: FREE badge completely remove kiya ──
                    // Sirf PREMIUM badge dikhao agar paid hai
                    if (!_isFree)
                      _buildTag(
                        icon: Icons.workspace_premium,
                        label: 'PREMIUM',
                        color: _mockGold,
                        bgColor: _mockGold.withOpacity(0.2),
                      ),
                  ],
                ),
                SizedBox(height: 10),
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
          Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentQuiz!.subscription_description.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.folder_open_outlined, size: 12, color: AppColors.greyS600),
                      SizedBox(width: 5),
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
                  SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _mockPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _mockPrimary.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 13, color: _mockAccent),
                        SizedBox(width: 7),
                        Expanded(
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            _currentQuiz!.subscription_description,
                            11,
                            _mockPrimary,
                            FontWeight.w600,
                            10,
                            TextAlign.left,
                            1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                if (_attempted)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFF43A047).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({required IconData icon, required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatBox('⏱️', _currentQuiz?.timeLimit.isEmpty == false ? _currentQuiz!.timeLimit : '—', 'Minutes'),
          SizedBox(width: 10),
          _buildStatBox('🏆', _currentQuiz?.totalMarks.toString() ?? '—', 'Marks'),
        ],
      ),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _mockPrimary.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _mockPrimary)),
            SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9.5, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mockPrimary.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.featured_play_list_outlined, 'Mock Test Features'),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFeatureTile('🗂️', 'Question\nPalette', 'Jump to any question')),
              SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('🔖', 'Mark for\nReview', 'Flag & revisit later')),
              SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('⏸️', 'Pause &\nResume', 'Pick up where left')),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildFeatureTile('📊', 'Detailed\nAnalysis', 'Topic-wise breakdown')),
              SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('✏️', 'Change\nAnswers', 'Edit before submit')),
              SizedBox(width: 8),
              Expanded(child: _buildFeatureTile('📈', 'Track\nProgress', 'Compare attempts')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String emoji, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _mockPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _mockPrimary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _mockPrimary, height: 1.3),
          ),
          SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.5, color: AppColors.greyS600, fontWeight: FontWeight.w400, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerAd() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

  Widget _buildTestInfoSection() {
    final hasStart = _currentQuiz!.startDateTime.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Test Details', isGreen: false),
          SizedBox(height: 14),
          _buildDetailRow(Icons.all_inclusive_rounded, 'Available', 'Anytime — attempt at your own pace'),
          if (hasStart)
            _buildDetailRow(
              Icons.play_circle_outline,
              'Start Date',
              _formatDateTime(_currentQuiz!.startDateTime).split('  •  ').first,
            ),
          // End date intentionally NOT shown
          if (_currentQuiz!.timeLimit.isNotEmpty)
            _buildDetailRow(Icons.timer_outlined, 'Duration', '${_currentQuiz!.timeLimit} Minutes'),
          _buildDetailRow(
            Icons.repeat_rounded,
            'Attempts',
            _attempted ? 'Already attempted once' : 'One attempt allowed',
          ),
          SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _mockAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _mockAccent.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_outlined, size: 14, color: _mockAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Designed to simulate actual exam conditions — same pattern, same time pressure.',
                    style: TextStyle(fontSize: 11, color: _mockPrimary, fontWeight: FontWeight.w500, height: 1.4),
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
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7),
            decoration: BoxDecoration(color: _mockPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: _mockPrimary, size: 15),
          ),
          SizedBox(width: 11),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
          Spacer(),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _mockPrimary)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    final error = _currentQuiz?.accessError ?? '';
    // ── CHANGED: upgrade_required → seedha premium section ──
    // Free user ka alag section hata diya
    return _buildPremiumSection();
  }

  Widget _buildPremiumSection() {
    final error = _currentQuiz?.accessError ?? '';

    String headline;
    String subtitle;
    String badgeLabel;
    Color badgeColor;
    IconData badgeIcon;

    if (error == 'plan_expired') {
      headline = 'Your plan has expired!\nRenew to regain full access.';
      subtitle = 'Your previous plan has ended — renew now to continue';
      badgeLabel = 'Plan Expired';
      badgeColor = Colors.orange.shade300;
      badgeIcon = Icons.warning_amber_rounded;
    } else if (error == 'upgrade_required') {
      headline = 'You\'ve used your\nfree attempt this month.';
      subtitle = 'Subscribe to a plan for unlimited mock tests';
      badgeLabel = 'Subscription Required';
      badgeColor = _mockGold;
      badgeIcon = Icons.workspace_premium;
    } else {
      headline = 'This mock test is not\nin your current plan.';
      subtitle = 'Upgrade your plan for access to all mock tests';
      badgeLabel = 'Upgrade Required';
      badgeColor = _mockGold;
      badgeIcon = Icons.workspace_premium;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.18), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      error == 'plan_expired'
                          ? [Colors.orange.shade800, Colors.orange.shade600]
                          : [_mockPrimary, _mockSecondary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: badgeColor, size: 15),
                        SizedBox(width: 6),
                        Text(
                          badgeLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    headline,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.white,
              padding: EdgeInsets.all(14),
              child: Column(
                children: [
                  if (error == 'plan_expired') ...[
                    // Plan expired — show renew benefits
                    _buildBenefit(
                      Icons.restore_rounded,
                      'Instant Access Restored',
                      'All your mock tests unlock immediately after renewal',
                      Colors.orange.shade700,
                    ),
                    SizedBox(height: 8),
                    _buildBenefit(
                      Icons.history_rounded,
                      'Previous Attempts Preserved',
                      'Your past results and analysis remain intact',
                      _mockPrimary,
                    ),
                    SizedBox(height: 8),
                    _buildBenefit(
                      Icons.assignment_outlined,
                      'Full Mock Test Series',
                      'Resume from where you left off — no data lost',
                      _mockAccent,
                    ),
                    SizedBox(height: 8),
                    _buildBenefit(
                      Icons.leaderboard_outlined,
                      'All India Rank',
                      'Continue competing with students nationwide',
                      _mockPrimary,
                    ),
                  ] else ...[
                    // Upgrade required / course mismatch
                    _buildBenefit(
                      Icons.assignment_outlined,
                      'Full Mock Test Series',
                      'Unlimited practice with real exam patterns',
                      _mockPrimary,
                    ),
                    SizedBox(height: 8),
                    _buildBenefit(
                      Icons.analytics_outlined,
                      'Detailed Performance Analysis',
                      'Identify your topic-wise weak areas',
                      _mockAccent,
                    ),
                    SizedBox(height: 8),
                    _buildBenefit(
                      Icons.compare_arrows_rounded,
                      'Answer Review & Comparison',
                      'View solutions for every incorrect answer',
                      _mockPrimary,
                    ),
                    SizedBox(height: 8),
                    _buildBenefit(
                      Icons.leaderboard_outlined,
                      'All India Rank',
                      'Compare your performance nationwide',
                      _mockAccent,
                    ),
                  ],
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
      padding: EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Color(0xFFF5F6FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _mockPrimary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 11),
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
                SizedBox(height: 2),
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

  Widget _buildDescriptionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.description_outlined, 'Description'),
          SizedBox(height: 10),
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
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.format_list_bulleted_outlined, 'Instructions'),
          SizedBox(height: 12),
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
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(color: _mockPrimary, borderRadius: BorderRadius.circular(5)),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
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
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(Icons.info_outline_rounded, 'Important Information', isGreen: false),
          SizedBox(height: 10),
          _buildInfoRow(Icons.touch_app_rounded, 'One attempt only — make every question count'),
          _buildInfoRow(Icons.swap_horiz_rounded, 'Navigate freely — jump to any question anytime'),
          _buildInfoRow(Icons.bookmark_border_rounded, 'Mark for review — revisit flagged questions before submitting'),
          _buildInfoRow(Icons.timer_outlined, 'Timer runs continuously — does not stop even on pause'),
          _buildInfoRow(Icons.wifi_rounded, 'Stable internet connection required throughout the test'),
          _buildInfoRow(
            Icons.bar_chart_rounded,
            'Detailed performance analysis available immediately after submission',
          ),
          _buildInfoRow(Icons.block_rounded, 'Once submitted, the attempt cannot be retaken'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _mockPrimary),
          SizedBox(width: 9),
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
    final Color headColor = isGreen ? _mockPrimary : _mockSecondary;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(color: headColor.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: headColor, size: 15),
        ),
        SizedBox(width: 9),
        AppRichText.setTextPoppinsStyle(context, label, 13, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0),
      ],
    );
  }

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
            content: Text('You have already attempted this test'),
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
      onTap = _handleStartMockTest;
    } else {
      final error = _currentQuiz?.accessError ?? '';
      if (error == 'attempt_pending') {
        btnLabel = 'Resume Attempt';
        btnIcon = Icons.play_circle_outline;
        btnColors = [_mockPrimary, _mockSecondary];
        onTap = _navigateToMockTest;
      } else if (error == 'plan_expired') {
        btnLabel = 'Renew Plan Now';
        btnIcon = Icons.refresh_rounded;
        btnColors = [Colors.orange.shade700, Colors.orange.shade900];
        onTap = _handleSubscribe;
      } else if (error == 'upgrade_required') {
        // ── CHANGED: seedha subscribe page ──
        btnLabel = 'Subscribe Now';
        btnIcon = Icons.workspace_premium_rounded;
        btnColors = [_mockPrimary, _mockSecondary];
        onTap = _handleSubscribe;
      } else {
        btnLabel = 'Upgrade to Premium';
        btnIcon = Icons.workspace_premium_rounded;
        btnColors = [_mockGold, _mockPrimary];
        onTap = _handleSubscribe;
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: _mockPrimary.withOpacity(0.1), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_attempted && canStart)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: _mockPrimary.withOpacity(0.5)),
                    SizedBox(width: 5),
                    Text(
                      'Timer starts as soon as the test begins',
                      style: TextStyle(fontSize: 10, color: _mockPrimary.withOpacity(0.6), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: btnColors),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: btnColors.first.withOpacity(0.35), blurRadius: 14, offset: Offset(0, 5))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(btnIcon, color: Colors.white, size: 21),
                        SizedBox(width: 9),
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
