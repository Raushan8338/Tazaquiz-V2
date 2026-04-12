import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/ads/banner_ads_helper.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/models/study_category_item.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/course_search_page.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class StudyMaterialScreen extends StatefulWidget {
  String pageId;
  StudyMaterialScreen(this.pageId, {Key? key}) : super(key: key);

  @override
  _StudyMaterialScreenState createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen>
    with SingleTickerProviderStateMixin {
  List<CategoryItem> _categoryItems = [];
  List<StudyMaterialItem> _studyMaterials = [];
  int _selectedCategoryId = 0;
  bool _isLoading = true;
  UserModel? _user;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  late AnimationController _searchAnimController;
  late Animation<double> _searchWidthAnim;

  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _searchWidthAnim = CurvedAnimation(
        parent: _searchAnimController, curve: Curves.easeInOut);
    bannerService.loadAd(() {
      if (mounted) setState(() => isBannerLoaded = true);
    });
    _getdata();
  }

  @override
  void dispose() {
    bannerService.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  List<StudyMaterialItem> get _filteredMaterials {
    if (_searchQuery.trim().isEmpty) return _studyMaterials;
    final query = _searchQuery.toLowerCase();
    return _studyMaterials.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _getdata() async {
        _user = await SessionManager.getUser();

    await fetchStudyLevels();
    await fetchStudyCategory(0, page: 1);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (_searchQuery.trim().isNotEmpty) return;
    setState(() => _isLoadingMore = true);
    await fetchStudyCategory(_selectedCategoryId, page: _currentPage + 1);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> fetchStudyLevels() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    Response response = await authRepository.fetchStudyLevels();
    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? [];
      setState(() {
        _categoryItems = [
          CategoryItem(category_id: 0, name: 'All'),
          ...list.map((e) => CategoryItem.fromJson(e)).toList(),
        ];
      });
    }
  }

  Future<void> fetchStudyCategory(int categoryId, {int page = 1}) async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    Response response = await authRepository.fetchStudyCategory(
        {'category_id': categoryId, 'page': page, 'limit': 6, 'user_id': _user?.id});
    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? [];
      final bool hasMore = response.data['hasMore'] ?? false;
      if (list.isEmpty) {
        setState(() { _hasMore = false; _isLoading = false; });
        return;
      }
      setState(() {
        if (page == 1) {
          _studyMaterials = list.map((e) => StudyMaterialItem.fromJson(e)).toList();
        } else {
          final existingIds = _studyMaterials.map((e) => e.id).toSet();
          final newItems = list
              .map((e) => StudyMaterialItem.fromJson(e))
              .where((e) => !existingIds.contains(e.id))
              .toList();
              
          _studyMaterials.addAll(newItems);
        }
        _currentPage = page;
        _hasMore = hasMore;
        _isLoading = false;
      });
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)))
          : _studyMaterials.isEmpty
              ? _buildEmptyState()
              : _buildBody(),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: widget.pageId == '1'
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.library_books, color: Colors.white, size: 18),
              ),
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'Exam Courses',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins'),
          ),
          TranslatedText(
            'Find your perfect course 🎯',
            style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 10),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StudyMaterialSearchScreen())),
          icon: const Icon(Icons.search, color: Colors.white, size: 22),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StudyMaterialPurchaseHistoryScreen('1'))),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D9E75), Color(0xFF0D6E6E)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0D6E6E).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_library_books_rounded, size: 13, color: Colors.white),
                SizedBox(width: 5),
                TranslatedText('My Courses',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: _buildCategoryTabs(),
      ),
    );
  }

  // ─── CATEGORY TABS ────────────────────────────────────────────────

  Widget _buildCategoryTabs() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: _categoryItems.length,
        itemBuilder: (context, index) {
          final cat = _categoryItems[index];
          final bool isSelected = _selectedCategoryId == cat.category_id;

          return GestureDetector(
            onTap: () async {
              if (_selectedCategoryId == cat.category_id) return;
              setState(() {
                _selectedCategoryId = cat.category_id;
                _isLoading = true;
                _currentPage = 1;
                _hasMore = true;
                _studyMaterials = [];
                _searchQuery = '';
                _searchController.clear();
              });
              await fetchStudyCategory(cat.category_id, page: 1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.tealGreen, AppColors.darkNavy])
                    : null,
                color: isSelected ? null : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.greyS600.withOpacity(0.2)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.tealGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: Center(
                child: TranslatedText(
                  cat.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.greyS700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── BODY ─────────────────────────────────────────────────────────

  Widget _buildBody() {
    final items = _filteredMaterials;

    if (_searchQuery.trim().isNotEmpty && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.greyS600.withOpacity(0.4)),
            const SizedBox(height: 16),
            TranslatedText('No results for "$_searchQuery"',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyS600)),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        final max = scrollInfo.metrics.maxScrollExtent;
        if (max > 0 &&
            scrollInfo.metrics.pixels >= max - 300 &&
            !_isLoadingMore &&
            _hasMore &&
            _searchQuery.trim().isEmpty) {
          _loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridCard(items[index]),
                childCount: items.length,
              ),
            ),
          ),

          if (isBannerLoaded &&
              bannerService.bannerAd != null &&
              _searchQuery.trim().isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: bannerService.bannerAd!.size.height.toDouble(),
                    width: double.infinity,
                    child: AdWidget(ad: bannerService.bannerAd!),
                  ),
                ),
              ),
            ),

          if (_searchQuery.trim().isEmpty)
            SliverToBoxAdapter(
              child: _isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()))
                  : !_hasMore
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.tealGreen.withOpacity(0.6)),
                                const SizedBox(width: 6),
                                const TranslatedText('All courses loaded',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(height: 80),
            ),
        ],
      ),
    );
  }

  // ─── GRID CARD ────────────────────────────────────────────────────

  Widget _buildGridCard(StudyMaterialItem material) {
  final bool hasIcon =
      material.boardIcon != null && material.boardIcon!.isNotEmpty;

  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuyCoursePage(
            contentId: material.id, page_API_call: 'SUBSCRIPTION'),
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ─────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: hasIcon
                      ? Image.network(
                          material.boardIcon!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildGradientFallback(material.title),
                        )
                      : _buildGradientFallback(material.title),
                ),
                // Bottom fade
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
                // Badge top-right
                Positioned(
                  top: 7, right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: material.is_purchased == 1
                          ? AppColors.tealGreen
                          : const Color(0xFF0D4B3B),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 5)
                      ],
                    ),
                    child: Text(
                      material.is_purchased == 1 ? 'Continue' : 'Enroll Now',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Title + Description + Button ──────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TranslatedText(
                    material.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Expanded(
                    child: TranslatedText(
                      material.description,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.greyS600,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Single Button ─────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuyCoursePage(
                          contentId: material.id,
                          page_API_call: 'SUBSCRIPTION',
                        ),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: material.is_purchased == 1
                              ? [AppColors.tealGreen, AppColors.darkNavy]
                              : [AppColors.darkNavy, const Color(0xFF0D4B3B)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkNavy.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: TranslatedText(
                          material.is_purchased == 1
                              ? 'Continue'
                              : 'Enroll Now',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  // ─── GRADIENT FALLBACK ────────────────────────────────────────────

  Widget _buildGradientFallback(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(title),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: -10, bottom: -10,
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle),
            ),
          ),
          Center(
            child: Icon(Icons.school_rounded,
                size: 40, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: AppColors.tealGreen.withOpacity(0.08),
                shape: BoxShape.circle),
            child: Icon(Icons.library_books_outlined,
                size: 56, color: AppColors.greyS600.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          TranslatedText('No courses found',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyS600)),
          const SizedBox(height: 6),
          TranslatedText('Try selecting a different category',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.greyS600.withOpacity(0.6))),
        ],
      ),
    );
  }

  // ─── GRADIENT COLORS ──────────────────────────────────────────────

  List<Color> _getGradientColors(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return [AppColors.darkNavy, AppColors.tealGreen];
    if (s.contains('science')) return [AppColors.tealGreen, const Color(0xFF0D6B55)];
    if (s.contains('physics')) return [const Color(0xFF1a237e), AppColors.darkNavy];
    if (s.contains('chemistry')) return [AppColors.tealGreen, AppColors.darkNavy];
    if (s.contains('english')) return [AppColors.darkNavy, const Color(0xFF1B5E20)];
    if (s.contains('bihar') || s.contains('board'))
      return [const Color(0xFF1a237e), AppColors.darkNavy];
    if (s.contains('railway') || s.contains('rrb'))
      return [const Color(0xFF0D47A1), AppColors.darkNavy];
    if (s.contains('bank') || s.contains('sbi') || s.contains('ibps'))
      return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
    if (s.contains('police')) return [const Color(0xFF4A148C), AppColors.darkNavy];
    if (s.contains('bpsc') || s.contains('upsc'))
      return [const Color(0xFF880E4F), AppColors.darkNavy];
    return [AppColors.darkNavy, AppColors.tealGreen];
  }
}