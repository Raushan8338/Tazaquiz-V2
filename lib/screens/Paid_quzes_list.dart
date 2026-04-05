import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/ads/banner_ads_helper.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/models/study_category_item.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/mock_test_detail_page.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

// ─── PAGE TYPE CONSTANTS ──────────────────────────────────────────────────────
// '0' → Live Tests       (with subject tabs)
// '4' → Mock Tests       (with subject tabs)
// '5' → Full Mock Test   (NO subject tabs — real exam style)
// '6' → Previous Year Papers (NO subject tabs)

class Paid_QuizListScreen extends StatefulWidget {
  final String pageId;
  final String PageType;

  Paid_QuizListScreen(this.pageId, this.PageType);

  @override
  _Paid_QuizListScreenState createState() => _Paid_QuizListScreenState();
}

class _Paid_QuizListScreenState extends State<Paid_QuizListScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';
  String? _errorMessage;

  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  List<CategoryItem> _categories = [];
  int _selectedCategoryId = 0;

  bool _isLoading = true;
  bool _isFetchingQuizzes = false;
  List<QuizItem> _quizzes = [];
  UserModel? _user;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Page type helpers ──────────────────────────────────────────────────────
  bool get isLiveTest => widget.PageType == '0';
  bool get isMockTest => widget.PageType == '4';
  bool get isFullMockTest => widget.PageType == '5';
  bool get isPYP => widget.PageType == '6';

  /// Pages that show subject/category tabs
  bool get showCategoryTabs => isLiveTest || isMockTest;

  String get pageTitle {
    if (isLiveTest) return 'Live Tests';
    if (isMockTest) return 'Mock Tests';
    if (isFullMockTest) return 'Full Mock Test';
    if (isPYP) return 'Previous Year Papers';
    return 'Tests';
  }

  String get pageSubtitle {
    if (isLiveTest) return 'Join live sessions in real-time';
    if (isMockTest) return 'Practice with topic-wise mocks';
    if (isFullMockTest) return 'Full-length exam simulation';
    if (isPYP) return 'Solve actual past exam questions';
    return '';
  }

  IconData get pageIcon {
    if (isLiveTest) return Icons.bolt_rounded;
    if (isMockTest) return Icons.assignment_rounded;
    if (isFullMockTest) return Icons.quiz_rounded;
    if (isPYP) return Icons.history_edu_rounded;
    return Icons.quiz_rounded;
  }

  // ── Gradients & accent ─────────────────────────────────────────────────────
  Color get _accent {
    if (isLiveTest) return AppColors.tealGreen;
    if (isMockTest) return const Color(0xFF3949AB);
    if (isFullMockTest) return const Color(0xFFE65100);
    if (isPYP) return const Color(0xFF00897B);
    return AppColors.tealGreen;
  }

  Color get _accentDark {
    if (isLiveTest) return const Color(0xFF0D4B3B);
    if (isMockTest) return const Color(0xFF1A237E);
    if (isFullMockTest) return const Color(0xFF7F2F00);
    if (isPYP) return const Color(0xFF00504A);
    return AppColors.darkNavy;
  }

  final List<List<Color>> _cardGradients = const [
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    bannerService.loadAd(() => mounted ? setState(() => isBannerLoaded = true) : null);
    _getUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    bannerService.dispose();
    super.dispose();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────
  Future<void> _getUserData() async {
    try {
      _user = await SessionManager.getUser();
      if (_user == null) {
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      setState(() {});
      if (showCategoryTabs) {
        await _fetchLevels();
      } else {
        // Full Mock Test & PYP — skip category fetch, go straight to quizzes
        setState(() => _isLoading = false);
        await _fetchQuizzes(0, 1);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLevels() async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'categoryId': widget.pageId};

      Response response = await authRepository.fetchStudySubjectCategory(data);

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _categories = [
            CategoryItem(category_id: 0, name: 'All'),
            ...list.map((e) => CategoryItem.fromJson(e)).toList(),
          ];
          _isLoading = false;
          _errorMessage = null;
        });
        await _fetchQuizzes(0, 1);
      } else {
        setState(() {
          _errorMessage = 'Failed to load categories. Pull down to refresh.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = _dioErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchQuizzes(int categoryId, int educationLevelId) async {
    setState(() {
      _isFetchingQuizzes = true;
      _errorMessage = null;
    });
    try {
      Authrepository auth = Authrepository(Api_Client.dio);

      final data = {
        'subscription_id': widget.pageId,
        'user_id': _user!.id.toString(),
        'category_id': categoryId.toString(),
        'education_level_id': educationLevelId == 0 ? categoryId.toString() : 0,
        'Pagetype': widget.PageType,
        if (isLiveTest && (_selectedFilter == 'live' || _selectedFilter == 'upcoming' || _selectedFilter == 'missed'))
          'type': _selectedFilter,
      };

      final response = await auth.get_paid_quizes_api(data);

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _quizzes = list.map((e) => QuizItem.fromJson(e)).toList();
          _isFetchingQuizzes = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() {
          _errorMessage = 'Failed to load tests. Pull down to refresh.';
          _isFetchingQuizzes = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = _dioErrorMessage(e);
        _isFetchingQuizzes = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error occurred. Please try again.';
        _isFetchingQuizzes = false;
      });
    }
  }

  String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'Network error. Please try again.';
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<QuizItem> get _filtered {
    if (isMockTest || isFullMockTest || isPYP) {
      if (_selectedFilter == 'attempted') return _quizzes.where((q) => q.is_attempted).toList();
      if (_selectedFilter == 'unattempted') return _quizzes.where((q) => !q.is_attempted).toList();
      return _quizzes;
    }
    // Live Tests
    if (_selectedFilter == 'live') return _quizzes.where((q) => q.isLive).toList();
    if (_selectedFilter == 'upcoming') return _quizzes.where((q) => q.quizStatus == 'upcoming' && !q.isLive).toList();
    if (_selectedFilter == 'ended') return _quizzes.where((q) => q.quizStatus == 'ended').toList();
    if (_selectedFilter == 'missed') return _quizzes.where((q) => q.quizStatus == 'missed').toList();

    final live = _quizzes.where((q) => q.isLive).toList();
    final upcoming = _quizzes.where((q) => q.quizStatus == 'upcoming' && !q.isLive).toList();
    final missed = _quizzes.where((q) => q.quizStatus == 'missed').toList();
    return [...live, ...upcoming, ...missed];
  }

  void _goToDetail(QuizItem quiz) {
    if (isMockTest || isFullMockTest || isPYP) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MockTestDetailPage(quizId: quiz.quizId)));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizDetailPage(quizId: quiz.quizId, is_subscribed: true)),
      );
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? _buildLoadingState()
              : RefreshIndicator(
                onRefresh: _getUserData,
                color: AppColors.tealGreen,
                child: Column(
                  children: [
                    if (showCategoryTabs) _buildCategoryTabs(),
                    if (_errorMessage != null && !_isFetchingQuizzes) _buildErrorBanner(),
                    Expanded(
                      child:
                          _isFetchingQuizzes
                              ? _buildLoadingState()
                              : _filtered.isEmpty && _errorMessage == null
                              ? _buildEmptyState()
                              : _errorMessage != null && _quizzes.isEmpty
                              ? _buildFullErrorState()
                              : _buildContent(),
                    ),
                  ],
                ),
              ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pageTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          TranslatedText(
            '${_filtered.length} ${isMockTest || isFullMockTest || isPYP ? 'tests' : 'tests'} available',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
          ),
          onPressed:
              () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _buildFilterSheet(),
              ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
          ),
        ),
      ),
    );
  }

  // ── ERROR BANNER (inline, non-blocking) ────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TranslatedText(
              _errorMessage!,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: () => _fetchQuizzes(_selectedCategoryId, 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
              child: TranslatedText(
                'Retry',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FULL ERROR STATE ───────────────────────────────────────────────────────
  Widget _buildFullErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            const TranslatedText(
              'Unable to Load',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 8),
            TranslatedText(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.greyS600),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _getUserData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    TranslatedText(
                      'Try Again',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADING STATE ──────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.08), shape: BoxShape.circle),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          TranslatedText(
            'Loading ${pageTitle.toLowerCase()}...',
            style: TextStyle(fontSize: 13, color: AppColors.greyS600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── CATEGORY TABS ──────────────────────────────────────────────────────────
  Widget _buildCategoryTabs() {
    if (_isLoading) return const SizedBox(height: 52);
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final bool sel = _selectedCategoryId == cat.category_id;
          return GestureDetector(
            onTap: () async {
              setState(() => _selectedCategoryId = cat.category_id);
              await _fetchQuizzes(cat.category_id, 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: sel ? LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]) : null,
                color: sel ? null : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(20),
                border: sel ? null : Border.all(color: AppColors.greyS600.withOpacity(0.2)),
              ),
              child: TranslatedText(
                cat.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? Colors.white : AppColors.greyS700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CONTENT LIST ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    const int adAfterIndex = 4;
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCard(_filtered[index], _cardGradients[index % _cardGradients.length]),
                childCount: _filtered.length.clamp(0, adAfterIndex + 1),
              ),
            ),
          ),
          if (isBannerLoaded && bannerService.bannerAd != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: bannerService.bannerAd!.size.height.toDouble(),
                    width: bannerService.bannerAd!.size.width.toDouble(),
                    child: AdWidget(ad: bannerService.bannerAd!),
                  ),
                ),
              ),
            ),
          if (_filtered.length > adAfterIndex + 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final i = adAfterIndex + 1 + index;
                  return _buildCard(_filtered[i], _cardGradients[i % _cardGradients.length]);
                }, childCount: _filtered.length - adAfterIndex - 1),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── CARD ───────────────────────────────────────────────────────────────────
  Widget _buildCard(QuizItem quiz, List<Color> colors) {
    final bool isAttempted = quiz.is_attempted;
    final bool isLive = isLiveTest && quiz.quizStatus == 'live';
    final bool isUpcoming = isLiveTest && quiz.quizStatus == 'upcoming';
    final bool isMissed = isLiveTest && quiz.quizStatus == 'missed';
    final bool hasBanner = quiz.banner != null && quiz.banner!.isNotEmpty;

    return GestureDetector(
      onTap: () => _goToDetail(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            // ── Left panel ──
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
              child: SizedBox(
                width: 100,
                height: 130,
                child:
                    hasBanner
                        ? _buildBannerPanel(quiz, colors, isLive, isUpcoming, isMissed, isAttempted)
                        : _buildGradientPanel(quiz, colors, isLive, isUpcoming, isMissed, isAttempted),
              ),
            ),
            // ── Right content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TranslatedText(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (quiz.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      TranslatedText(
                        quiz.description,
                        style: TextStyle(fontSize: 11, color: AppColors.greyS600, height: 1.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Chips
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        if (quiz.difficultyLevel.isNotEmpty)
                          _chip(Icons.signal_cellular_alt_rounded, quiz.difficultyLevel, AppColors.tealGreen),
                        if (quiz.timeLimit.isNotEmpty && quiz.timeLimit != '0')
                          _chip(Icons.timer_outlined, '${quiz.timeLimit} min', AppColors.greyS600),
                        if (quiz.totalQuestions > 0)
                          _chip(Icons.help_outline_rounded, '${quiz.totalQuestions} Qs', AppColors.greyS600),

                        // Attempt status for mock/full mock/pyp
                        // if (!isLiveTest) ...[
                        //   if (isAttempted)
                        //     _chip(Icons.check_circle_outline_rounded, 'Attempted', const Color(0xFF00897B))
                        //   else
                        //     _chip(Icons.radio_button_unchecked_rounded, 'Not Attempted', const Color(0xFF3949AB)),
                        // ],

                        // Live test specific
                        if (isLiveTest) ...[
                          if (quiz.startsInText.isNotEmpty && !isLive)
                            _chip(Icons.schedule_rounded, quiz.startsInText, Colors.orange.shade700),
                          if (isMissed) _chip(Icons.assignment_late_outlined, 'Assessment', const Color(0xFF6366F1)),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    // CTA button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              quiz.isAccessible
                                  ? [AppColors.darkNavy, AppColors.tealGreen]
                                  : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow:
                            quiz.isAccessible
                                ? [
                                  BoxShadow(
                                    color: AppColors.tealGreen.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_btnIcon(quiz, isLive, isAttempted), color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          TranslatedText(
                            _btnText(quiz, isLive, isMissed, isAttempted),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BANNER PANEL ───────────────────────────────────────────────────────────
  Widget _buildBannerPanel(
    QuizItem quiz,
    List<Color> colors,
    bool isLive,
    bool isUpcoming,
    bool isMissed,
    bool isAttempted,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          quiz.banner!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildGradientPanel(quiz, colors, isLive, isUpcoming, isMissed, isAttempted),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Center(child: _statusBadge(isLive, isUpcoming, isMissed, isAttempted)),
        ),
      ],
    );
  }

  // ── GRADIENT PANEL ─────────────────────────────────────────────────────────
  Widget _buildGradientPanel(
    QuizItem quiz,
    List<Color> colors,
    bool isLive,
    bool isUpcoming,
    bool isMissed,
    bool isAttempted,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
          Positioned(
            right: -18,
            bottom: -18,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                    child: TranslatedText(
                      isLiveTest
                          ? '⚡'
                          : isMockTest
                          ? '📝'
                          : isFullMockTest
                          ? '🎯'
                          : '📜',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _statusBadge(isLive, isUpcoming, isMissed, isAttempted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STATUS BADGE ───────────────────────────────────────────────────────────
  Widget _statusBadge(bool isLive, bool isUpcoming, bool isMissed, bool isAttempted) {
    // Non-live types
    if (!isLiveTest) {
      final Color color = isAttempted ? const Color(0xFF00897B) : const Color(0xFF3949AB);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: TranslatedText(
          isAttempted ? 'DONE' : 'ATTEMPT',
          style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
        ),
      );
    }

    // Live test
    final Color color =
        isLive
            ? Colors.red
            : isUpcoming
            ? const Color(0xFFF59E0B)
            : isMissed
            ? const Color(0xFF6366F1)
            : AppColors.greyS600;

    final String label =
        isLive
            ? 'LIVE'
            : isUpcoming
            ? 'UPCOMING'
            : isMissed
            ? 'ASSESS'
            : 'ENDED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          TranslatedText(
            label,
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  // ── FILTER SHEET ───────────────────────────────────────────────────────────
  Widget _buildFilterSheet() {
    String tempFilter = _selectedFilter;

    final mockFilters = [
      {
        'key': 'all',
        'title': 'All Tests',
        'subtitle': 'Show every test in this series',
        'icon': Icons.view_list_rounded,
        'color': AppColors.darkNavy,
      },
      {
        'key': 'unattempted',
        'title': 'Not Attempted',
        'subtitle': 'Tests you haven\'t started yet',
        'icon': Icons.radio_button_unchecked_rounded,
        'color': const Color(0xFF3949AB),
      },
      {
        'key': 'attempted',
        'title': 'Attempted',
        'subtitle': 'Tests you have already completed',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF00897B),
      },
    ];

    final liveFilters = [
      {
        'key': 'all',
        'title': 'All Tests',
        'subtitle': 'Show live, upcoming and assessments',
        'icon': Icons.view_list_rounded,
        'color': AppColors.darkNavy,
      },
      {
        'key': 'live',
        'title': 'Live Now',
        'subtitle': 'Tests currently running',
        'icon': Icons.radio_button_checked_rounded,
        'color': Colors.red,
      },
      {
        'key': 'upcoming',
        'title': 'Upcoming',
        'subtitle': 'Tests scheduled ahead',
        'icon': Icons.schedule_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'key': 'missed',
        'title': 'Assessment',
        'subtitle': 'Missed tests — attempt anytime',
        'icon': Icons.assignment_late_outlined,
        'color': const Color(0xFF6366F1),
      },
      {
        'key': 'ended',
        'title': 'Ended',
        'subtitle': 'Tests that have concluded',
        'icon': Icons.history_rounded,
        'color': AppColors.greyS600,
      },
    ];

    final filters = isLiveTest ? liveFilters : mockFilters;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        TranslatedText(
                          'Filter Tests',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: AppColors.greyS600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filter options
                    ...filters.map((f) {
                      final bool sel = tempFilter == f['key'];
                      final Color c = f['color'] as Color;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempFilter = f['key'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: sel ? c.withOpacity(0.07) : const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: sel ? c : Colors.transparent, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: sel ? c.withOpacity(0.15) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(f['icon'] as IconData, color: sel ? c : AppColors.greyS600, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TranslatedText(
                                      f['title'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                        color: sel ? c : AppColors.darkNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    TranslatedText(
                                      f['subtitle'] as String,
                                      style: TextStyle(fontSize: 11, color: AppColors.greyS500),
                                    ),
                                  ],
                                ),
                              ),
                              if (sel) Icon(Icons.check_circle_rounded, color: c, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 8),

                    // Apply button
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = tempFilter);
                        Navigator.pop(context);
                        _fetchQuizzes(_selectedCategoryId, 1);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tealGreen.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: TranslatedText(
                            'Apply Filter',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  IconData _btnIcon(QuizItem quiz, bool isLive, bool isAttempted) {
    if (!quiz.isAccessible) return Icons.lock_outline_rounded;
    if (!isLiveTest) {
      return isAttempted ? Icons.bar_chart_rounded : Icons.play_arrow_rounded;
    }
    if (isLive) return Icons.play_arrow_rounded;
    return Icons.arrow_forward_rounded;
  }

  String _btnText(QuizItem quiz, bool isLive, bool isMissed, bool isAttempted) {
    if (!quiz.isAccessible) return 'Subscribe to Unlock';
    if (!isLiveTest) {
      return isAttempted ? 'View Result' : 'Start Test';
    }
    if (isLive) return 'Join Now';
    if (isMissed) return 'Attempt Now';
    return 'View Details';
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          TranslatedText(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final Map<String, Map<String, dynamic>> emptyData = {
      '0': {'icon': '⚡', 'title': 'No Live Tests Found', 'subtitle': 'Check back later or try a different category.'},
      '4': {'icon': '📝', 'title': 'No Mock Tests Found', 'subtitle': 'Try selecting a different subject or filter.'},
      '5': {
        'icon': '🎯',
        'title': 'No Full Mock Tests Available',
        'subtitle': 'Full mock tests will appear here when published.',
      },
      '6': {'icon': '📜', 'title': 'No Previous Year Papers', 'subtitle': 'PYP papers will appear here when added.'},
    };

    final data = emptyData[widget.PageType] ?? {'icon': '📭', 'title': 'Nothing Here', 'subtitle': 'Try again later.'};

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.07), shape: BoxShape.circle),
              child: TranslatedText(data['icon'] as String, style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            TranslatedText(
              data['title'] as String,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 8),
            TranslatedText(
              data['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.greyS600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PAINTERS ─────────────────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..strokeWidth = 1;
    const spacing = 14.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
