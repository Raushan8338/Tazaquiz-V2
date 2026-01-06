import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/models/study_category_item.dart';
import 'package:tazaquiznew/models/study_material_details_item.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/utils/richText.dart';

class SubjectContentPage extends StatefulWidget {
  final String id;
  SubjectContentPage(this.id);

  @override
  _SubjectContentPageState createState() => _SubjectContentPageState();
}

class _SubjectContentPageState extends State<SubjectContentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String subjectName = '';

  List<CategoryItem> _categoryItems = [];
  int _selectedCategoryId = 0;

  List<StudyMaterialDetailsItem> _studyMaterials_new = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchStudyLevels();
    fetchStudyCategory(0);
  }

  Future<void> fetchStudyLevels() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'categoryId': widget.id};
    print(data);
    Response response = await authRepository.fetchStudySubjectCategory(data);
    print(response.data);

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

  Future<List<StudyMaterialDetailsItem>> fetchStudyCategory(int categoryId) async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {
      'subject_id': categoryId.toString(), // Example level ID
    };

    final responseFuture = await authRepository.fetchStudyMaterialsDetails(data);
    print(responseFuture.statusCode);
    if (responseFuture.statusCode == 200) {
      final responseData = responseFuture.data;

      final List list = responseData['data'] ?? [];

      _studyMaterials_new = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();

      return _studyMaterials_new;
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
      expandedHeight: 80,
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
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title in single line
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.arrow_back, color: AppColors.white, size: 18),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
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
                ],
              ),
            ),
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
          print(category.name);

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
                _studyMaterials_new = data;
                subjectName = category.name;
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

  Widget _buildMaterialsList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }

    if (_studyMaterials_new.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Text('No study material found')));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final material = _studyMaterials_new[index];
        return _buildMaterialCard(material);
      }, childCount: _studyMaterials_new.length),
    );
  }

  Widget _buildMaterialCard(StudyMaterialDetailsItem material) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectContentPage()));
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
                  colors: _getGradientColors(subjectName),
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
                  Center(
                    child: Icon(
                      material.contentType == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_filled,
                      size: 50,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        if (material.isPaid)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium, size: 12, color: AppColors.tealGreen),
                                SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tealGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                          child: Icon(Icons.bookmark_outline, color: AppColors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        material.contentType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getSubjectColor(subjectName),
                        ),
                      ),
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
                          subjectName,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tealGreen),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.person_outline, size: 13, color: AppColors.greyS500),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          material.author,
                          style: TextStyle(fontSize: 11, color: AppColors.greyS600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _buildInfoChip(Icons.insert_drive_file, material.contentType == 'PDF' ? '2 pages' : '30'),
                      SizedBox(width: 10),
                      _buildInfoChip(Icons.file_download, material.size),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber[700]),
                            SizedBox(width: 3),
                            Text(
                              '${material.rating}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Single Preview button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        material.isPaid ? Icons.lock_outline : Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.white,
                      ),
                      label: Text(
                        material.isPaid ? 'Unlock to Preview' : 'Preview',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ).decorated(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              material.isPaid
                                  ? [AppColors.darkNavy, AppColors.tealGreen]
                                  : [AppColors.tealGreen, AppColors.darkNavy],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Updated ${material.createdAt}', style: TextStyle(fontSize: 10, color: AppColors.greyS500)),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.tealGreen),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.greyS700)),
      ],
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

  void _previewMaterial(Map<String, dynamic> material) {
    if (material['isPremium']) {
      _showPremiumDialog();
    } else {
      _showPreviewDialog(material);
    }
  }

  void _showPreviewDialog(Map<String, dynamic> material) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _getGradientColors(material['subject'])),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      material['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_filled,
                      size: 40,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    material['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Preview feature coming soon!',
                    style: TextStyle(fontSize: 13, color: AppColors.greyS600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.transparent,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Text(
                          'Close',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
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

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.workspace_premium, size: 40, color: AppColors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Premium Content',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Upgrade to Pro to access this material',
                    style: TextStyle(fontSize: 13, color: AppColors.greyS600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.greyS300),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.greyS700),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.transparent,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              child: Text(
                                'Upgrade',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

extension WidgetExtension on Widget {
  Widget decorated({required BoxDecoration decoration}) {
    return DecoratedBox(decoration: decoration, child: this);
  }
}
