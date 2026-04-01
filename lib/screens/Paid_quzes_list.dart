import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

class Paid_QuizListScreen extends StatefulWidget {
  final String pageId;
  final String PageType;

  Paid_QuizListScreen(this.pageId, this.PageType);

  @override
  _Paid_QuizListScreenState createState() => _Paid_QuizListScreenState();
}

class _Paid_QuizListScreenState extends State<Paid_QuizListScreen> {
  // For live quizzes, filter can be: all / live / upcoming / missed / ended
  // For mock tests, filter can be: all / attempted / unattempted
  String _selectedFilter = 'all';

  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  List<CategoryItem> _categories = [];
  int _selectedCategoryId = 0;

  bool _isLoading = true;
  bool _isFetchingQuizzes = false;
  List<QuizItem> _quizzes = [];
  UserModel? _user;

  bool get isMockTest => widget.PageType == '4';

  final List<List<Color>> _liveGradients = const [
    [Color(0xFF0D4B3B), Color(0xFF0D6E6E)],
    [Color(0xFF0B3D5E), Color(0xFF0D6E6E)],
    [Color(0xFF1A4D6D), Color(0xFF0D6E6E)],
    [Color(0xFF0C3756), Color(0xFF0D6E6E)],
    [Color(0xFF093D4A), Color(0xFF0D6E6E)],
  ];

  final List<List<Color>> _mockGradients = const [
    [Color(0xFF0D6E6E), Color(0xFF0D6E6E)],
    [Color(0xFF0D6E6E), Color(0xFF0D6E6E)],
    [Color(0xFF0D6E6E), Color(0xFF0D6E6E)],
    [Color(0xFF0D6E6E), Color(0xFF0D6E6E)],
    [Color(0xFF0D6E6E), Color(0xFF0D6E6E)],
  ];

  List<List<Color>> get _gradients => isMockTest ? _mockGradients : _liveGradients;
  Color get _accent => isMockTest ? const Color(0xFF0D6E6E) : AppColors.tealGreen;

  @override
  void initState() {
    super.initState();
    bannerService.loadAd(() => mounted ? setState(() => isBannerLoaded = true) : null);
    _getUserData();
  }

  @override
  void dispose() {
    bannerService.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    await _fetchLevels();
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
        });
        await _fetchQuizzes(0, 1);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchQuizzes(int categoryId, int educationLevelId) async {
    setState(() => _isFetchingQuizzes = true);
    try {
      Authrepository auth = Authrepository(Api_Client.dio);

      final data = {
        'subscription_id': widget.pageId,
        'user_id': _user!.id.toString(),
        'category_id': categoryId.toString(),
        'education_level_id': educationLevelId == 0 ? categoryId.toString() : 0,
        'Pagetype': widget.PageType,
        // For live quizzes, pass live/upcoming/missed to API
        if (!isMockTest && (_selectedFilter == 'live' || _selectedFilter == 'upcoming' || _selectedFilter == 'missed'))
          'type': _selectedFilter,
      };
      print('Fetching quizzes with data: $data');

      final response = await auth.get_paid_quizes_api(data);
      print('Quiz API response: ${response.data}');
      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _quizzes = list.map((e) => QuizItem.fromJson(e)).toList();
          _isFetchingQuizzes = false;
        });
      }
    } catch (e) {
      setState(() => _isFetchingQuizzes = false);
    }
  }

  List<QuizItem> get _filtered {
    // ── MOCK TEST filters ──────────────────────────────────────────────────
    if (isMockTest) {
      if (_selectedFilter == 'attempted') {
        return _quizzes.where((q) => q.is_attempted).toList();
      }
      if (_selectedFilter == 'unattempted') {
        return _quizzes.where((q) => !q.is_attempted).toList();
      }
      // 'all'
      return _quizzes;
    }

    // ── LIVE QUIZ filters ──────────────────────────────────────────────────
    if (_selectedFilter == 'live') {
      return _quizzes.where((q) => q.isLive).toList();
    }
    if (_selectedFilter == 'upcoming') {
      return _quizzes.where((q) => q.quizStatus == 'upcoming' && !q.isLive).toList();
    }
    if (_selectedFilter == 'ended') {
      return _quizzes.where((q) => q.quizStatus == 'ended').toList();
    }
    if (_selectedFilter == 'missed') {
      return _quizzes.where((q) => q.quizStatus == 'missed').toList();
    }

    // 'all' — Live + Upcoming + Missed
    final live = _quizzes.where((q) => q.isLive).toList();
    final upcoming = _quizzes.where((q) => q.quizStatus == 'upcoming' && !q.isLive).toList();
    final missed = _quizzes.where((q) => q.quizStatus == 'missed').toList();
    return [...live, ...upcoming, ...missed];
  }

  void _goToDetail(QuizItem quiz) {
    if (isMockTest) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MockTestDetailPage(quizId: quiz.quizId)));
      return;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizDetailPage(quizId: quiz.quizId, is_subscribed: true)),
      );
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(int.parse(widget.PageType)),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child:
                _isFetchingQuizzes
                    ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_accent)))
                    : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(int pageType_data) {
    // Title differs for mock vs live
    final String title = isMockTest ? 'Mock Tests' : 'Live Quizzes';

    return AppBar(
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            isMockTest ? '${_filtered.length} tests available' : '${_filtered.length} quizzes available',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isMockTest
                    ? [AppColors.darkNavy, const Color(0xFF0D6E6E)]
                    : [AppColors.darkNavy, const Color(0xFF0D6E6E)],
          ),
        ),
      ),
    );
  }

  // ─── FILTER BOTTOM SHEET ──────────────────────────────────────────────────

  Widget _buildFilterSheet() {
    String tempFilter = _selectedFilter;

    // ── Mock test filter options ──────────────────────────────────────────
    final mockFilters = [
      {
        'key': 'all',
        'title': 'All Tests',
        'subtitle': 'Show every mock test in this series',
        'icon': Icons.view_list,
        'color': AppColors.darkNavy,
      },
      {
        'key': 'unattempted',
        'title': 'Not Attempted',
        'subtitle': 'Tests you haven\'t started yet',
        'icon': Icons.radio_button_unchecked,
        'color': const Color(0xFF0D6E6E),
      },
      {
        'key': 'attempted',
        'title': 'Attempted',
        'subtitle': 'Tests you have already completed',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF00897B),
      },
    ];

    // ── Live quiz filter options ───────────────────────────────────────────
    final liveFilters = [
      {
        'key': 'all',
        'title': 'All Quizzes',
        'subtitle': 'Show live, upcoming and assessments',
        'icon': Icons.view_list,
        'color': const Color(0xFF0D6E6E),
      },
      {
        'key': 'live',
        'title': 'Live Now',
        'subtitle': 'Quizzes currently live',
        'icon': Icons.radio_button_checked,
        'color': Colors.red,
      },
      {
        'key': 'upcoming',
        'title': 'Upcoming',
        'subtitle': 'Quizzes scheduled ahead',
        'icon': Icons.schedule,
        'color': const Color(0xFFF59E0B),
      },
      {
        'key': 'missed',
        'title': 'Assessment',
        'subtitle': 'Quizzes you missed — attempt now',
        'icon': Icons.assignment_late_outlined,
        'color': const Color(0xFF6366F1),
      },
      {
        'key': 'ended',
        'title': 'Ended',
        'subtitle': 'Quizzes that have concluded',
        'icon': Icons.history,
        'color': AppColors.greyS600,
      },
    ];

    final filters = isMockTest ? mockFilters : liveFilters;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_accent, AppColors.darkNavy]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isMockTest ? 'Filter Tests' : 'Filter Quizzes',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D6E6E)),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppColors.greyS600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...filters.map((f) {
                      final bool sel = tempFilter == f['key'];
                      final Color c = f['color'] as Color;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempFilter = f['key'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: sel ? c.withOpacity(0.08) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? c : Colors.transparent, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: sel ? c.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(f['icon'] as IconData, color: sel ? c : AppColors.greyS600, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                        color: sel ? c : AppColors.darkNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      f['subtitle'] as String,
                                      style: TextStyle(fontSize: 11, color: AppColors.greyS600),
                                    ),
                                  ],
                                ),
                              ),
                              if (sel) Icon(Icons.check_circle_rounded, color: c, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
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
                          gradient: LinearGradient(colors: [_accent, AppColors.darkNavy]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Apply Filter',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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

  // ─── CATEGORY TABS ────────────────────────────────────────────────────────

  Widget _buildCategoryTabs() {
    if (_isLoading) return const SizedBox(height: 52);
    return Container(
      height: 52,
      color: AppColors.white,
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
                gradient: sel ? LinearGradient(colors: [_accent, AppColors.darkNavy]) : null,
                color: sel ? null : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(20),
                border: sel ? null : Border.all(color: AppColors.greyS600.withOpacity(0.2)),
              ),
              child: Text(
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

  // ─── CONTENT ──────────────────────────────────────────────────────────────

  Widget _buildContent() {
    const int adAfterIndex = 4;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCard(_filtered[index], _gradients[index % _gradients.length]),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final i = adAfterIndex + 1 + index;
                return _buildCard(_filtered[i], _gradients[i % _gradients.length]);
              }, childCount: _filtered.length - adAfterIndex - 1),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // ─── CARD ─────────────────────────────────────────────────────────────────

  Widget _buildCard(QuizItem quiz, List<Color> colors) {
    // For mock tests, status flags are irrelevant — use attempted flag
    final bool isAttempted = quiz.is_attempted;

    // For live quizzes only
    final bool isLive = !isMockTest && quiz.quizStatus == 'live';
    final bool isUpcoming = !isMockTest && quiz.quizStatus == 'upcoming';
    final bool isMissed = !isMockTest && quiz.quizStatus == 'missed';

    final bool hasBanner = quiz.banner != null && quiz.banner!.isNotEmpty;

    return GestureDetector(
      onTap: () => _goToDetail(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: SizedBox(
                width: 95,
                height: 120,
                child:
                    hasBanner
                        ? _buildBannerPanel(quiz, colors, isLive, isUpcoming, isMissed, isAttempted)
                        : _buildGradientPanel(quiz, colors, isLive, isUpcoming, isMissed, isAttempted),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quiz.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        quiz.description,
                        style: TextStyle(fontSize: 11, color: AppColors.greyS600, height: 1.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (quiz.difficultyLevel.isNotEmpty)
                          _chip(Icons.signal_cellular_alt, quiz.difficultyLevel, AppColors.tealGreen),
                        if (quiz.timeLimit.isNotEmpty && quiz.timeLimit != '0')
                          _chip(Icons.timer_outlined, '${quiz.timeLimit} min', AppColors.greyS600),

                        // ── Mock test chips ──────────────────────────────
                        if (isMockTest) ...[
                          if (isAttempted)
                            _chip(Icons.check_circle_outline_rounded, 'Attempted', const Color(0xFF00897B))
                          else
                            _chip(Icons.assignment_outlined, 'Not Attempted', const Color(0xFF3949AB)),
                          if (quiz.totalQuestions > 0)
                            _chip(Icons.help_outline_rounded, '${quiz.totalQuestions} Qs', AppColors.greyS600),
                        ],

                        // ── Live quiz chips ──────────────────────────────
                        if (!isMockTest) ...[
                          if (quiz.startsInText.isNotEmpty && !isLive)
                            _chip(Icons.schedule, quiz.startsInText, Colors.orange),
                          if (isMissed) _chip(Icons.assignment_late_outlined, 'Assessment', const Color(0xFF6366F1)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_btnIcon(quiz, isLive, isAttempted), color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
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

  // ─── BANNER PANEL ─────────────────────────────────────────────────────────

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
              colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
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

  // ─── GRADIENT PANEL ───────────────────────────────────────────────────────

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
            right: -15,
            bottom: -15,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                  ),
                  child: Center(child: Text(isMockTest ? '📝' : '⚡', style: const TextStyle(fontSize: 22))),
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

  // ─── STATUS BADGE ─────────────────────────────────────────────────────────

  Widget _statusBadge(bool isLive, bool isUpcoming, bool isMissed, bool isAttempted) {
    // ── Mock test badge — no live/upcoming concept ─────────────────────────
    if (isMockTest) {
      final Color color =
          isAttempted
              ? const Color(0xFF00897B) // teal — completed
              : const Color(0xFF3949AB); // indigo — available

      final String label = isAttempted ? 'DONE' : 'ATTEMPT';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isAttempted ? Icons.check_circle_outline : Icons.play_arrow_rounded, size: 7, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
            ),
          ],
        ),
      );
    }

    // ── Live quiz badge ────────────────────────────────────────────────────
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
            ? 'ASSESSMENT'
            : 'ENDED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
          if (isMissed)
            const Padding(
              padding: EdgeInsets.only(right: 3),
              child: Icon(Icons.assignment_late_outlined, size: 7, color: Colors.white),
            ),
          Text(
            label,
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  IconData _btnIcon(QuizItem quiz, bool isLive, bool isAttempted) {
    if (!quiz.isAccessible) return Icons.lock_outline;
    // Mock test
    if (isMockTest) {
      return isAttempted ? Icons.bar_chart_rounded : Icons.play_arrow_rounded;
    }
    // Live quiz
    if (isLive) return Icons.play_arrow_rounded;
    return Icons.arrow_forward_rounded;
  }

  String _btnText(QuizItem quiz, bool isLive, bool isMissed, bool isAttempted) {
    if (!quiz.isAccessible) return 'Subscribe to Unlock';

    // Mock test
    if (isMockTest) {
      return isAttempted ? 'View Result' : 'Start Test';
    }

    // Live quiz
    if (isLive) return 'Join Now';
    if (isMissed) return 'Attempt Now';
    return 'View Details';
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMockTest ? Icons.assignment_outlined : Icons.quiz_outlined,
            size: 64,
            color: AppColors.greyS600.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isMockTest ? 'No tests found' : 'No quizzes found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.greyS600),
          ),
          const SizedBox(height: 6),
          Text('Try a different category', style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
        ],
      ),
    );
  }
}

// ─── DOT PATTERN ──────────────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.06)
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
