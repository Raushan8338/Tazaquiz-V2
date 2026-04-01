import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/ads/banner_ads_helper.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/models/study_category_item.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';

class StudyMaterialScreen extends StatefulWidget {
  String pageId;
  StudyMaterialScreen(this.pageId, {Key? key}) : super(key: key);

  @override
  _StudyMaterialScreenState createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  List<CategoryItem> _categoryItems = [];
  List<StudyMaterialItem> _studyMaterials = [];
  int _selectedCategoryId = 0;
  bool _isLoading = true;

  // ── Pagination ─────────────────────────────────────────────────────
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    bannerService.loadAd(() {
      if (mounted) setState(() => isBannerLoaded = true);
    });
    _getdata();
  }

  @override
  void dispose() {
    bannerService.dispose();
    super.dispose();
  }

  // ── Initial load ───────────────────────────────────────────────────
  Future<void> _getdata() async {
    await fetchStudyLevels();
    await fetchStudyCategory(0, page: 1);
  }

  // ── Load more ──────────────────────────────────────────────────────
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    debugPrint("🔄 Loading more... page ${_currentPage + 1}");
    setState(() => _isLoadingMore = true);
    await fetchStudyCategory(_selectedCategoryId, page: _currentPage + 1);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  // ── Fetch categories (tabs) ────────────────────────────────────────
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

  // ── Fetch study materials (paginated) ─────────────────────────────
  Future<void> fetchStudyCategory(int categoryId, {int page = 1}) async {
    Authrepository authRepository = Authrepository(Api_Client.dio);

    Response response = await authRepository.fetchStudyCategory({'category_id': categoryId, 'page': page, 'limit': 6});

    debugPrint("🌐 Response: ${response.data}");

    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? [];
      final bool hasMore = response.data['hasMore'] ?? false;

      debugPrint("📦 Page: $page | Items: ${list.length} | hasMore: $hasMore");

      if (list.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        if (page == 1) {
          _studyMaterials = list.map((e) => StudyMaterialItem.fromJson(e)).toList();
        } else {
          final existingIds = _studyMaterials.map((e) => e.id).toSet();
          final newItems =
              list.map((e) => StudyMaterialItem.fromJson(e)).where((e) => !existingIds.contains(e.id)).toList();
          _studyMaterials.addAll(newItems);
        }
        _currentPage = page;
        _hasMore = hasMore;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
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
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.library_books, color: Colors.white, size: 18),
                  ),
                ),
        title: const Text(
          'Exam Courses',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
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
        bottom: PreferredSize(preferredSize: const Size.fromHeight(54), child: _buildCategoryTabs()),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)))
              : _studyMaterials.isEmpty
              ? _buildEmptyState()
              : _buildBody(),
    );
  }

  // ── Category tabs ──────────────────────────────────────────────────
  Widget _buildCategoryTabs() {
    return Container(
      height: 54,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              });
              await fetchStudyCategory(cat.category_id, page: 1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
                color: isSelected ? null : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: AppColors.greyS600.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
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

  // ── Body ───────────────────────────────────────────────────────────
  Widget _buildBody() {
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
          // ── All items in single grid ──────────────────────────
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
                (context, index) => _buildGridCard(_studyMaterials[index]),
                childCount: _studyMaterials.length,
              ),
            ),
          ),

          // ── Banner Ad ─────────────────────────────────────────
          if (isBannerLoaded && bannerService.bannerAd != null)
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

          // ── Bottom loader / end message ───────────────────────
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
                        child: Text('✅ All items loaded', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    )
                    : const SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // ── Grid card ──────────────────────────────────────────────────────
  Widget _buildGridCard(StudyMaterialItem material) {
    final bool hasIcon = material.boardIcon != null && material.boardIcon!.isNotEmpty;

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BuyCoursePage(contentId: material.id, page_API_call: 'SUBSCRIPTION'),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 115,
                width: double.infinity,
                child:
                    hasIcon
                        ? Image.network(
                          material.boardIcon!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildGradientFallback(material.title),
                        )
                        : _buildGradientFallback(material.title),
              ),
            ),

            // ── Content ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title — fixed height: fontSize(12) * lineHeight(1.3) * maxLines(2) = 31.2
                    SizedBox(
                      height: 32, // 31.2 ko ceil karke 32 rakha — clean aur safe
                      child: Text(
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
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      material.description,
                      style: TextStyle(fontSize: 11, color: AppColors.greyS600, height: 1),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Spacer remaining space absorb karta hai
                    const Spacer(),

                    // Explore Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Explore',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
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

  // ── Gradient fallback ──────────────────────────────────────────────
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
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
            ),
          ),
          Center(child: Icon(Icons.school_rounded, size: 40, color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: AppColors.greyS600.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No study material found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.greyS600),
          ),
        ],
      ),
    );
  }

  // ── Gradient colors ────────────────────────────────────────────────
  List<Color> _getGradientColors(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return [AppColors.darkNavy, AppColors.tealGreen];
      case 'science':
        return [AppColors.tealGreen, const Color(0xFF0D6B55)];
      case 'physics':
        return [const Color(0xFF1a237e), AppColors.darkNavy];
      case 'chemistry':
        return [AppColors.tealGreen, AppColors.darkNavy];
      case 'english':
        return [AppColors.darkNavy, const Color(0xFF1B5E20)];
      default:
        return [AppColors.darkNavy, AppColors.tealGreen];
    }
  }
}
