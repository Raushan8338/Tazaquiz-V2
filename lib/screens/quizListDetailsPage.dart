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
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/mock_test_detail_page.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizListScreen extends StatefulWidget {
  String pageId;
  String PageType;
  QuizListScreen(this.pageId, this.PageType);

  @override
  _QuizListScreenState createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';

  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  List<CategoryItem> _categories = [];
  int _selectedCategoryId = 0;

  bool _isLoading = true;
  bool _isFetchingQuizzes = false;
  List<QuizItem> _quizzes = [];
  UserModel? _user;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    bannerService.loadAd(
        () => mounted ? setState(() => isBannerLoaded = true) : null);
    _scrollController.addListener(_onScroll);
    _getUserData();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

  Future<void> _fetchQuizzes(int categoryId, {int page = 1}) async {
    if (page == 1) setState(() => _isFetchingQuizzes = true);
    try {
      Authrepository auth = Authrepository(Api_Client.dio);
      final Map<String, dynamic> payload = {
        'Pagetype': widget.PageType,
        'category_id': categoryId.toString(),
        'user_id': _user!.id.toString(),
        'page': page.toString(),
        'limit': '5',
      };
      if (_selectedFilter == 'live' ||
          _selectedFilter == 'upcoming' ||
          _selectedFilter == 'missed') {
        payload['type'] = _selectedFilter;
      }
      final response = await auth.fetch_Quiz_List(payload);
      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        final bool hasMore = response.data['hasMore'] ?? false;
        setState(() {
          if (page == 1) {
            _quizzes = list.map((e) => QuizItem.fromJson(e)).toList();
          } else {
            final existingIds = _quizzes.map((e) => e.quizId).toSet();
            final newItems = list
                .map((e) => QuizItem.fromJson(e))
                .where((e) => !existingIds.contains(e.quizId))
                .toList();
            _quizzes.addAll(newItems);
          }
          _currentPage = page;
          _hasMore = hasMore;
          _isFetchingQuizzes = false;
        });
        if (page == 1) _animController.forward(from: 0);
        if (page == 1 && hasMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollController.hasClients) return;
            final pos = _scrollController.position;
            if (pos.maxScrollExtent == 0 || pos.maxScrollExtent < 300) {
              _loadMore();
            }
          });
        }
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

  List<QuizItem> get _filtered => _quizzes;

  bool _isLiveStatus(String s) =>
      s == 'join_now' || s == 'resume' || s == 'submitted';

  void _goToDetail(QuizItem quiz) {
    if (!quiz.isAccessible) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuyCoursePage(
            contentId: quiz.subscription_id.toString(),
            page_API_call: 'SUBSCRIPTION',
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizDetailPage(
          pageType_data: widget.PageType,
          quizId: quiz.quizId,
          is_subscribed: quiz.isPurchased || !quiz.isAccessible,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: _isFetchingQuizzes
                ? _buildLoadingState()
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromARGB(0, 255, 255, 255),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)],
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Container(
          //   padding: const EdgeInsets.all(8),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.15),
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          //   child: const Text('⚡', style: TextStyle(fontSize: 16)),
          // ),
       
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live & Upcoming Tests',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins'),
              ),
              Text(
                '${_filtered.length} tests available',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.filter_list_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _buildFilterSheet()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── FILTER SHEET ─────────────────────────────────────────────────
  Widget _buildFilterSheet() {
    String tempFilter = _selectedFilter;
    final filters = [
      {'key': 'all', 'title': 'All Tests', 'subtitle': 'Live, upcoming aur assessment sab', 'icon': Icons.view_list_rounded, 'color': const Color(0xFF0D4B3B)},
      {'key': 'live', 'title': 'Live Now', 'subtitle': 'Abhi live chal rahe tests', 'icon': Icons.radio_button_checked_rounded, 'color': Colors.red},
      {'key': 'upcoming', 'title': 'Upcoming', 'subtitle': 'Aane wale scheduled tests', 'icon': Icons.schedule_rounded, 'color': const Color(0xFFF59E0B)},
      {'key': 'missed', 'title': 'Assessment', 'subtitle': 'Miss ho gaye — ab bhi attempt karo', 'icon': Icons.assignment_late_outlined, 'color': const Color(0xFF6366F1)},
    ];
    return StatefulBuilder(builder: (context, setModalState) {
      return Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.filter_list_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Filter Tests',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                        fontFamily: 'Poppins')),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: AppColors.greyS600)),
              ]),
              const SizedBox(height: 16),
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
                        border: Border.all(
                            color: sel ? c : Colors.transparent, width: 1.5)),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: sel ? c.withOpacity(0.15) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(f['icon'] as IconData,
                            color: sel ? c : AppColors.greyS600, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(f['title'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                    color: sel ? c : AppColors.darkNavy,
                                    fontFamily: 'Poppins')),
                            const SizedBox(height: 2),
                            Text(f['subtitle'] as String,
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.greyS500)),
                          ])),
                      if (sel)
                        Icon(Icons.check_circle_rounded, color: c, size: 20),
                    ]),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = tempFilter);
                  Navigator.pop(context);
                  _fetchQuizzes(_selectedCategoryId, page: 1);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF0D4B3B).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: const Center(
                      child: Text('Apply Filter',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Poppins'))),
                ),
              ),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ]),
      );
    });
  }

  // ── CATEGORY TABS ─────────────────────────────────────────────────
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
                gradient: sel
                    ? const LinearGradient(
                        colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)])
                    : null,
                color: sel ? null : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(20),
                border: sel
                    ? null
                    : Border.all(color: AppColors.greyS600.withOpacity(0.2)),
              ),
              child: Center(
                child: TranslatedText(cat.name,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : AppColors.greyS700,
                        fontFamily: 'Poppins')),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CONTENT ───────────────────────────────────────────────────────
  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCard(_filtered[index], index),
                childCount: _filtered.length,
              ),
            ),
          ),
          if (isBannerLoaded && bannerService.bannerAd != null)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      height: bannerService.bannerAd!.size.height.toDouble(),
                      width: bannerService.bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: bannerService.bannerAd!)),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0D4B3B)),
                            strokeWidth: 2)))
                : !_hasMore
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  width: 40,
                                  height: 1,
                                  color: Colors.grey.shade300),
                              const SizedBox(width: 10),
                              Text('All tests loaded',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11)),
                              const SizedBox(width: 10),
                              Container(
                                  width: 40,
                                  height: 1,
                                  color: Colors.grey.shade300),
                            ]))
                    : const SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // ── CARD ──────────────────────────────────────────────────────────
  Widget _buildCard(QuizItem quiz, int index) {
    final String status = quiz.quizStatus;
    final bool isLiveAny = _isLiveStatus(status);
    final bool isJoinNow = status == 'join_now';
    final bool isResume = status == 'resume';
    final bool isUpcoming = status == 'upcoming';
    final bool isMissed = status == 'missed';
    final bool isLocked = !quiz.isAccessible;
    final bool hasBanner = quiz.banner != null && quiz.banner!.isNotEmpty;

    final List<Color> panelColors = isLocked
        ? [const Color(0xFF263238), const Color(0xFF37474F)]
        : isLiveAny || isJoinNow
            ? [const Color(0xFF7B0000), const Color(0xFFB71C1C)]
            : isUpcoming
                ? [const Color(0xFF0A1628), const Color(0xFF0D4B3B)]
                : isMissed
                    ? [const Color(0xFF1A237E), const Color(0xFF3949AB)]
                    : [const Color(0xFF0A1628), const Color(0xFF0D4B3B)];

    final List<Color> btnColors = isLocked
        ? [const Color(0xFFBF360C), const Color(0xFFE64A19)]
        : isLiveAny || isJoinNow
            ? [const Color(0xFFB71C1C), const Color(0xFFE53935)]
            : isMissed
                ? [const Color(0xFF283593), const Color(0xFF3949AB)]
                : [const Color(0xFF0A1628), const Color(0xFF0D4B3B)];

    // Date parse karo
    String dateDisplay = '';
    String monthDisplay = '';
    if (quiz.startDateTime.isNotEmpty) {
      try {
        final dt = DateTime.parse(quiz.startDateTime);
        final months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
        dateDisplay = '${dt.day}';
        monthDisplay = months[dt.month - 1];
      } catch (_) {}
    }

    String badgeLabel = isLocked
        ? 'Locked'
        : isResume
            ? 'Resume'
            : (isJoinNow || isLiveAny)
                ? 'Live'
                : isUpcoming
                    ? 'Upcoming'
                    : isMissed
                        ? 'Assess'
                        : 'Ended';

    Color badgeColor = isLocked
        ? const Color.fromARGB(255, 116, 114, 114)
        : isResume
            ? const Color(0xFF00897B)
            : (isJoinNow || isLiveAny)
                ? Colors.red
                : isUpcoming
                    ? const Color(0xFF1B5E20)
                    : isMissed
                        ? const Color(0xFF3949AB)
                        : Colors.grey;

    return GestureDetector(
      onTap: () => _goToDetail(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            // ── LEFT PANEL ────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Container(
                width: 82,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: panelColors,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: CustomPaint(painter: _DotPatternPainter())),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Live pulse indicator
            
                          // Icon
                          Text(
                            isLocked
                                ? '🔒'
                                : (isJoinNow || isLiveAny)
                                    ? '⚡'
                                    : isUpcoming
                                        ? '⏰'
                                        : isMissed
                                            ? '📋'
                                            : '⚡',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          // Date
                          if (dateDisplay.isNotEmpty) ...[
                            Text(dateDisplay,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Poppins')),
                            Text(monthDisplay,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.75),
                                    fontFamily: 'Poppins')),
                            const SizedBox(height: 8),
                          ],
                          // Status Badge
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── RIGHT CONTENT ──────────────────────────────────
             Expanded(
  child: Container(
    decoration: (isJoinNow || isLiveAny)
        ? const BoxDecoration(
            color: Color(0xFFFFF5F5),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          )
        : null,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: SizedBox(
        height: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ key fix
          children: [
            // Title
            TranslatedText(
              quiz.title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                  height: 1.35,
                  fontFamily: 'Poppins'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Description
            if (quiz.description.isNotEmpty)
              TranslatedText(
                quiz.description,
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.greyS600,
                    height: 1.4),
                maxLines: 2, // 2 se 1 kar do space bachane ke liye
                overflow: TextOverflow.ellipsis,
              ),
            // Bottom row
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                                if (quiz.timeLimit.isNotEmpty &&
                                    quiz.timeLimit != '0')
                                  Text('⏱ ${quiz.timeLimit} min',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                if (isUpcoming &&
                                    quiz.startsInText.isNotEmpty)
                                  Text('🕐 ${quiz.startsInText}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange.shade700)),
                                if (isLiveAny && quiz.startsInText.isNotEmpty)
                                  Text('🕐 ${quiz.startsInText}',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.red)),
                                if (isResume)
                                  const Text('▶ In Progress',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF00897B))),
                              ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                            onTap: () => _goToDetail(quiz),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: btnColors),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: btnColors[1].withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      _btnIcon(isLiveAny, isJoinNow, isResume,
                                          isMissed, isLocked),
                                      color: Colors.white,
                                      size: 13),
                                  const SizedBox(width: 4),
                                  TranslatedText(
                                    _btnText(quiz, isLiveAny, isJoinNow,
                                        isResume, isMissed, isLocked),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                            ),
                          ),


              ],
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

  // ── GRADIENT PANEL (banner nahi hone par) ────────────────────────
  Widget _buildGradientPanel(QuizItem quiz, List<Color> colors, bool isLiveAny,
      bool isJoinNow, bool isResume, bool isUpcoming, bool isMissed, bool isLocked) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
        Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              isLocked ? '🔒' : (isJoinNow || isLiveAny) ? '⚡' : isUpcoming ? '⏰' : isMissed ? '📋' : '⚡',
              style: const TextStyle(fontSize: 26),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBadge(bool isLiveAny, bool isJoinNow, bool isResume,
      bool isUpcoming, bool isMissed, bool isLocked) {
    Color color;
    String label;
    bool showDot = false;
    if (isLocked) { color = const Color(0xFFBF360C); label = 'LOCKED'; }
    else if (isResume) { color = const Color(0xFF00897B); label = 'RESUME'; }
    else if (isJoinNow || isLiveAny) { color = Colors.red; label = 'LIVE'; showDot = true; }
    else if (isUpcoming) { color = const Color(0xFF0D4B3B); label = 'UPCOMING'; }
    else if (isMissed) { color = const Color(0xFF3949AB); label = 'ASSESS'; }
    else { color = Colors.grey.shade600; label = 'ENDED'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (showDot)
          Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5, fontFamily: 'Poppins')),
      ]),
    );
  }

  IconData _btnIcon(bool isLiveAny, bool isJoinNow, bool isResume,
      bool isMissed, bool isLocked) {
    if (isLocked) return Icons.shopping_cart_outlined;
    if (isResume) return Icons.play_circle_outline_rounded;
    if (isJoinNow || isLiveAny) return Icons.play_arrow_rounded;
    if (isMissed) return Icons.assignment_outlined;
    return Icons.arrow_forward_rounded;
  }

  String _btnText(QuizItem quiz, bool isLiveAny, bool isJoinNow, bool isResume,
      bool isMissed, bool isLocked) {
    if (isLocked) return 'Enroll Now';
    if (isResume) return 'Resume';
    if (isJoinNow || isLiveAny) return 'Join Now';
    if (isMissed) return 'Attempt';
    return 'View Details';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFF0D4B3B).withOpacity(0.08),
                shape: BoxShape.circle),
            child: const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF0D4B3B)),
                strokeWidth: 3)),
        const SizedBox(height: 16),
        Text('Loading tests...',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.greyS600,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF0D4B3B).withOpacity(0.07),
                  shape: BoxShape.circle),
              child: const Icon(Icons.event_busy_rounded,
                  size: 44, color: Color(0xFF0D4B3B))),
          const SizedBox(height: 18),
          const Text('No Tests Found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          Text('Is waqt koi live ya upcoming test nahi hai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.greyS600, height: 1.5)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => PricingPage(CourseIds: '0'))),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF0D4B3B).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]),
              child: const Text('View Plans',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins')),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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