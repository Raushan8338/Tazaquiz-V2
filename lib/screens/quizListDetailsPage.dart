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
import 'package:tazaquiznew/screens/mockTestScreen.dart';
import 'package:tazaquiznew/screens/mock_test_detail_page.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizListScreen extends StatefulWidget {
  String pageId;
  String PageType;
  QuizListScreen(this.pageId, this.PageType);

  @override
  _QuizListScreenState createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  // all | live | upcoming | missed
  String _selectedFilter = 'all';

  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  List<CategoryItem> _categories = [];
  int _selectedCategoryId = 0;

  bool _isLoading = true;
  bool _isFetchingQuizzes = false;
  List<QuizItem> _quizzes = [];
  UserModel? _user;

  // ── Pagination ───────────────────────────────────────────────────────────
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get isMockTest => widget.PageType == '4';
  Color get _accent => isMockTest ? const Color(0xFF3949AB) : AppColors.tealGreen;

  final List<List<Color>> _liveGradients = const [
    [Color(0xFF0D4B3B), Color(0xFF1A8070)],
    [Color(0xFF0B3D5E), Color(0xFF1A6D8A)],
    [Color(0xFF1A4D6D), Color(0xFF0D7A6B)],
    [Color(0xFF0C3756), Color(0xFF28A194)],
    [Color(0xFF093D4A), Color(0xFF1A7A6D)],
  ];

  final List<List<Color>> _mockGradients = const [
    [Color(0xFF1a237e), Color(0xFF283593)],
    [Color(0xFF0D1B6D), Color(0xFF1a237e)],
    [Color(0xFF283593), Color(0xFF3949AB)],
    [Color(0xFF1a237e), Color(0xFF0D1B6D)],
    [Color(0xFF3949AB), Color(0xFF283593)],
  ];

  List<List<Color>> get _gradients => isMockTest ? _mockGradients : _liveGradients;

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
      Authrepository auth = Authrepository(Api_Client.dio);
      Response response = await auth.fetchStudyLevels();
      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _categories = [
            CategoryItem(category_id: 0, name: 'All'),
            ...list.map((e) => CategoryItem.fromJson(e)).toList(),
          ];
          _isLoading = false;
        });
        await _fetchQuizzes(0, page: 1);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Fetch with pagination ────────────────────────────────────────────────
  Future<void> _fetchQuizzes(int categoryId, {int page = 1}) async {
    if (page == 1) setState(() => _isFetchingQuizzes = true);

    try {
      Authrepository auth = Authrepository(Api_Client.dio);

      // Pass type filter to API only for live/upcoming/missed
      final Map<String, dynamic> payload = {
        'Pagetype': widget.PageType,
        'category_id': categoryId.toString(),
        'user_id': _user!.id.toString(),
        'page': page.toString(),
        'limit': '5',
      };
      if (_selectedFilter == 'live' || _selectedFilter == 'upcoming' || _selectedFilter == 'missed') {
        payload['type'] = _selectedFilter;
      }

      final response = await auth.fetch_Quiz_List(payload);

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        final bool hasMore = response.data['hasMore'] ?? false;

        debugPrint("📦 Quiz Page: $page | Items: ${list.length} | hasMore: $hasMore");

        setState(() {
          if (page == 1) {
            _quizzes = list.map((e) => QuizItem.fromJson(e)).toList();
          } else {
            final existingIds = _quizzes.map((e) => e.quizId).toSet();
            final newItems =
                list.map((e) => QuizItem.fromJson(e)).where((e) => !existingIds.contains(e.quizId)).toList();
            _quizzes.addAll(newItems);
          }
          _currentPage = page;
          _hasMore = hasMore;
          _isFetchingQuizzes = false;
        });
      }
    } catch (e) {
      setState(() => _isFetchingQuizzes = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _fetchQuizzes(_selectedCategoryId, page: _currentPage + 1);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  // ── Filter — API already filters by type, so this is just local display ──
  // API returns: upcoming | join_now | resume | submitted | missed
  List<QuizItem> get _filtered {
    if (isMockTest) return _quizzes;

    // When a specific filter is active, API already returned filtered data
    if (_selectedFilter != 'all') return _quizzes;

    // 'all' — show everything the API sent: live (all sub-states) + upcoming + missed
    return _quizzes;
  }

  bool _isLiveStatus(String s) => s == 'join_now' || s == 'resume' || s == 'submitted';

  bool _isLocked(QuizItem quiz) => quiz.isAccessible && !quiz.isPurchased && !quiz.is_attempted;

  void _goToDetail(QuizItem quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                isMockTest
                    ? MockTestDetailPage(quizId: quiz.quizId)
                    : QuizDetailPage(quizId: quiz.quizId, is_subscribed: quiz.isPurchased || !quiz.isAccessible),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 40,
      titleSpacing: 0,
      leading:
          widget.pageId == '1'
              ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              )
              : Padding(
                padding: const EdgeInsets.all(10),
                child: Text(isMockTest ? '📝' : '⚡', style: const TextStyle(fontSize: 20)),
              ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMockTest ? 'Mock Tests' : 'Live / Upcoming Test',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '${_filtered.length} ${isMockTest ? 'tests' : 'quizzes'} available',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
          ),
        ],
      ),
      actions: [
        if (!isMockTest)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizListScreen('1', '4'))),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D6E6E).withOpacity(0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('📝', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 5),
                  Text(
                    'Mock Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  // ─── FILTER SHEET ─────────────────────────────────────────────────────────

  Widget _buildFilterSheet() {
    String tempFilter = _selectedFilter;

    // Live quiz filters — now includes "Assessment" (missed)
    final liveFilters = [
      {
        'key': 'all',
        'title': 'All',
        'subtitle': 'Live, upcoming aur assessment sab dikhao',
        'icon': Icons.view_list,
        'color': AppColors.darkNavy,
      },
      {
        'key': 'live',
        'title': 'Live Now',
        'subtitle': 'Abhi live chal rahe quizzes',
        'icon': Icons.radio_button_checked,
        'color': Colors.red,
      },
      {
        'key': 'upcoming',
        'title': 'Upcoming',
        'subtitle': 'Aane wale quizzes',
        'icon': Icons.schedule,
        'color': const Color(0xFFF59E0B),
      },
      {
        'key': 'missed',
        'title': 'Assessment',
        'subtitle': 'Jo miss ho gaye — ab bhi attempt kar sakte ho',
        'icon': Icons.assignment_late_outlined,
        'color': const Color(0xFF6366F1),
      },
    ];

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
                            gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Filter Quizzes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppColors.greyS600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...liveFilters.map((f) {
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
                        // Re-fetch with new type filter
                        _fetchQuizzes(_selectedCategoryId, page: 1);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
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
              if (_selectedCategoryId == cat.category_id) return;
              setState(() {
                _selectedCategoryId = cat.category_id;
                _currentPage = 1;
                _hasMore = true;
                _quizzes = [];
              });
              await _fetchQuizzes(cat.category_id, page: 1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient:
                    sel
                        ? LinearGradient(
                          colors:
                              isMockTest
                                  ? [const Color(0xFF1a237e), AppColors.darkNavy]
                                  : [AppColors.tealGreen, AppColors.darkNavy],
                        )
                        : null,
                color: sel ? null : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(20),
                border: sel ? null : Border.all(color: AppColors.greyS600.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : AppColors.greyS700,
                  ),
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
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 300 && !_isLoadingMore && _hasMore) {
          _loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final quiz = _filtered[index];
                final colors = _gradients[index % _gradients.length];
                return _buildCard(quiz, colors);
              }, childCount: _filtered.length),
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
          SliverToBoxAdapter(
            child:
                _isLoadingMore
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : !_hasMore
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('✅ All quizzes loaded', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    )
                    : const SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // ─── CARD ─────────────────────────────────────────────────────────────────

  Widget _buildCard(QuizItem quiz, List<Color> colors) {
    // ── Derive display flags from quiz_status ─────────────────────────────
    final String status = quiz.quizStatus; // from API
    final bool isLiveAny = _isLiveStatus(status); // join_now | resume | submitted
    final bool isJoinNow = status == 'join_now';
    final bool isResume = status == 'resume';
    final bool isUpcoming = status == 'upcoming';
    final bool isMissed = status == 'missed';

    final bool hasBanner = quiz.banner != null && quiz.banner!.isNotEmpty;
    final bool locked = _isLocked(quiz);

    return GestureDetector(
      onTap: () => _goToDetail(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // ── Left panel ─────────────────────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  child: SizedBox(
                    width: 95,
                    height: 120,
                    child:
                        hasBanner
                            ? _buildBannerPanel(quiz, colors, isLiveAny, isJoinNow, isResume, isUpcoming, isMissed)
                            : _buildGradientPanel(quiz, colors, isLiveAny, isJoinNow, isResume, isUpcoming, isMissed),
                  ),
                ),

                // ── Right content ──────────────────────────────────────
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

                            // Countdown — only upcoming
                            if (isUpcoming && quiz.startsInText.isNotEmpty)
                              _chip(Icons.schedule, quiz.startsInText, Colors.orange),

                            // Resume chip — live, in-progress
                            if (isResume) _chip(Icons.pending_actions_rounded, 'In Progress', const Color(0xFF00897B)),

                            // Assessment chip — missed
                            if (isMissed) _chip(Icons.assignment_late_outlined, 'Assessment', const Color(0xFF6366F1)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ── Action button ───────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isMissed ? [const Color(0xFF6366F1), const Color(0xFF4338CA)] : colors,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _btnIcon(quiz, isLiveAny, isJoinNow, isResume, isMissed, locked),
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _btnText(quiz, isLiveAny, isJoinNow, isResume, isMissed, locked),
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

            // ── Mock test progress bar ────────────────────────────────
            if (isMockTest && quiz.is_attempted)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 11, color: colors[1]),
                            const SizedBox(width: 4),
                            Text(
                              'Attempted',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.greyS600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 5,
                        backgroundColor: Colors.grey.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(colors[1]),
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

  // ─── BANNER PANEL ─────────────────────────────────────────────────────────

  Widget _buildBannerPanel(
    QuizItem quiz,
    List<Color> colors,
    bool isLiveAny,
    bool isJoinNow,
    bool isResume,
    bool isUpcoming,
    bool isMissed,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          quiz.banner!,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => _buildGradientPanel(quiz, colors, isLiveAny, isJoinNow, isResume, isUpcoming, isMissed),
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
          child: Center(child: _statusBadge(isLiveAny, isJoinNow, isResume, isUpcoming, isMissed)),
        ),
        if (quiz.isAccessible && !quiz.isPurchased)
          Positioned(
            top: 6,
            right: 6,
            child: Icon(Icons.workspace_premium, color: Colors.white.withOpacity(0.9), size: 14),
          ),
      ],
    );
  }

  // ─── GRADIENT PANEL ───────────────────────────────────────────────────────

  Widget _buildGradientPanel(
    QuizItem quiz,
    List<Color> colors,
    bool isLiveAny,
    bool isJoinNow,
    bool isResume,
    bool isUpcoming,
    bool isMissed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMissed ? [const Color(0xFF4338CA), const Color(0xFF6366F1)] : colors,
        ),
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
                  child: Center(
                    child: Text(
                      isMockTest
                          ? '📝'
                          : isMissed
                          ? '📋'
                          : '⚡',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _statusBadge(isLiveAny, isJoinNow, isResume, isUpcoming, isMissed),
              ],
            ),
          ),
          if (quiz.isAccessible && !quiz.isPurchased)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.workspace_premium, color: Colors.white.withOpacity(0.8), size: 13),
            ),
        ],
      ),
    );
  }

  // ─── STATUS BADGE ─────────────────────────────────────────────────────────

  Widget _statusBadge(bool isLiveAny, bool isJoinNow, bool isResume, bool isUpcoming, bool isMissed) {
    Color color;
    String label;
    IconData? icon;

    if (isMockTest) {
      color = const Color(0xFF3949AB);
      label = 'MOCK';
      icon = Icons.assignment_outlined;
    } else if (isResume) {
      color = const Color(0xFF00897B);
      label = 'RESUME';
      icon = Icons.pending_actions_rounded;
    } else if (isJoinNow || isLiveAny) {
      color = Colors.red;
      label = 'LIVE';
      icon = null; // dot instead
    } else if (isUpcoming) {
      color = const Color(0xFFF59E0B);
      label = 'UPCOMING';
      icon = null;
    } else if (isMissed) {
      color = const Color(0xFF6366F1);
      label = 'ASSESSMENT';
      icon = Icons.assignment_late_outlined;
    } else {
      color = AppColors.greyS600;
      label = 'ENDED';
      icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot for live
          if (!isMockTest && (isJoinNow || isLiveAny) && !isResume)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          // Icon for resume / missed / mock
          if (icon != null)
            Padding(padding: const EdgeInsets.only(right: 3), child: Icon(icon, size: 7, color: Colors.white)),
          Text(
            label,
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  IconData _btnIcon(QuizItem quiz, bool isLiveAny, bool isJoinNow, bool isResume, bool isMissed, bool locked) {
    if (locked) return Icons.lock_outline;
    if (isMockTest) {
      return quiz.is_attempted ? Icons.bar_chart_rounded : Icons.edit_outlined;
    }
    if (isResume) return Icons.play_circle_outline;
    if (isJoinNow || isLiveAny) return Icons.play_arrow_rounded;
    if (isMissed) return Icons.assignment_late_outlined;
    return Icons.arrow_forward_rounded;
  }

  String _btnText(QuizItem quiz, bool isLiveAny, bool isJoinNow, bool isResume, bool isMissed, bool locked) {
    if (locked) return 'Subscribe to Unlock';
    if (isMockTest) {
      return quiz.is_attempted ? 'View Result' : 'Start Test';
    }
    if (isResume) return 'Resume Quiz';
    if (isJoinNow || isLiveAny) return 'Join Now';
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
            isMockTest ? 'Koi Mock Test nahi mila' : 'No quizzes found',
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
