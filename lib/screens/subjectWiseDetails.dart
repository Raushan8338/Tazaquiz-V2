import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/models/study_category_item.dart';
import 'package:tazaquiznew/models/study_material_details_item.dart';
import 'package:tazaquiznew/screens/PDFViewerPage.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/screens/studyMaterial.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectContentPage extends StatefulWidget {
  final String id;
  SubjectContentPage(this.id);

  @override
  _SubjectContentPageState createState() => _SubjectContentPageState();
}

class _SubjectContentPageState extends State<SubjectContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // FIX: _isLoading starts true, only false after data is ready
  bool _isLoading = true;
  String subjectName = '';

  List<CategoryItem> _categoryItems = [];
  int _selectedCategoryId = 0;

  List<Map<String, dynamic>> _topics = [];
  bool _isFetchingTopics = false;
  int _selectedTopicId = 0;
  String _selectedTopicName = 'All Topics';

  List<StudyMaterialDetailsItem> _studyMaterials_new = [];
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    getdata();
  }

  Future<void> getdata() async {
    if (mounted) setState(() => _isLoading = true);

    _user = await SessionManager.getUser();

    // 1. Fetch categories (without "All")
    await fetchStudyLevels();

    // 2. Auto-select first real category
    if (_categoryItems.isNotEmpty) {
      _selectedCategoryId = _categoryItems.first.category_id;
      subjectName = _categoryItems.first.name;

      // 3. Fetch topics and materials together for first category
      await Future.wait([
        fetchTopics(_selectedCategoryId),
        fetchStudyCategory(_selectedCategoryId),
      ]);
    }

    // 4. Only NOW set loading false
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchStudyLevels() async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'categoryId': widget.id};
      Response response = await authRepository.fetchStudySubjectCategory(data);

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        // FIX: No "All" item — sirf real categories
        if (mounted) {
          setState(() {
            _categoryItems =
                list.map((e) => CategoryItem.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('fetchStudyLevels error: $e');
    }
  }


  Future<void> fetchTopics(int subjectId) async {
    if (mounted) {
      setState(() {
        _topics = [];
        _selectedTopicId = 0;
        _selectedTopicName = 'All Topics';
        _isFetchingTopics = true;
      });
    }
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

        if (mounted) {
          setState(() {
            _topics = [
              {'id': 0, 'name': 'All Topics'},
              ...topics,
            ];
            _selectedTopicId = 0;
            _selectedTopicName = 'All Topics';
            _isFetchingTopics = false;
          });
        }
      } else {
        if (mounted) setState(() => _isFetchingTopics = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingTopics = false);
    }
  }

  Future<void> fetchStudyCategory(int categoryId, {int topicId = 0}) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'subject_id': categoryId.toString(),
        'category_id': widget.id,
        'user_id': _user!.id.toString(),
        if (topicId != 0) 'topic_id': topicId.toString(),
      };
      print('fetchStudyCategory data: $data');

      final responseFuture =
          await authRepository.fetch_non_paid_materials(data);

      if (responseFuture.statusCode == 200) {
        final List list = responseFuture.data['data'] ?? [];
        _studyMaterials_new =
            list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();
      } else {
        _studyMaterials_new = [];
      }
    } catch (e) {
      debugPrint('fetchStudyCategory error: $e');
      _studyMaterials_new = [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCategoriesSection()),
          // Topics row: sirf tab dikhe jab category select ho aur topics ho
          if (!_isLoading && _selectedCategoryId != 0 && _topics.isNotEmpty)
            SliverToBoxAdapter(child: _buildTopicSelectorRow()),
          _buildMaterialsList(),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 70,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back,
                          color: AppColors.white, size: 18),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TranslatedText(
                      'Study Materials',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_categoryItems.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 12),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categoryItems.length,
        itemBuilder: (context, index) {
          final category = _categoryItems[index];
          bool isSelected = _selectedCategoryId == category.category_id;

          return GestureDetector(
            onTap: () async {
              if (_selectedCategoryId == category.category_id) return;

              setState(() {
                _selectedCategoryId = category.category_id;
                subjectName = category.name;
                _selectedTopicId = 0;
                _selectedTopicName = 'All Topics';
                _topics = [];
                // FIX: loading true, list clear — no "no data" flash
                _isLoading = true;
                _studyMaterials_new = [];
              });

              // Fetch topics and materials at the same time
              await Future.wait([
                fetchTopics(category.category_id),
                fetchStudyCategory(category.category_id),
              ]);

              if (!mounted) return;
              setState(() => _isLoading = false);
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColors.tealGreen, AppColors.darkNavy])
                    : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.tealGreen.withOpacity(0.3)
                        : AppColors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 10 : 5,
                    offset: Offset(0, isSelected ? 3 : 2),
                  ),
                ],
              ),
              child: Center(
                child: TranslatedText(
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

  Widget _buildTopicSelectorRow() {
    final bool hasTopicSelected = _selectedTopicId != 0;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: _isFetchingTopics ? null : _showTopicBottomSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: hasTopicSelected
                ? AppColors.tealGreen.withOpacity(0.07)
                : const Color(0xFFF0F2F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasTopicSelected
                  ? AppColors.tealGreen.withOpacity(0.4)
                  : AppColors.greyS600.withOpacity(0.2),
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasTopicSelected
                    ? AppColors.tealGreen.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.menu_book_rounded,
                  size: 16,
                  color: hasTopicSelected
                      ? AppColors.tealGreen
                      : AppColors.greyS600),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Topic / Chapter',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.greyS600,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins')),
                    Text(
                      _isFetchingTopics
                          ? 'Loading topics...'
                          : _selectedTopicName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: hasTopicSelected
                            ? AppColors.tealGreen
                            : AppColors.darkNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
            ),
            _isFetchingTopics
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.tealGreen)))
                : Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: hasTopicSelected
                        ? AppColors.tealGreen
                        : AppColors.greyS600),
          ]),
        ),
      ),
    );
  }

  void _showTopicBottomSheet() {
    if (_topics.isEmpty) return;
    int tempTopicId = _selectedTopicId;
    String tempTopicName = _selectedTopicName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF0A1628),
                                Color(0xFF0D4B3B)
                              ]),
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
                        if (_topics.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.tealGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('${_topics.length} topics',
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
                      Text('Choose a topic to filter materials',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.greyS600)),
                      const SizedBox(height: 14),
                    ]),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.48),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    final int tId = topic['id'] as int;
                    final String tName = topic['name'] as String;
                    final bool sel = tempTopicId == tId;
                    return GestureDetector(
                      onTap: () => setModalState(() {
                        tempTopicId = tId;
                        tempTopicName = tName;
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
                              color: sel
                                  ? AppColors.tealGreen
                                  : Colors.transparent,
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
                                color: sel
                                    ? AppColors.tealGreen
                                    : AppColors.greyS600,
                                size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(tName,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Poppins',
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
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
                  onTap: () async {
                    setState(() {
                      _selectedTopicId = tempTopicId;
                      _selectedTopicName = tempTopicName;
                      // FIX: Show loading when topic filter applied
                      _isLoading = true;
                      _studyMaterials_new = [];
                    });
                    Navigator.pop(context);

                    await fetchStudyCategory(_selectedCategoryId,
                        topicId: tempTopicId);

                    if (mounted) setState(() => _isLoading = false);
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

  Widget _buildMaterialsList() {
    // FIX: Spinner dikhao jab tak load ho — "No data" kabhi flash nahi hoga
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.tealGreen),
          ),
        ),
      );
    }

    if (_studyMaterials_new.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_rounded,
                  size: 56, color: AppColors.greyS500),
              SizedBox(height: 12),
              TranslatedText(
                'No study material found',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.greyS600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final material = _studyMaterials_new[index];
          return _buildMaterialCard(material);
        },
        childCount: _studyMaterials_new.length,
      ),
    );
  }

  Widget _buildMaterialCard(StudyMaterialDetailsItem material) {
    final bool hasImage =
        material.filePath != null && material.filePath!.isNotEmpty;

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 6),
                spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              child: Stack(
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        material.thumbnail,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildGradientBackground(subjectName),
                      ),
                    )
                  else
                    _buildGradientBackground(subjectName),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.4)
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.15),
                          shape: BoxShape.circle),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.1),
                          shape: BoxShape.circle),
                    ),
                  ),

                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Icon(
                        material.contentType.toString().toUpperCase() == 'PDF'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 48,
                        color: AppColors.white,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (material.isPaid)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded,
                                    size: 14, color: Colors.amber[700]),
                                SizedBox(width: 4),
                                TranslatedText(
                                  'PREMIUM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber[800],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            material.contentType.toString().toUpperCase() ==
                                    'PDF'
                                ? Icons.description_rounded
                                : Icons.videocam_rounded,
                            size: 14,
                            color: _getSubjectColor(subjectName),
                          ),
                          SizedBox(width: 4),
                          TranslatedText(
                            material.contentType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _getSubjectColor(subjectName),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    material.title,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkNavy,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            _getSubjectColor(subjectName).withOpacity(0.1),
                        backgroundImage: material.profile_icon.isNotEmpty
                            ? NetworkImage(material.profile_icon)
                            : null,
                        child: material.profile_icon.isEmpty
                            ? Icon(Icons.account_circle,
                                size: 18,
                                color: _getSubjectColor(subjectName))
                            : null,
                        onBackgroundImageError:
                            material.profile_icon.isNotEmpty
                                ? (exception, stackTrace) {}
                                : null,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: TranslatedText(
                          material.coaching_name,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.greyS600,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  AppRichText.setTextPoppinsStyle(
                    context,
                    material.description ?? '',
                    13,
                    AppColors.darkNavy,
                    FontWeight.normal,
                    3,
                    TextAlign.left,
                    0.0,
                  ),

                  SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.darkNavy, AppColors.tealGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.darkNavy.withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (material.is_premium == 0 &&
                              material.isAccessible == false) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyCoursePage(
                                  contentId: material.materialId.toString(),
                                  page_API_call: 'STUDY',
                                ),
                              ),
                            );
                          } else {
                            if (material.contentType != 'Video') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PDFViewerPage(
                                      pdfUrl: material.filePath,
                                      title: material.title),
                                ),
                              );
                            } else {
                              launchUrl(Uri.parse(material.filePath));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_rounded,
                                size: 20, color: AppColors.white),
                            SizedBox(width: 8),
                            TranslatedText(
                              (material.isAccessible == true)
                                  ? 'Start Learning'
                                  : (material.is_premium == 0)
                                      ? 'SUBSCRIBE NOW'
                                      : 'Start Learning',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.greyS500),
                      SizedBox(width: 4),
                      TranslatedText(
                        'Updated ${material.createdAt}',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.greyS500,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground(String subject) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(subject),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  List<Color> _getGradientColors(String subject) {
    switch (subject) {
      case 'Mathematics':
        return [AppColors.darkNavy, AppColors.tealGreen];
      case 'Science':
        return [AppColors.tealGreen, AppColors.greenS2];
      case 'Physics':
        return [AppColors.oxfordBlue, AppColors.darkNavy];
      case 'Chemistry':
        return [AppColors.tealGreen, AppColors.darkNavy];
      case 'English':
        return [AppColors.darkNavy, AppColors.oxfordBlue];
      default:
        return [AppColors.tealGreen, AppColors.darkNavy];
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return AppColors.darkNavy;
      case 'Science':
        return AppColors.tealGreen;
      case 'Physics':
        return AppColors.oxfordBlue;
      case 'Chemistry':
        return AppColors.tealGreen;
      case 'English':
        return AppColors.darkNavy;
      default:
        return AppColors.tealGreen;
    }
  }
}