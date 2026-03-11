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
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizListScreen extends StatefulWidget {
  String pageId;
  String PageType;
  QuizListScreen(this.pageId, this.PageType);

  @override
  _QuizListScreenState createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> with SingleTickerProviderStateMixin {
  bool _isGridView = true;
  String _selectedFilter = 'all';
  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  late TabController _tabController;
  List<CategoryItem> _categories = [];
  int _selectedCategoryId = 0;

  bool _isLoading = true;
  bool _isFetchingQuizzes = false;
  List<QuizItem> _quizzes = [];

  // ── PageType check ──
  bool get isMockTest => widget.PageType == '4';

  // ── Theme helpers ──
  List<Color> get _themeGradient =>
      isMockTest ? [AppColors.darkNavy, const Color(0xFF1a237e)] : [AppColors.darkNavy, AppColors.tealGreen];

  Color get _accentColor => isMockTest ? const Color(0xFF3949AB) : AppColors.tealGreen;

  final List<List<Color>> _liveGradients = [
    [Color(0xFF1A4D6D), Color(0xFF28A194)],
    [Color(0xFF28A194), Color(0xFF1A4D6D)],
    [Color(0xFF0C3756), Color(0xFF1A4D6D)],
    [Color(0xFF1A4D6D), Color(0xFF0C3756)],
    [Color(0xFF28A194), Color(0xFF0C3756)],
  ];

  final List<List<Color>> _mockGradients = [
    [Color(0xFF1a237e), Color(0xFF283593)],
    [Color(0xFF0D1B6D), Color(0xFF1a237e)],
    [Color(0xFF283593), Color(0xFF3949AB)],
    [Color(0xFF1a237e), Color(0xFF0D1B6D)],
    [Color(0xFF3949AB), Color(0xFF283593)],
  ];

  List<List<Color>> get _gradientColors => isMockTest ? _mockGradients : _liveGradients;

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    bannerService.loadAd(() => setState(() => isBannerLoaded = true));
    _getUserData();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    bannerService.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    await fetchStudyLevels();
  }

  Future<void> fetchStudyLevels() async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      Response response = await authRepository.fetchStudyLevels();
      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _categories = [
            CategoryItem(category_id: 0, name: 'All'),
            ...list.map((e) => CategoryItem.fromJson(e)).toList(),
          ];
          _isLoading = false;
        });
        await fetchQuizData(0);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching study levels: $e');
    }
  }

  Future<void> fetchQuizData(int category_id) async {
    setState(() => _isFetchingQuizzes = true);
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'Pagetype': widget.PageType,
        'category_id': category_id.toString(),
        'user_id': _user!.id.toString(),
      };
      print(data);
      final responseFuture = await authRepository.fetch_Quiz_List(data);
      print(responseFuture.data);
      if (responseFuture.statusCode == 200) {
        final List list = responseFuture.data['data'] ?? [];
        setState(() {
          _quizzes = list.map((e) => QuizItem.fromJson(e)).toList();
          _isFetchingQuizzes = false;
        });
      }
    } catch (e) {
      setState(() => _isFetchingQuizzes = false);
      print('Error fetching quizzes: $e');
    }
  }

  List<QuizItem> get _filteredQuizzes {
    if (isMockTest) return _quizzes; // Mock me koi filter nahi
    if (_selectedFilter == 'live') return _quizzes.where((q) => q.isLive).toList();
    if (_selectedFilter == 'upcoming') return _quizzes.where((q) => q.quizStatus == 'upcoming' && !q.isLive).toList();
    return _quizzes;
  }

  void _navigateToDetail(QuizItem quiz) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCategoriesSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 3)),

          if (isBannerLoaded && bannerService.bannerAd != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: bannerService.bannerAd!.size.height.toDouble(),
                width: bannerService.bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: bannerService.bannerAd!),
              ),
            ),
          SliverToBoxAdapter(child: const SizedBox(height: 10)),

          if (_isFetchingQuizzes)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_accentColor)),
                ),
              ),
            )
          else if (_filteredQuizzes.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            _isGridView ? _buildGridView() : _buildListView(),

          SliverToBoxAdapter(child: const SizedBox(height: 20)),
        ],
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _themeGradient),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),

              // Mock test dot pattern
              if (isMockTest) Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Back / Icon
                          (widget.pageId == '1')
                              ? IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                                ),
                                onPressed: () => Navigator.pop(context),
                              )
                              : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(isMockTest ? '📝' : '⚡', style: const TextStyle(fontSize: 20)),
                              ),

                          const SizedBox(width: 14),

                          // Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMockTest ? 'Mock Tests' : 'Available Quizzes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  '${_filteredQuizzes.length} ${isMockTest ? 'tests' : 'quizzes'} available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.white.withOpacity(0.8),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Grid toggle
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _isGridView ? Icons.view_list : Icons.grid_view,
                                color: AppColors.white,
                                size: 22,
                              ),
                            ),
                            onPressed: () => setState(() => _isGridView = !_isGridView),
                          ),

                          // Filter — only for Live
                          if (!isMockTest)
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.filter_list, color: AppColors.white, size: 22),
                              ),
                              onPressed:
                                  () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => _buildFilterBottomSheet(),
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CATEGORIES ───────────────────────────────────────────────────────────────

  Widget _buildCategoriesSection() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 16),
        height: 42,
        child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_accentColor))),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          bool isSelected = _selectedCategoryId == category.category_id;

          return GestureDetector(
            onTap: () async {
              setState(() => _selectedCategoryId = category.category_id);
              await fetchQuizData(category.category_id);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: _themeGradient) : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? _accentColor.withOpacity(0.3) : AppColors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 12 : 6,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.greyS700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(isMockTest ? Icons.assignment_outlined : Icons.quiz_outlined, size: 80, color: AppColors.greyS400),
            const SizedBox(height: 16),
            Text(
              isMockTest ? 'Koi Mock Test nahi mila' : 'No quizzes found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.greyS600),
            ),
            const SizedBox(height: 8),
            Text('Try selecting a different category', style: TextStyle(fontSize: 14, color: AppColors.greyS500)),
          ],
        ),
      ),
    );
  }

  // ─── GRID / LIST ──────────────────────────────────────────────────────────────

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final quiz = _filteredQuizzes[index];
          final colors = _gradientColors[index % _gradientColors.length];
          return _buildGridCard(quiz, colors);
        }, childCount: _filteredQuizzes.length),
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final quiz = _filteredQuizzes[index];
        final colors = _gradientColors[index % _gradientColors.length];
        return _buildListCard(quiz, colors);
      }, childCount: _filteredQuizzes.length),
    );
  }

  // ─── GRID CARD ────────────────────────────────────────────────────────────────

  Widget _buildGridCard(QuizItem quiz, List<Color> colors) {
    return InkWell(
      onTap: () => _navigateToDetail(quiz),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.white.withOpacity(0.08), shape: BoxShape.circle),
              ),
            ),
            if (isMockTest)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(painter: _DotPatternPainter()),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isMockTest ? _mockBadge(quiz) : _liveBadge(quiz),
                      if (quiz.isPaid && !quiz.isPurchased)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                          child: Icon(Icons.workspace_premium, color: AppColors.white, size: 14),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    quiz.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      fontFamily: 'Poppins',
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (quiz.difficultyLevel.isNotEmpty)
                    Text(
                      quiz.difficultyLevel,
                      style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.8), fontFamily: 'Poppins'),
                    ),
                  if (!isMockTest && quiz.startsInText.isNotEmpty && !quiz.isLive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Starts in ${quiz.startsInText}',
                        style: TextStyle(fontSize: 10, color: AppColors.white.withOpacity(0.9)),
                      ),
                    ),
                  if (isMockTest && quiz.timeLimit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 11, color: AppColors.white.withOpacity(0.8)),
                          const SizedBox(width: 3),
                          Text(
                            '${quiz.timeLimit} min',
                            style: TextStyle(fontSize: 10, color: AppColors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isMockTest
                              ? (quiz.is_attempted ? Icons.bar_chart_rounded : Icons.edit_outlined)
                              : (quiz.isAccessible ? (quiz.isLive ? Icons.play_arrow : Icons.schedule) : Icons.lock),
                          color: colors[0],
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getButtonText(quiz),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors[0]),
                            overflow: TextOverflow.ellipsis,
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

  // ─── LIST CARD ────────────────────────────────────────────────────────────────

  Widget _buildListCard(QuizItem quiz, List<Color> colors) {
    return InkWell(
      onTap: () => _navigateToDetail(quiz),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Left panel
            Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.08), shape: BoxShape.circle),
                    ),
                  ),
                  if (isMockTest)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: CustomPaint(painter: _DotPatternPainter(), child: const SizedBox.expand()),
                    ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isMockTest ? '📝' : '⚡', style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 6),
                        isMockTest ? _mockBadge(quiz) : _liveBadge(quiz),
                      ],
                    ),
                  ),
                  if (quiz.isPaid && !quiz.isPurchased)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                        child: Icon(Icons.workspace_premium, color: AppColors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),

            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (quiz.description.isNotEmpty)
                      Text(
                        quiz.description,
                        style: TextStyle(fontSize: 12, color: AppColors.greyS600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (quiz.difficultyLevel.isNotEmpty)
                          _chip(Icons.signal_cellular_alt, quiz.difficultyLevel, AppColors.tealGreen),
                        if (quiz.timeLimit.isNotEmpty) _chip(Icons.timer, '${quiz.timeLimit} min', AppColors.greyS600),
                        if (!isMockTest && quiz.startsInText.isNotEmpty && !quiz.isLive)
                          _chip(Icons.schedule, quiz.startsInText, AppColors.orange),
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
                          Icon(
                            isMockTest
                                ? (quiz.is_attempted ? Icons.bar_chart_rounded : Icons.edit_outlined)
                                : (quiz.isAccessible ? (quiz.isLive ? Icons.play_arrow : Icons.schedule) : Icons.lock),
                            color: AppColors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getButtonText(quiz),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
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

  // ─── BADGE HELPERS ────────────────────────────────────────────────────────────

  Widget _mockBadge(QuizItem quiz) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: quiz.is_attempted ? AppColors.tealGreen.withOpacity(0.9) : AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            quiz.is_attempted ? Icons.check_circle_rounded : Icons.assignment_outlined,
            color: AppColors.white,
            size: 9,
          ),
          const SizedBox(width: 3),
          Text(
            quiz.is_attempted ? 'DONE' : 'MOCK',
            style: TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _liveBadge(QuizItem quiz) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: quiz.isLive ? AppColors.red : AppColors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quiz.isLive)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
            ),
          Text(
            quiz.isLive ? 'LIVE' : 'UPCOMING',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white),
          ),
        ],
      ),
    );
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

  // ─── BUTTON TEXT ──────────────────────────────────────────────────────────────

  String _getButtonText(QuizItem quiz) {
    if (isMockTest) {
      return quiz.is_attempted ? '📊 View Result' : '✏️ Start Test';
    }
    if (!quiz.isAccessible) {
      if (quiz.isPaid && !quiz.isPurchased) return 'Unlock - ₹${quiz.price.toStringAsFixed(0)}';
      return 'Locked';
    }
    if (quiz.isLive) return 'Join Now';
    return 'View Details';
  }

  // ─── FILTER BOTTOM SHEET (Live only) ─────────────────────────────────────────

  Widget _buildFilterBottomSheet() {
    String tempSelectedFilter = _selectedFilter;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.filter_list, color: AppColors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Filter Quizzes',
                        20,
                        AppColors.darkNavy,
                        FontWeight.w900,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.greyS600),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.greyS200),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Select Quiz Type',
                      16,
                      AppColors.darkNavy,
                      FontWeight.w800,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    const SizedBox(height: 8),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Choose one option to filter quizzes',
                      13,
                      AppColors.greyS600,
                      FontWeight.w500,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    const SizedBox(height: 20),
                    _buildFilterOption(
                      context: context,
                      icon: Icons.view_list,
                      title: 'All Quizzes',
                      subtitle: 'Show all available quizzes',
                      isSelected: tempSelectedFilter == 'all',
                      activeColor: AppColors.darkNavy,
                      onTap: () => setModalState(() => tempSelectedFilter = 'all'),
                    ),
                    const SizedBox(height: 12),
                    _buildFilterOption(
                      context: context,
                      icon: Icons.radio_button_checked,
                      title: 'Live Quiz',
                      subtitle: 'Show quizzes that are currently live',
                      isSelected: tempSelectedFilter == 'live',
                      activeColor: AppColors.red,
                      onTap: () => setModalState(() => tempSelectedFilter = 'live'),
                    ),
                    const SizedBox(height: 12),
                    _buildFilterOption(
                      context: context,
                      icon: Icons.schedule,
                      title: 'Upcoming Quiz',
                      subtitle: 'Show quizzes scheduled for later',
                      isSelected: tempSelectedFilter == 'upcoming',
                      activeColor: AppColors.tealGreen,
                      onTap: () => setModalState(() => tempSelectedFilter = 'upcoming'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedFilter = tempSelectedFilter);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.transparent,
                          shadowColor: AppColors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.white, size: 22),
                                const SizedBox(width: 10),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  'Apply Filter',
                                  16,
                                  AppColors.white,
                                  FontWeight.w700,
                                  1,
                                  TextAlign.center,
                                  0.0,
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
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(colors: [activeColor.withOpacity(0.15), activeColor.withOpacity(0.08)])
                  : null,
          color: isSelected ? null : AppColors.greyS1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : AppColors.greyS300!, width: isSelected ? 2.5 : 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.2) : AppColors.greyS200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? activeColor : AppColors.greyS600, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    title,
                    15,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  const SizedBox(height: 4),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    subtitle,
                    12,
                    AppColors.greyS600,
                    FontWeight.w500,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? activeColor : AppColors.greyS400, width: 2.5),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DOT PATTERN PAINTER ─────────────────────────────────────────────────────

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
