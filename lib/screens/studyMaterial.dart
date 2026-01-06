import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/models/study_category_item.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/utils/richText.dart';

class StudyMaterialScreen extends StatefulWidget {
  @override
  _StudyMaterialScreenState createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CategoryItem> _categoryItems = [];
  int _selectedCategoryId = 0;

  bool _isLoading = true;
  List<StudyMaterialItem> _studyMaterials = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchStudyLevels();
    fetchStudyCategory(0);
  }

  Future<void> fetchStudyLevels() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    Response response = await authRepository.fetchStudyLevels();

    if (response.statusCode == 200) {
      final data = response.data; // 👈 JSON yahan hota hai

      final List list = data['data'] ?? [];

      setState(() {
        _categoryItems = [
          CategoryItem(category_id: 0, name: 'All'),
          ...list.map((e) => CategoryItem.fromJson(e)).toList(),
        ];
        _isLoading = false;
      });
    }
  }

  Future<List<StudyMaterialItem>> fetchStudyCategory(int categoryId) async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {
      'category_id': categoryId.toString(), // Example level ID
    };
    final responseFuture = await authRepository.fetchStudyCategory(data);
    print(responseFuture.statusCode);
    if (responseFuture.statusCode == 200) {
      final responseData = responseFuture.data;

      final List list = responseData['data'] ?? [];

      _studyMaterials = list.map((e) => StudyMaterialItem.fromJson(e)).toList();

      return _studyMaterials;
    } else {
      return []; // return empty list if failed
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
          _buildMaterialsList(),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 90,
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
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title in single line
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.library_books, color: AppColors.white, size: 28),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Study Materials',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                fontFamily: 'Poppins',
                              ),
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

  Widget _buildCategoriesSection() {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 16),
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categoryItems.length,
        itemBuilder: (context, index) {
          final category = _categoryItems[index];

          bool isSelected = _selectedCategoryId == category.category_id;

          return GestureDetector(
            onTap: () async {
              setState(() {
                _selectedCategoryId = category.category_id;
                _isLoading = true;
              });

              final data = await fetchStudyCategory(category.category_id);
              if (!mounted) return;

              setState(() {
                _studyMaterials = data;
                _isLoading = false;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppColors.tealGreen.withOpacity(0.3) : AppColors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 12 : 6,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _categoryItems[index].name,
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

  Widget _buildMaterialsList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }

    if (_studyMaterials.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Text('No study material found')));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final material = _studyMaterials[index];
        return _buildMaterialCard(material);
      }, childCount: _studyMaterials.length),
    );
  }

  Widget _buildMaterialCard(StudyMaterialItem material) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectContentPage(material.id)));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header Image Section
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(material.title),
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tealGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          material.description,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tealGreen),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.person_outline, size: 13, color: AppColors.greyS500),
                      SizedBox(width: 4),
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
}

extension WidgetExtension on Widget {
  Widget decorated({required BoxDecoration decoration}) {
    return DecoratedBox(decoration: decoration, child: this);
  }
}
