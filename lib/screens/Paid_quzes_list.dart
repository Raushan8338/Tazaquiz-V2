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
import 'package:tazaquiznew/utils/session_manager.dart';

class Paid_QuizListScreen extends StatefulWidget {
  final String pageId;
  final String PageType;
  final String pageTitle;
  Paid_QuizListScreen(this.pageId, this.PageType, this.pageTitle);

  @override
  _Paid_QuizListScreenState createState() => _Paid_QuizListScreenState();
}

class _Paid_QuizListScreenState extends State<Paid_QuizListScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';
  String? _errorMessage;

  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  List<CategoryItem> _categories = [];
  int _selectedCategoryId = 0;

  List<Map<String, dynamic>> _chapters = [];
  bool _isFetchingChapters = false;
  int _selectedChapterId = 0;
  String _selectedChapterName = 'All Topics';

  bool _isLoading = true;
  bool _isFetchingQuizzes = false;
  List<QuizItem> _quizzes = [];
  UserModel? _user;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get isLiveTest     => widget.PageType == '7';
  bool get isChapterTest  => widget.PageType == '0';
  bool get isMockTest     => widget.PageType == '4';
  bool get isFullMockTest => widget.PageType == '5';
  bool get isPYP          => widget.PageType == '6';
  bool get showCategoryTabs => isLiveTest || isMockTest || isChapterTest;

  final List<List<Color>> _cardGradients = const [
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
    [AppColors.darkNavy, Color(0xFF0D4B3B)],
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    bannerService.loadAd(
        () => mounted ? setState(() => isBannerLoaded = true) : null);
    _getUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    bannerService.dispose();
    super.dispose();
  }

  // ── DATA FETCHING ─────────────────────────────────────────────────

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
      Response response = await authRepository
          .fetchStudySubjectCategory({'categoryId': widget.pageId});

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _categories = [
            if (!isChapterTest) CategoryItem(category_id: 0, name: 'All'),
            ...list.map((e) => CategoryItem.fromJson(e)).toList(),
          ];
          if (isChapterTest && _categories.isNotEmpty) {
            _selectedCategoryId = _categories[0].category_id;
          }
          _isLoading = false;
          _errorMessage = null;
        });

        if (isChapterTest && _selectedCategoryId != 0) {
          await _fetchChapters(_selectedCategoryId);
        } else {
          await _fetchQuizzes(0, 1);
        }
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
        _errorMessage = 'Unexpected error occurred.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchChapters(int subjectId) async {
  setState(() {
    _chapters = [];
    _selectedChapterId = 0;          // 0 = "All Topics"
    _selectedChapterName = 'All Topics';
    _isFetchingChapters = true;
  });
  try {
    Authrepository auth = Authrepository(Api_Client.dio);
    final response =
        await auth.fetchTopics({'subject_id': subjectId.toString()});
    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? [];
      final topics = list
          .map((e) => {
                'id': int.tryParse(e['level_id'].toString()) ?? 0,
                'name': e['name'].toString(),
              })
          .toList();
 
      setState(() {
        // ✅ "All Topics" pehle entry — id=0
        _chapters = [
          {'id': 0, 'name': 'All Topics'},
          ...topics,
        ];
        // ✅ Default: All Topics selected (id=0)
        _selectedChapterId = 0;
        _selectedChapterName = 'All Topics';
        _isFetchingChapters = false;
      });
 
      // ✅ All Topics ke saath pehla data load — topic_id nahi jayega
      await _fetchQuizzes(subjectId, 1);
    } else {
      setState(() => _isFetchingChapters = false);
    }
  } catch (_) {
    setState(() => _isFetchingChapters = false);
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
      'education_level_id': isChapterTest
          ? categoryId.toString()
          : educationLevelId == 0
              ? categoryId.toString()
              : '0',
      'Pagetype': widget.PageType,
      if (isLiveTest &&
          (_selectedFilter == 'live' ||
              _selectedFilter == 'upcoming' ||
              _selectedFilter == 'missed'))
        'type': _selectedFilter,
      // ✅ KEY FIX: topic_id sirf tab jaaye jab specific chapter selected ho
      // _selectedChapterId == 0 matlab "All Topics" → topic_id mat bhejo
      if (isChapterTest && _selectedChapterId != 0)
        'topic_id': _selectedChapterId.toString(),
    };
 
    print('_fetchQuizzes payload: $data');
 
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
      _errorMessage = 'Unexpected error occurred.';
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

  // ── FILTERED LIST ─────────────────────────────────────────────────

  List<QuizItem> get _filtered {
    if (isMockTest || isFullMockTest || isPYP || isChapterTest) {
      if (_selectedFilter == 'attempted')
        return _quizzes.where((q) => q.is_attempted).toList();
      if (_selectedFilter == 'unattempted')
        return _quizzes.where((q) => !q.is_attempted).toList();
      return _quizzes;
    }
    if (_selectedFilter == 'live')
      return _quizzes.where((q) => q.isLive).toList();
    if (_selectedFilter == 'upcoming')
      return _quizzes
          .where((q) => q.quizStatus == 'upcoming' && !q.isLive)
          .toList();
    if (_selectedFilter == 'ended')
      return _quizzes.where((q) => q.quizStatus == 'ended').toList();
    if (_selectedFilter == 'missed')
      return _quizzes.where((q) => q.quizStatus == 'missed').toList();
    final live = _quizzes.where((q) => q.isLive).toList();
    final upcoming = _quizzes
        .where((q) => q.quizStatus == 'upcoming' && !q.isLive)
        .toList();
    final missed = _quizzes.where((q) => q.quizStatus == 'missed').toList();
    return [...live, ...upcoming, ...missed];
  }

  // ── NAVIGATION ────────────────────────────────────────────────────

  void _goToDetail(QuizItem quiz) {
    if (!quiz.isAccessible) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BuyCoursePage(
                    contentId: widget.pageId,
                    page_API_call: 'SUBSCRIPTION',
                  )));
      return;
    }
    if (isMockTest || isFullMockTest || isPYP) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => MockTestDetailPage(quizId: quiz.quizId)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  QuizDetailPage(quizId: quiz.quizId, is_subscribed: true)));
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _getUserData,
              color: AppColors.tealGreen,
              child: Column(children: [
                if (showCategoryTabs) _buildCategoryTabs(),
                if (isChapterTest && !_isLoading && _selectedCategoryId != 0)
                  _buildChapterSelectorRow(),
                if (_errorMessage != null && !_isFetchingQuizzes)
                  _buildErrorBanner(),
                Expanded(
                  child: _isFetchingQuizzes
                      ? _buildLoadingState()
                      : _filtered.isEmpty && _errorMessage == null
                          ? _buildEmptyState()
                          : _errorMessage != null && _quizzes.isEmpty
                              ? _buildFullErrorState()
                              : _buildContent(),
                ),
              ]),
            ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
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
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isLiveTest ? '⚡'
                : isMockTest ? '📝'
                : isFullMockTest ? '🎯'
                : isChapterTest ? '📖'
                : '📜',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.pageTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins'),
                overflow: TextOverflow.ellipsis),
            Text('${_filtered.length} tests available',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65), fontSize: 11)),
          ]),
        ),
      ]),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
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
                _selectedChapterId = 0;
                _selectedChapterName = 'All Topics';
                _chapters = [];
                _quizzes = [];
              });
              if (isChapterTest && cat.category_id != 0) {
                await _fetchChapters(cat.category_id);
              } else {
                // ORIGINAL: educationLevelId = 0 → subject wise filter
                await _fetchQuizzes(cat.category_id, 0);
              }
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

  // ── CHAPTER SELECTOR ──────────────────────────────────────────────

  Widget _buildChapterSelectorRow() {
    final bool hasChapterSelected = _selectedChapterId != 0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: _isFetchingChapters ? null : _showChapterBottomSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: hasChapterSelected
                ? AppColors.tealGreen.withOpacity(0.07)
                : const Color(0xFFF0F2F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasChapterSelected
                  ? AppColors.tealGreen.withOpacity(0.4)
                  : AppColors.greyS600.withOpacity(0.2),
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasChapterSelected
                    ? AppColors.tealGreen.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.menu_book_rounded,
                  size: 16,
                  color: hasChapterSelected
                      ? AppColors.tealGreen
                      : AppColors.greyS600),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Topic / Chapter',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.greyS600,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins')),
                Text(
                  _isFetchingChapters ? 'Loading topics...' : _selectedChapterName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: hasChapterSelected
                        ? AppColors.tealGreen
                        : AppColors.darkNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            _isFetchingChapters
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.tealGreen)))
                : Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: hasChapterSelected
                        ? AppColors.tealGreen
                        : AppColors.greyS600),
          ]),
        ),
      ),
    );
  }

  void _showChapterBottomSheet() {
    if (_chapters.isEmpty) return;
    int tempChapterId = _selectedChapterId;
    String tempChapterName = _selectedChapterName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Select Topic',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                            fontFamily: 'Poppins')),
                    const Spacer(),
                    if (_chapters.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.tealGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('${_chapters.length} topics',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.tealGreen,
                                fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded,
                            color: AppColors.greyS600)),
                  ]),
                  const SizedBox(height: 4),
                  Text('Choose a topic to filter quizzes',
                      style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
                  const SizedBox(height: 14),
                ]),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.48),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    final int chId = chapter['id'] as int;
                    final String chName = chapter['name'] as String;
                    final bool sel = tempChapterId == chId;
                    return GestureDetector(
                      onTap: () => setModalState(() {
                        tempChapterId = chId;
                        tempChapterName = chName;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.tealGreen.withOpacity(0.07)
                              : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: sel ? AppColors.tealGreen : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.tealGreen.withOpacity(0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.bookmark_outline_rounded,
                                color: sel ? AppColors.tealGreen : AppColors.greyS600,
                                size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(chName,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Poppins',
                                    fontWeight:
                                        sel ? FontWeight.w700 : FontWeight.w500,
                                    color: sel
                                        ? AppColors.tealGreen
                                        : AppColors.darkNavy)),
                          ),
                          if (sel)
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.tealGreen, size: 20),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChapterId = tempChapterId;
                      _selectedChapterName = tempChapterName;
                    });
                    Navigator.pop(context);
                    // Chapter apply: educationLevelId=1 → '0' jayega (chapter topic_id se filter)
                    _fetchQuizzes(_selectedCategoryId, 1);
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
                      child: Text('Apply Topic Filter',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── CONTENT ───────────────────────────────────────────────────────

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
                (context, index) => _buildCard(
                    _filtered[index],
                    _cardGradients[index % _cardGradients.length]),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final i = adAfterIndex + 1 + index;
                    return _buildCard(_filtered[i],
                        _cardGradients[i % _cardGradients.length]);
                  },
                  childCount: _filtered.length - adAfterIndex - 1,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── CARD ──────────────────────────────────────────────────────────

  Widget _buildCard(QuizItem quiz, List<Color> colors) {
    final bool isAttempted = quiz.is_attempted;
    final bool isLive = isLiveTest && quiz.quizStatus == 'live';
    final bool isUpcoming = isLiveTest && quiz.quizStatus == 'upcoming';
    final bool isMissed = isLiveTest && quiz.quizStatus == 'missed';
    final bool isLocked = !quiz.isAccessible;

    final List<Color> panelColors = isLocked
        ? [const Color(0xFF263238), const Color(0xFF37474F)]
        : isLive
            ? [const Color(0xFF7B0000), const Color(0xFFB71C1C)]
            : isUpcoming
                ? [const Color(0xFF0A1628), const Color(0xFF0D4B3B)]
                : isMissed
                    ? [const Color(0xFF1A237E), const Color(0xFF3949AB)]
                    : colors;

    final List<Color> btnColors = isLocked
        ? [const Color(0xFFBF360C), const Color(0xFFE64A19)]
        : isLive
            ? [const Color(0xFFB71C1C), const Color(0xFFE53935)]
            : isMissed
                ? [const Color(0xFF283593), const Color(0xFF3949AB)]
                : [const Color(0xFF0A1628), const Color(0xFF0D4B3B)];

    String dateDisplay = '';
    String monthDisplay = '';
    if (isLiveTest && quiz.startDateTime.isNotEmpty) {
      try {
        final dt = DateTime.parse(quiz.startDateTime);
        const months = [
          'JAN','FEB','MAR','APR','MAY','JUN',
          'JUL','AUG','SEP','OCT','NOV','DEC'
        ];
        dateDisplay = '${dt.day}';
        monthDisplay = months[dt.month - 1];
      } catch (_) {}
    }

    final String badgeLabel = isLocked
        ? 'Locked'
        : isLive ? 'Live'
        : isUpcoming ? 'Soon'
        : isMissed ? 'Assess'
        : isAttempted ? 'Done'
        : 'Attempt';

    final Color badgeColor = isLocked
        ? const Color(0xFF74726E)
        : isLive ? Colors.red
        : isUpcoming ? const Color(0xFF1B5E20)
        : isMissed ? const Color(0xFF3949AB)
        : isAttempted ? const Color(0xFF00897B)
        : const Color(0xFF3949AB);

    final String panelEmoji = isLocked ? '🔒'
        : isLive ? '⚡'
        : isUpcoming ? '⏰'
        : isMissed ? '📋'
        : isMockTest ? '📝'
        : isFullMockTest ? '🎯'
        : isChapterTest ? '📖'
        : isPYP ? '📜'
        : '⚡';

    return GestureDetector(
      onTap: () => _goToDetail(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── LEFT PANEL ──────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                child: Container(
                  width: 78,
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(panelEmoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 5),
                            if (dateDisplay.isNotEmpty) ...[
                              Text(dateDisplay,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      height: 1.1)),
                              Text(monthDisplay,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Poppins')),
                              const SizedBox(height: 6),
                            ] else
                              const SizedBox(height: 4),
                            // Status Badge
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isLive)
                                    Container(
                                      width: 5, height: 5,
                                      margin: const EdgeInsets.only(right: 3),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
                                      badgeLabel,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.2,
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
              ),

              // ── RIGHT CONTENT ────────────────────────────────
              Expanded(
                child: Container(
                  decoration: isLive
                      ? const BoxDecoration(
                          color: Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TranslatedText(
                          quiz.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                            height: 1.3,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (quiz.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          TranslatedText(
                            quiz.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greyS600,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                children: [
                                  if (quiz.timeLimit.isNotEmpty &&
                                      quiz.timeLimit != '0')
                                    _chip(Icons.timer_outlined,
                                        '${quiz.timeLimit} min',
                                        AppColors.greyS600),
                                  if (quiz.totalQuestions > 0)
                                    _chip(Icons.help_outline_rounded,
                                        '${quiz.totalQuestions} Qs',
                                        AppColors.greyS600),
                                  if (isLiveTest &&
                                      quiz.startsInText.isNotEmpty &&
                                      !isLive)
                                    _chip(Icons.schedule_rounded,
                                        quiz.startsInText,
                                        Colors.orange.shade700),
                                  if (isMissed)
                                    _chip(Icons.assignment_late_outlined,
                                        'Assessment',
                                        const Color(0xFF6366F1)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _goToDetail(quiz),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: btnColors),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: btnColors[1].withOpacity(0.3),
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _btnIcon(quiz, isLive, isAttempted),
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    TranslatedText(
                                      _btnText(quiz, isLive, isMissed,
                                          isAttempted),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
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
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(7)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        TranslatedText(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  IconData _btnIcon(QuizItem quiz, bool isLive, bool isAttempted) {
    if (!quiz.isAccessible) return Icons.lock_outline_rounded;
    if (!isLiveTest)
      return isAttempted ? Icons.bar_chart_rounded : Icons.play_arrow_rounded;
    if (isLive) return Icons.play_arrow_rounded;
    return Icons.arrow_forward_rounded;
  }

  String _btnText(QuizItem quiz, bool isLive, bool isMissed, bool isAttempted) {
    if (!quiz.isAccessible) return 'Enroll Now';
    if (!isLiveTest) return isAttempted ? 'View Result' : 'Start Test';
    if (isLive) return 'Join Now';
    if (isMissed) return 'Attempt';
    return 'View Details';
  }

  // ── ERROR / EMPTY / LOADING ───────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200)),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: Colors.orange.shade700, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: TranslatedText(_errorMessage!,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500))),
        GestureDetector(
          onTap: () => _fetchQuizzes(_selectedCategoryId, 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8)),
            child: TranslatedText('Retry',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _buildFullErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.all(24),
              decoration:
                  BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  size: 48, color: Colors.red.shade300)),
          const SizedBox(height: 20),
          const TranslatedText('Unable to Load',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy)),
          const SizedBox(height: 8),
          TranslatedText(_errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.greyS600)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _getUserData,
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
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                TranslatedText('Try Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.tealGreen.withOpacity(0.08),
              shape: BoxShape.circle),
          child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.tealGreen),
              strokeWidth: 3),
        ),
        const SizedBox(height: 16),
        TranslatedText('Loading ${widget.pageTitle.toLowerCase()}...',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.greyS600,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    final Map<String, Map<String, dynamic>> emptyData = {
      '0': {
        'icon': '📖',
        'title': 'No Chapter Tests Found',
        'subtitle': 'Try selecting a different subject or topic.'
      },
      '4': {
        'icon': '📝',
        'title': 'No Mock Tests Found',
        'subtitle': 'Try selecting a different subject or filter.'
      },
      '5': {
        'icon': '🎯',
        'title': 'No Full Mock Tests Available',
        'subtitle': 'Full mock tests will appear here when published.'
      },
      '6': {
        'icon': '📜',
        'title': 'No Previous Year Papers',
        'subtitle': 'PYP papers will appear here when added.'
      },
    };
    final data = emptyData[widget.PageType] ??
        {'icon': '📭', 'title': 'Nothing Here', 'subtitle': 'Try again later.'};
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.07),
                  shape: BoxShape.circle),
              child: TranslatedText(data['icon'] as String,
                  style: const TextStyle(fontSize: 48))),
          const SizedBox(height: 20),
          TranslatedText(data['title'] as String,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy)),
          const SizedBox(height: 8),
          TranslatedText(data['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.greyS600)),
        ]),
      ),
    );
  }

  // ── FILTER SHEET ──────────────────────────────────────────────────

  Widget _buildFilterSheet() {
    String tempFilter = _selectedFilter;
    final mockFilters = [
      {'key': 'all', 'title': 'All Tests', 'subtitle': 'Show every test in this series', 'icon': Icons.view_list_rounded, 'color': const Color(0xFF0A1628)},
      {'key': 'unattempted', 'title': 'Not Attempted', 'subtitle': "Tests you haven't started yet", 'icon': Icons.radio_button_unchecked_rounded, 'color': const Color(0xFF3949AB)},
      {'key': 'attempted', 'title': 'Attempted', 'subtitle': 'Tests you have already completed', 'icon': Icons.check_circle_outline_rounded, 'color': const Color(0xFF00897B)},
    ];
    final liveFilters = [
      {'key': 'all', 'title': 'All Tests', 'subtitle': 'Show live, upcoming and assessments', 'icon': Icons.view_list_rounded, 'color': const Color(0xFF0A1628)},
      {'key': 'live', 'title': 'Live Now', 'subtitle': 'Tests currently running', 'icon': Icons.radio_button_checked_rounded, 'color': Colors.red},
      {'key': 'upcoming', 'title': 'Upcoming', 'subtitle': 'Tests scheduled ahead', 'icon': Icons.schedule_rounded, 'color': const Color(0xFFF59E0B)},
      {'key': 'missed', 'title': 'Assessment', 'subtitle': 'Missed tests — attempt anytime', 'icon': Icons.assignment_late_outlined, 'color': const Color(0xFF6366F1)},
      {'key': 'ended', 'title': 'Ended', 'subtitle': 'Tests that have concluded', 'icon': Icons.history_rounded, 'color': AppColors.greyS600},
    ];
    final filters = isLiveTest ? liveFilters : mockFilters;

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
                TranslatedText('Filter Tests',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy)),
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
                  onTap: () =>
                      setModalState(() => tempFilter = f['key'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                        color: sel
                            ? c.withOpacity(0.07)
                            : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: sel ? c : Colors.transparent, width: 1.5)),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: sel
                                ? c.withOpacity(0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(f['icon'] as IconData,
                            color: sel ? c : AppColors.greyS600, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            TranslatedText(f['title'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: sel ? c : AppColors.darkNavy)),
                            const SizedBox(height: 2),
                            TranslatedText(f['subtitle'] as String,
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
                  // Filter apply: educationLevelId=1 → original logic
                  _fetchQuizzes(_selectedCategoryId, 1);
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
                      child: TranslatedText('Apply Filter',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))),
                ),
              ),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ]),
      );
    });
  }
}

// ── DOT PATTERN ───────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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