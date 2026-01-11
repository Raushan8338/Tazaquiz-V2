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
  String pageId;
  StudyMaterialScreen(this.pageId, {Key? key}) : super(key: key);

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
    getdata();
  }

  getdata() async {
    await fetchStudyLevels();
    await fetchStudyCategory(0);
    setState(() {});
  }

  Future<void> fetchStudyLevels() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    Response response = await authRepository.fetchStudyLevels();

    if (response.statusCode == 200) {
      final data = response.data;

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
    final data = {'category_id': categoryId.toString()};
    final responseFuture = await authRepository.fetchStudyCategory(data);
    print(responseFuture.statusCode);
    if (responseFuture.statusCode == 200) {
      final responseData = responseFuture.data;

      final List list = responseData['data'] ?? [];

      _studyMaterials = list.map((e) => StudyMaterialItem.fromJson(e)).toList();

      return _studyMaterials;
    } else {
      return [];
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
                      Row(
                        children: [
                          (widget.pageId == '1')
                              ? IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                                ),
                                onPressed: () => Navigator.pop(context),
                              )
                              : Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.library_books, color: AppColors.white, size: 22),
                              ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Study Materials',
                              style: TextStyle(
                                fontSize: 16,
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
    // Check if material has a banner/image URL (add this property to your model if needed)
    final bool hasBanner = material.boardIcon != null && material.boardIcon!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Optional: Navigate on card tap
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 6), spreadRadius: 1),
          ],
        ),
        child: Column(
          children: [
            // Enhanced Header Section with Banner or Gradient
            Container(
              height: 160,
              decoration: BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Stack(
                children: [
                  // Background - Either Banner or Gradient
                  if (hasBanner)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        material.boardIcon!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildGradientBackground(material.title);
                        },
                      ),
                    )
                  else
                    _buildGradientBackground(material.title),

                  // Dark overlay for better readability
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                      ),
                    ),
                  ),

                  // Decorative circles
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.12), shape: BoxShape.circle),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.08), shape: BoxShape.circle),
                    ),
                  ),

                  // Popular badge at top right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.orange[600]!, Colors.deepOrange[500]!]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.white),
                          SizedBox(width: 4),
                          Text(
                            'Popular',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center icon/logo - using boardIcon if available
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.black.withOpacity(0.15), blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child:
                          material.boardIcon != null && material.boardIcon!.isNotEmpty
                              ? ClipOval(
                                child: Image.network(
                                  material.boardIcon!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.school_rounded, size: 50, color: AppColors.white);
                                  },
                                ),
                              )
                              : Icon(Icons.school_rounded, size: 50, color: AppColors.white),
                    ),
                  ),

                  // Subject badge at bottom
                  // Positioned(
                  //   bottom: 14,
                  //   left: 14,
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  //     decoration: BoxDecoration(
                  //       color: AppColors.white,
                  //       borderRadius: BorderRadius.circular(12),
                  //       boxShadow: [
                  //         BoxShadow(color: AppColors.black.withOpacity(0.15), blurRadius: 10, offset: Offset(0, 4)),
                  //       ],
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(Icons.category_rounded, size: 16, color: _getSubjectColor(material.title)),
                  //         SizedBox(width: 6),
                  //         Text(
                  //           material.title,
                  //           style: TextStyle(
                  //             fontSize: 12,
                  //             fontWeight: FontWeight.w800,
                  //             color: _getSubjectColor(material.title),
                  //             letterSpacing: 0.3,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            // Enhanced Content Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    material.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkNavy, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),

                  // Description with icon
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.tealGreen.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.tealGreen),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            material.description,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.greyS700,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),

                  // Stats row

                  // Explore Button - Keeping original color
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SubjectContentPage(material.id)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 6),
                          Text(
                            'Explore Content',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ).decorated(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.tealGreen, AppColors.darkNavy],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                    ),

                    // child: ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => SubjectContentPage(material.id)),
                    //     );
                    //   },
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Color(0xFFFF8A80), // Coral/salmon color like in image
                    //     padding: EdgeInsets.symmetric(vertical: 14),
                    //     elevation: 2,
                    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //   ),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       Icon(Icons.check_circle_rounded, size: 18, color: AppColors.white),
                    //       SizedBox(width: 8),
                    //       Text(
                    //         'Explore Content',
                    //         style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                    //       ),
                    //       SizedBox(width: 6),
                    //       Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.white),
                    //     ],
                    //   ),
                    // ),
                  ),
                  SizedBox(height: 10),

                  // Additional info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Updated on ${material.DateTime}',
                            style: TextStyle(fontSize: 11, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Available',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green[700]),
                            ),
                          ],
                        ),
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

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.greyS1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyS300.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.tealGreen),
          SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.greyS700)),
        ],
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

extension WidgetExtension on Widget {
  Widget decorated({required BoxDecoration decoration}) {
    return DecoratedBox(decoration: decoration, child: this);
  }
}
