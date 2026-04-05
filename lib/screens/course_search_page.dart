import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USAGE:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const StudyMaterialSearchScreen()));
// ─────────────────────────────────────────────────────────────────────────────

class StudyMaterialSearchScreen extends StatefulWidget {
  const StudyMaterialSearchScreen({Key? key}) : super(key: key);

  @override
  State<StudyMaterialSearchScreen> createState() => _StudyMaterialSearchScreenState();
}

class _StudyMaterialSearchScreenState extends State<StudyMaterialSearchScreen> with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // ── State ──────────────────────────────────────────────────────────
  List<StudyMaterialItem> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  // ── Debounce ───────────────────────────────────────────────────────
  Timer? _debounce;

  // ── Animation ─────────────────────────────────────────────────────
  late AnimationController _listAnimCtrl;
  late Animation<double> _listFade;

  @override
  void initState() {
    super.initState();
    _listAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _listFade = CurvedAnimation(parent: _listAnimCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _listAnimCtrl.dispose();
    super.dispose();
  }

  // ── Debounced search ───────────────────────────────────────────────
  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isLoading = false;
        _lastQuery = '';
      });
      _listAnimCtrl.reset();
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 420), () {
      _fetchResults(value.trim());
    });
  }

  // ── API call — same structure, search param added ──────────────────
  Future<void> _fetchResults(String query) async {
    if (query == _lastQuery && _results.isNotEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    _lastQuery = query;

    try {
      final Authrepository repo = Authrepository(Api_Client.dio);
      final Response response = await repo.fetchStudyCategory({
        'category_id': 0,
        'page': 1,
        'limit': 100, // search mode → bada limit, no pagination
        'search': query, // ← PHP API mein yeh param add kiya gaya hai
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List raw = response.data['data'] ?? [];

        // Client-side fallback filter (agar backend search na kare)
        final q = query.toLowerCase();
        final items =
            raw
                .map((e) => StudyMaterialItem.fromJson(e))
                .where((e) => e.title.toLowerCase().contains(q) || e.description.toLowerCase().contains(q))
                .toList();

        setState(() {
          _results = items;
          _hasSearched = true;
          _isLoading = false;
        });
        _listAnimCtrl
          ..reset()
          ..forward();
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.requestFocus();
    setState(() {
      _results = [];
      _hasSearched = false;
      _isLoading = false;
      _lastQuery = '';
    });
    _listAnimCtrl.reset();
  }

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(backgroundColor: const Color(0xFFF6F7FB), appBar: _buildAppBar(), body: _buildBody()),
    );
  }

  // ── AppBar with embedded search ────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(66),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.darkNavy),
                  ),
                ),
                const SizedBox(width: 10),

                // Search field
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _focusNode.hasFocus ? AppColors.tealGreen.withOpacity(0.5) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    key: const ValueKey('ld'),
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(AppColors.tealGreen),
                                    ),
                                  )
                                  : Icon(
                                    key: const ValueKey('ic'),
                                    Icons.search_rounded,
                                    size: 18,
                                    color: Colors.grey.shade400,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: _onChanged,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(color: AppColors.darkNavy, fontSize: 14, fontWeight: FontWeight.w500),
                            cursorColor: AppColors.tealGreen,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              hintText: 'Search courses...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearSearch,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
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
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (!_hasSearched && !_isLoading) return _buildIdleState();
    if (_isLoading && _results.isEmpty) return _buildShimmer();
    if (_hasSearched && _results.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result count chip
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tealGreen.withOpacity(0.25)),
                ),
                child: TranslatedText(
                  '${_results.length} result${_results.length == 1 ? '' : 's'}',
                  style: TextStyle(color: AppColors.tealGreen, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: TranslatedText(
                  'for "${_searchController.text}"',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: FadeTransition(
            opacity: _listFade,
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _results.length,
              itemBuilder: (context, index) => _buildCard(_results[index], index),
            ),
          ),
        ),
      ],
    );
  }

  // ── Idle state ─────────────────────────────────────────────────────
  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.auto_stories_rounded, size: 34, color: AppColors.tealGreen),
          ),
          const SizedBox(height: 18),
          TranslatedText(
            'Find your course',
            style: TextStyle(color: AppColors.darkNavy, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            'Type above to search from\nour complete course library',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.6),
          ),
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
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          TranslatedText(
            'No courses found',
            style: TextStyle(color: AppColors.darkNavy, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TranslatedText('Try a different keyword', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Shimmer skeleton ───────────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 5,
      itemBuilder:
          (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 86,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimBox(140, 12),
                      const SizedBox(height: 8),
                      _shimBox(100, 10),
                      const SizedBox(height: 6),
                      _shimBox(120, 10),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
    );
  }

  Widget _shimBox(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
  );

  // ── Course card ────────────────────────────────────────────────────
  Widget _buildCard(StudyMaterialItem material, int index) {
    final bool hasIcon = material.boardIcon != null && material.boardIcon!.isNotEmpty;
    final accent = _accent(index);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BuyCoursePage(contentId: material.id, page_API_call: 'SUBSCRIPTION')),
          ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + (index * 40).clamp(0, 300)),
        curve: Curves.easeOut,
        builder:
            (_, v, child) =>
                Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child:
                      hasIcon
                          ? Image.network(
                            material.boardIcon!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _gradientThumb(accent),
                          )
                          : _gradientThumb(accent),
                ),
              ),

              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        material.title,
                        style: TextStyle(
                          color: AppColors.darkNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      TranslatedText(
                        material.description,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientThumb(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(Icons.school_rounded, size: 30, color: Colors.white.withOpacity(0.9))),
    );
  }

  // ── Accent colors ──────────────────────────────────────────────────
  Color _accent(int i) {
    const list = [
      Color(0xFF0D9488),
      Color(0xFF6366F1),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
    ];
    return list[i % list.length];
  }
}
