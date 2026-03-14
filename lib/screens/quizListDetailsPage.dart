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

class QuizListScreen extends StatefulWidget {
  String pageId;
  String PageType;
  QuizListScreen(this.pageId, this.PageType);

  @override
  _QuizListScreenState createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
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
        await _fetchQuizzes(0);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchQuizzes(int categoryId) async {
    setState(() => _isFetchingQuizzes = true);
    try {
      Authrepository auth = Authrepository(Api_Client.dio);
      final response = await auth.fetch_Quiz_List({
        'Pagetype': widget.PageType,
        'category_id': categoryId.toString(),
        'user_id': _user!.id.toString(),
      });
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
    if (isMockTest) return _quizzes;

    // Ended hide karo hamesha
    final active = _quizzes.where((q) => q.isLive || q.quizStatus == 'upcoming').toList();

    if (_selectedFilter == 'live') return active.where((q) => q.isLive).toList();
    if (_selectedFilter == 'upcoming') return active.where((q) => q.quizStatus == 'upcoming' && !q.isLive).toList();
    return active;
  }

  void _goToDetail(QuizItem quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                isMockTest
                    ? MockTestDetailPage(quizId: quiz.quizId, is_subscribed: false)
                    : QuizDetailPage(quizId: quiz.quizId, is_subscribed: false),
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
            isMockTest ? 'Mock Tests' : 'Live Quizzes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
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
      actions:
          !isMockTest
              ? [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              ]
              : [],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isMockTest
                    ? [AppColors.darkNavy, const Color(0xFF1a237e)]
                    : [AppColors.darkNavy, const Color(0xFF0D4B3B)],
          ),
        ),
      ),
    );
  }

  // ─── FILTER BOTTOM SHEET ──────────────────────────────────────────────────

  Widget _buildFilterSheet() {
    String tempFilter = _selectedFilter;
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
                    ...[
                      {
                        'key': 'all',
                        'title': 'All Quizzes',
                        'subtitle': 'Live aur upcoming dono dikhao',
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
                        'color': Colors.orange,
                      },
                    ].map((f) {
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
              setState(() => _selectedCategoryId = cat.category_id);
              await _fetchQuizzes(cat.category_id);
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final quiz = _filtered[index];
              final colors = _gradients[index % _gradients.length];
              return _buildCard(quiz, colors);
            }, childCount: _filtered.length.clamp(0, adAfterIndex + 1)),
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
                final dataIndex = adAfterIndex + 1 + index;
                final quiz = _filtered[dataIndex];
                final colors = _gradients[dataIndex % _gradients.length];
                return _buildCard(quiz, colors);
              }, childCount: _filtered.length - adAfterIndex - 1),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // ─── CARD ─────────────────────────────────────────────────────────────────

  Widget _buildCard(QuizItem quiz, List<Color> colors) {
    final bool isLive = quiz.isLive;
    final bool isUpcoming = quiz.quizStatus == 'upcoming' && !isLive;
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
            // ── Left panel — fixed size ───────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: SizedBox(
                width: 95,
                height: 120,
                child:
                    hasBanner
                        ? _buildBannerPanel(quiz, colors, isLive, isUpcoming)
                        : _buildGradientPanel(quiz, colors, isLive, isUpcoming),
              ),
            ),

            // ── Right content ─────────────────────────────────────
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
                        if (!isMockTest && quiz.startsInText.isNotEmpty && !isLive)
                          _chip(Icons.schedule, quiz.startsInText, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Button
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
                          Icon(_btnIcon(quiz, isLive), color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            _btnText(quiz, isLive),
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

  Widget _buildBannerPanel(QuizItem quiz, List<Color> colors, bool isLive, bool isUpcoming) {
    return SizedBox(
      width: 95,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            quiz.banner!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildGradientPanel(quiz, colors, isLive, isUpcoming),
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
            child: Center(child: _statusBadge(isLive, isUpcoming, quiz.is_attempted)),
          ),
          if (quiz.isPaid && !quiz.isPurchased)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.workspace_premium, color: Colors.white.withOpacity(0.9), size: 14),
            ),
        ],
      ),
    );
  }

  // ─── GRADIENT PANEL ───────────────────────────────────────────────────────

  Widget _buildGradientPanel(QuizItem quiz, List<Color> colors, bool isLive, bool isUpcoming) {
    return SizedBox(
      width: 95,
      height: 120,
      child: Container(
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

            // ── Icon + Badge CENTER ──
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  _statusBadge(isLive, isUpcoming, quiz.is_attempted),
                ],
              ),
            ),

            if (quiz.isPaid && !quiz.isPurchased)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.workspace_premium, color: Colors.white.withOpacity(0.8), size: 13),
              ),
          ],
        ),
      ),
    );
  }

  // ─── STATUS BADGE ─────────────────────────────────────────────────────────

  Widget _statusBadge(bool isLive, bool isUpcoming, bool isAttempted) {
    Color color;
    String label;

    if (isMockTest) {
      color = isAttempted ? AppColors.tealGreen : Colors.white.withOpacity(0.25);
      label = isAttempted ? 'DONE' : 'MOCK';
    } else if (isLive) {
      color = Colors.red;
      label = 'LIVE';
    } else {
      color = Colors.orange;
      label = 'UPCOMING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMockTest && isLive)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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

  IconData _btnIcon(QuizItem quiz, bool isLive) {
    if (isMockTest) return quiz.is_attempted ? Icons.bar_chart_rounded : Icons.edit_outlined;
    if (!quiz.isAccessible) return Icons.lock_outline;
    if (isLive) return Icons.play_arrow_rounded;
    return Icons.arrow_forward_rounded;
  }

  String _btnText(QuizItem quiz, bool isLive) {
    if (isMockTest) return quiz.is_attempted ? 'View Result' : 'Start Test';
    if (!quiz.isAccessible) return 'Subscribe to Unlock';
    if (isLive) return 'Join Now';
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
