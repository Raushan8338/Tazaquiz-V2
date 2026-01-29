import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiz/API/api_client.dart';
import 'package:tazaquiz/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiz/constants/app_colors.dart';
import 'package:tazaquiz/models/login_response_model.dart';
import 'package:tazaquiz/models/study_material_details_item.dart';
import 'package:tazaquiz/screens/PDFViewerPage.dart';
import 'package:tazaquiz/screens/Paid_quzes_list.dart';
import 'package:tazaquiz/screens/subjectWiseDetails.dart';
import 'package:tazaquiz/utils/richText.dart';
import 'package:tazaquiz/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyMaterialPurchaseHistoryScreen extends StatefulWidget {
  StudyMaterialPurchaseHistoryScreen();

  @override
  _StudyMaterialPurchaseHistoryScreenState createState() => _StudyMaterialPurchaseHistoryScreenState();
}

class _StudyMaterialPurchaseHistoryScreenState extends State<StudyMaterialPurchaseHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<StudyMaterialDetailsItem> _allStudyMaterials = [];
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    await fetchStudyMaterials(_user!.id);
  }

  Future<void> fetchStudyMaterials(String user_id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': user_id.toString()};

      final responseFuture = await authRepository.fetchStudyMaterialsDetails(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;

        final List list = responseData['data'] ?? [];

        setState(() {
          _allStudyMaterials = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔥 Get subject name from subject_id
  String _getSubjectName(int subjectId) {
    switch (subjectId) {
      case 1:
        return 'Mathematics';
      case 2:
        return 'Science';
      case 3:
        return 'Physics';
      case 4:
        return 'Chemistry';
      case 5:
        return 'English';
      default:
        return 'General';
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
        slivers: [_buildAppBar(), _buildMaterialsList(), SliverToBoxAdapter(child: SizedBox(height: 20))],
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
                          child: Icon(Icons.arrow_back, color: AppColors.white, size: 16),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Study Materials',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (!_isLoading)
                              Text(
                                '${_allStudyMaterials.length} item${_allStudyMaterials.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.white.withOpacity(0.8),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                          ],
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

  Widget _buildMaterialsList() {
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)),
          ),
        ),
      );
    }

    if (_allStudyMaterials.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.tealGreen.withOpacity(0.1), AppColors.darkNavy.withOpacity(0.05)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.greyS400),
                ),
                SizedBox(height: 24),
                Text(
                  'No Study Materials',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                ),
                SizedBox(height: 12),
                Text(
                  'No study materials available at the moment',
                  style: TextStyle(fontSize: 14, color: AppColors.greyS600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final material = _allStudyMaterials[index];

        return _buildMaterialCard(material);
      }, childCount: _allStudyMaterials.length),
    );
  }

  Widget _buildMaterialCard(StudyMaterialDetailsItem material) {
    // Get subject name from subject_id
    final String subjectName = _getSubjectName(material.subjectId);
    final bool hasImage = material.thumbnail.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (material.contentType != 'Video') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PDFViewerPage(pdfUrl: material.filePath, title: material.title)),
          );
        } else {
          launchUrl(Uri.parse(material.filePath));
        }
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

                  // Top badges - Conditional badge based on purchase status
                  if (material.isPurchased)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.black.withOpacity(0.15), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: AppColors.tealGreen),
                            SizedBox(width: 4),
                            Text(
                              'PURCHASED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tealGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
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
                    material.description,
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
                    child:
                        material.contentType == 'SUBSCRIPTION'
                            ? Row(
                              children: [
                                // Quiz Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Paid_QuizListScreen(material.materialId.toString()),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppColors.tealGreen, AppColors.tealGreen.withOpacity(0.85)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.tealGreen.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.quiz_rounded, size: 28, color: AppColors.white),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Quiz',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Material Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SubjectContentPage(material.materialId.toString()),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppColors.darkNavy, AppColors.darkNavy.withOpacity(0.85)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.darkNavy.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.menu_book_rounded, size: 28, color: AppColors.white),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Material',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : InkWell(
                              onTap: () {
                                if (material.contentType != 'Video') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PDFViewerPage(pdfUrl: material.filePath, title: material.title),
                                    ),
                                  );
                                } else {
                                  launchUrl(Uri.parse(material.filePath));
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
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
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_circle_rounded, size: 20, color: AppColors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Start Learning',
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

                  // Updated date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AppColors.greyS500),
                          SizedBox(width: 4),
                          Text(
                            'Added on ${material.createdAt}',
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
