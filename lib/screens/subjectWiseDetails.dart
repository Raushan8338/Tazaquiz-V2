import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

class _SubjectContentPageState extends State<SubjectContentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String subjectName = '';
  bool _bookmarkLoading = false;

  List<CategoryItem> _categoryItems = [];
  int _selectedCategoryId = 0;

  List<StudyMaterialDetailsItem> _studyMaterials_new = [];
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    getdata();
  }

  Future<void> getdata() async {
    _user = await SessionManager.getUser();

    // 1️⃣ Pehle levels lao
    await fetchStudyLevels();

    // 2️⃣ Default category set karo
    _selectedCategoryId = 0;

    // 3️⃣ Ab category ka data lao
    await fetchStudyCategory(_selectedCategoryId);

    // 4️⃣ Sab kuch ke baad UI update
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> fetchStudyLevels() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'categoryId': widget.id};

    Response response = await authRepository.fetchStudySubjectCategory(data);

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

  Future<List<StudyMaterialDetailsItem>> fetchStudyCategory(int categoryId) async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'subject_id': categoryId.toString(), 'category_id': widget.id, 'user_id': _user!.id.toString()};
    print(data);

    final responseFuture = await authRepository.fetch_non_paid_materials(data);

    if (responseFuture.statusCode == 200) {
      final responseData = responseFuture.data;

      final List list = responseData['data'] ?? [];

      _studyMaterials_new = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();

      return _studyMaterials_new;
    } else {
      return [];
    }
  }

  // Future<void> saveBookmark(int materialid) async {
  //   Authrepository authRepository = Authrepository(Api_Client.dio);
  //   final data = {
  //     'action': categoryId.toString(),
  //     'user_id': widget.id,
  //     'content_type': materialid,
  //     'content_id': widget.id,
  //   };
  //   print(data);

  //   final responseFuture = await authRepository.save_bookmark_data(data);

  //   if (responseFuture.statusCode == 200) {
  //     final responseData = responseFuture.data;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(responseData["status"] == "success" ? "Bookmark added" : "Bookmark failed")),
  //     );
  //   } else {}
  //   if (!mounted) return;

  //   setState(() {
  //     _bookmarkLoading = false;
  //   });
  // }

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
    // Check if material has an image URL (add this property to your model if needed)
    final bool hasImage = material.filePath != null && material.filePath!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectContentPage()));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 6), spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            // Enhanced Header Section with Image or Gradient
            Container(
              height: 140,
              decoration: BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Stack(
                children: [
                  // Background - Either Image or Gradient
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        material.thumbnail,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildGradientBackground(subjectName);
                        },
                      ),
                    )
                  else
                    _buildGradientBackground(subjectName),

                  // Dark overlay for better readability
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.4)],
                      ),
                    ),
                  ),

                  // Decorative circles
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.15), shape: BoxShape.circle),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                    ),
                  ),

                  // Center Icon with animated effect
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.black.withOpacity(0.2), blurRadius: 15, offset: Offset(0, 4)),
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

                  // Top badges
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (material.isPaid)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber[700]),
                                SizedBox(width: 4),
                                Text(
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
                        // IconButton(
                        //   icon: Icon(Icons.bookmark, size: 14, color: Colors.amber[700]),
                        //   onPressed: () => saveBookmark(material.materialId),
                        // ),
                      ],
                    ),
                  ),

                  // Bottom content type badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: AppColors.black.withOpacity(0.15), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            material.contentType.toString().toUpperCase() == 'PDF'
                                ? Icons.description_rounded
                                : Icons.videocam_rounded,
                            size: 14,
                            color: _getSubjectColor(subjectName),
                          ),
                          SizedBox(width: 4),
                          Text(
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

            // Enhanced Content Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    material.title,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkNavy, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),

                  // Subject and Author Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getSubjectColor(subjectName).withOpacity(0.15),
                              _getSubjectColor(subjectName).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _getSubjectColor(subjectName),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.person_outline_rounded, size: 14, color: AppColors.greyS500),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          material.coaching_name,
                          style: TextStyle(fontSize: 11, color: AppColors.greyS600, fontWeight: FontWeight.w500),
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

                  // Info chips row
                  // Row(
                  //   children: [
                  //     _buildEnhancedInfoChip(
                  //       Icons.insert_drive_file_rounded,
                  //       material.contentType.toString().toUpperCase() == 'PDF' ? '2 pages' : '30 min',
                  //     ),
                  //     SizedBox(width: 10),
                  //     _buildEnhancedInfoChip(Icons.file_download_rounded, material.size),
                  //     Spacer(),
                  //     Container(
                  //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  //       decoration: BoxDecoration(
                  //         gradient: LinearGradient(
                  //           colors: [Colors.amber.withOpacity(0.2), Colors.amber.withOpacity(0.1)],
                  //         ),
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       child: Row(
                  //         children: [
                  //           Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                  //           SizedBox(width: 3),
                  //           Text(
                  //             '${material.rating}',
                  //             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  SizedBox(height: 14),

                  // Action Buttons - Enhanced for Paid Content
                  if (material.is_premium == 1)
                    Row(
                      children: [
                        // Price Display
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.tealGreen.withOpacity(0.15), AppColors.tealGreen.withOpacity(0.08)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.tealGreen.withOpacity(0.3), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.tealGreen,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '${material.price ?? '0.0'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.darkNavy,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),

                        // Enroll Now Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => BuyCoursePage(
                                        contentId: material.materialId.toString(),
                                        page_API_call: 'STUDY',
                                      ),
                                ),
                              );

                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder:
                              //         (context) =>
                              //             CheckoutPage(contentType: 'STUDY', contentId: material.materialId.toString()),
                              //   ),
                              // );

                              // Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutPage()));
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
                                Icon(Icons.shopping_bag_rounded, size: 18, color: AppColors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Enroll Now',
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
                                BoxShadow(
                                  color: AppColors.tealGreen.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Free Preview Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (material.is_premium == 0 && material.isAccessible == false) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BuyCoursePage(
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
                                  builder: (context) => PDFViewerPage(pdfUrl: material.filePath, title: material.title),
                                ),
                              );
                            } else {
                              launchUrl(Uri.parse(material.filePath));
                            }
                          }
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
                            Icon(Icons.play_circle_rounded, size: 20, color: AppColors.white),
                            SizedBox(width: 8),
                            Text(
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
                      ).decorated(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.darkNavy, AppColors.tealGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.darkNavy.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 10),

                  // Updated date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AppColors.greyS500),
                          SizedBox(width: 4),
                          Text(
                            'Updated ${material.createdAt}',
                            style: TextStyle(fontSize: 10, color: AppColors.greyS500, fontWeight: FontWeight.w500),
                          ),
                        ],
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

  Widget _buildEnhancedInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.tealGreen),
          SizedBox(width: 5),
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
