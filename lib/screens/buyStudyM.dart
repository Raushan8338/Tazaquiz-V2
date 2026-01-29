import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tazaquiz/API/api_client.dart';
import 'package:tazaquiz/authentication/AuthRepository.dart';
import 'package:tazaquiz/screens/PDFViewerPage.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:tazaquiz/constants/app_colors.dart';
import 'package:tazaquiz/models/login_response_model.dart';
import 'package:tazaquiz/models/study_material_details_item.dart';
import 'package:tazaquiz/screens/checkout.dart';
import 'package:tazaquiz/utils/richText.dart';
import 'package:tazaquiz/utils/session_manager.dart';

class BuyCoursePage extends StatefulWidget {
  final String contentId;
  final String page_API_call;

  BuyCoursePage({required this.contentId, required this.page_API_call});

  @override
  _BuyCoursePageState createState() => _BuyCoursePageState();
}

class _BuyCoursePageState extends State<BuyCoursePage> {
  UserModel? _user;
  List<StudyMaterialDetailsItem> _studyMaterials_new = [];
  bool _isLoading = true;
  bool _isPurchased = false;
  int _product_sub_id = 0;
  int _isPremium = 0;
  bool _isAccessible = false;
  bool _isFree = false;
  StudyMaterialDetailsItem? _currentMaterial;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    await fetchStudyCategory(_user!.id);

    if (!mounted) return;
    setState(() {});
  }

  Future<List<StudyMaterialDetailsItem>> fetchStudyCategory(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'material_id': widget.contentId.toString(),
        'user_id': userid.toString(),
        'page_API_call': widget.page_API_call,
      };
      print('data: $data');

      final responseFuture = await authRepository.get_study_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        final List list = responseData['data'] ?? [];

        _studyMaterials_new = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();

        if (_studyMaterials_new.isNotEmpty) {
          _currentMaterial = _studyMaterials_new.first;
          _isPurchased = _currentMaterial!.isPurchased;
          _isAccessible = _currentMaterial!.isAccessible;
          _isFree = !_currentMaterial!.isPaid;

          // Add these fields from API if available
          _isPremium = _currentMaterial!.is_premium ?? 0;
          _product_sub_id = _currentMaterial!.subscription_id ?? 0;
        }

        setState(() {
          _isLoading = false;
        });

        return _studyMaterials_new;
      } else {
        setState(() {
          _isLoading = false;
        });
        return [];
      }
    } catch (e) {
      print('Error fetching study details: $e');
      setState(() {
        _isLoading = false;
      });
      return [];
    }
  }

  void _handleStartLearning() {
    if (_currentMaterial == null) return;

    if (_currentMaterial!.contentType != 'Video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(pdfUrl: _currentMaterial!.filePath, title: _currentMaterial!.title),
        ),
      );
    } else {
      print(_currentMaterial!.contentType);
      launchUrl(Uri.parse(_currentMaterial!.filePath));
    }
  }

  void _handleSubscribe() {
    if (_currentMaterial == null) return;

    print('Navigating to checkout with isPremium: $_isPremium');
    String susb_category;
    String send_product_id;

    if (_isPremium == 1) {
      susb_category = 'STUDY';
      send_product_id = widget.contentId;
    } else {
      susb_category = 'Subscription';
      send_product_id = _product_sub_id.toString();
    }
    print('susb_category: $susb_category');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutPage(contentType: susb_category, contentId: send_product_id)),
    ).then((value) {
      if (value == true) {
        _getUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen))),
      );
    }

    if (_currentMaterial == null) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        appBar: AppBar(backgroundColor: AppColors.darkNavy, title: Text('Error')),
        body: Center(child: Text('Course not found')),
      );
    }

    bool canStartLearning = _isPurchased || _isAccessible || _isFree;
    print('canStartLearning: ${_currentMaterial!.description}');

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(_currentMaterial!.title.toString()),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 12),
                if (canStartLearning) _buildPurchaseStatusBanner(),
                if (canStartLearning) SizedBox(height: 12),

                // Course/Package Info
                _buildCourseInfo(),
                SizedBox(height: 12),

                _buildCourseCard(),
                SizedBox(height: 12),

                // Subscription Benefits or Course Details
                if (!canStartLearning) _buildSubscriptionSection() else _buildCourseDetailsSection(),

                SizedBox(height: 12),
                (_currentMaterial!.description.isEmpty) ? SizedBox() : _buildDescriptionCard(),
                SizedBox(height: 12),
                (_currentMaterial!.description.isEmpty) ? SizedBox() : _buildInstructorCard(),
                SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPurchaseStatusBanner() {
    String message;
    IconData icon;
    List<Color> gradientColors;

    if (_isFree) {
      message = '🎉 This Study Material is FREE!';
      icon = Icons.celebration;
      gradientColors = [AppColors.tealGreen, AppColors.darkNavy];
    } else if (_isPurchased) {
      message = '✅ You are subscribed!';
      icon = Icons.check_circle;
      gradientColors = [AppColors.tealGreen, AppColors.darkNavy];
    } else {
      message = '🔓 Accessible for you!';
      icon = Icons.lock_open;
      gradientColors = [AppColors.lightGold, AppColors.lightGoldS2];
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: gradientColors[0], size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              message,
              12,
              AppColors.white,
              FontWeight.w600,
              2,
              TextAlign.left,
              1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String title) {
    return SliverAppBar(
      expandedHeight: 55,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      title: AppRichText.setTextPoppinsStyle(
        context,
        title,
        12,
        AppColors.white,
        FontWeight.w700,
        2,
        TextAlign.left,
        1.2,
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    // Using subscription fields similar to QuizDetailPage
    String? courseTitle = _currentMaterial?.Category_name;
    String? category = _currentMaterial?.Material_name;

    if (courseTitle == null || courseTitle.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.lightGold.withOpacity(0.1), AppColors.lightGoldS2.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.library_books, color: AppColors.darkNavy, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null && category.isNotEmpty) ...[
                  AppRichText.setTextPoppinsStyle(
                    context,
                    category,
                    10,
                    AppColors.greyS600,
                    FontWeight.w600,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 2),
                ],
                AppRichText.setTextPoppinsStyle(
                  context,
                  courseTitle,
                  13,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  2,
                  TextAlign.left,
                  1.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Type Badge
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentMaterial!.contentType.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.video_library,
                      size: 12,
                      color: AppColors.tealGreen,
                    ),
                    SizedBox(width: 5),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      _currentMaterial!.contentType,
                      10,
                      AppColors.tealGreen,
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // Course Title
          AppRichText.setTextPoppinsStyle(
            context,
            _currentMaterial!.Material_name,
            12,
            AppColors.darkNavy,
            FontWeight.w700,
            3,
            TextAlign.left,
            1.3,
          ),
          SizedBox(height: 10),
          // Course Title
          AppRichText.setTextPoppinsStyle(
            context,
            _currentMaterial!.subscription_description,
            12,
            AppColors.darkNavy,
            FontWeight.normal,
            50,
            TextAlign.left,
            1.3,
          ),
          SizedBox(height: 10),

          // Updated Date
          Row(
            children: [
              Icon(Icons.access_time, size: 13, color: AppColors.greyS600),
              SizedBox(width: 5),
              AppRichText.setTextPoppinsStyle(
                context,
                'Updated ${_formatDate(_currentMaterial!.createdAt)}',
                11,
                AppColors.greyS600,
                FontWeight.w500,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildSubscriptionSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.tealGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, color: AppColors.lightGold, size: 18),
                SizedBox(width: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Subscription Benefits',
                  13,
                  AppColors.white,
                  FontWeight.w700,
                  1,
                  TextAlign.center,
                  0.0,
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          _buildBenefit(Icons.all_inclusive, 'Unlimited Content Access', 'Access all study materials without limits'),
          SizedBox(height: 10),
          _buildBenefit(Icons.menu_book, 'Complete Study Material', 'PDFs, videos, notes & practice sets'),
          SizedBox(height: 10),
          _buildBenefit(Icons.school, 'Expert Guidance', 'Learn from experienced teachers'),
          SizedBox(height: 10),
          _buildBenefit(Icons.bar_chart, 'Performance Analytics', 'Track progress with detailed reports'),
          SizedBox(height: 10),
          _buildBenefit(Icons.update, 'Regular Content Updates', 'New materials added every week'),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7),
            decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.darkNavy, size: 16),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  title,
                  12,
                  AppColors.white,
                  FontWeight.w600,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  subtitle,
                  10,
                  AppColors.white.withOpacity(0.85),
                  FontWeight.w400,
                  2,
                  TextAlign.left,
                  1.2,
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: AppColors.lightGold, size: 16),
        ],
      ),
    );
  }

  Widget _buildCourseDetailsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: AppColors.lightGold, size: 16),
              ),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                context,
                'Course Details',
                13,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildDetailRow(Icons.category_outlined, 'Content Type', _currentMaterial!.contentType),
          SizedBox(height: 8),
          _buildDetailRow(Icons.person_outline, 'Author', _currentMaterial!.coaching_name),
          SizedBox(height: 8),
          _buildDetailRow(Icons.calendar_today, 'Published', _formatDate(_currentMaterial!.createdAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.tealGreen),
        SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                label,
                11,
                AppColors.greyS600,
                FontWeight.w500,
                1,
                TextAlign.left,
                0.0,
              ),
              Flexible(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  value,
                  11,
                  AppColors.darkNavy,
                  FontWeight.w600,
                  1,
                  TextAlign.right,
                  0.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_outlined, color: AppColors.lightGold, size: 16),
              ),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                context,
                'About This Course',
                13,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 10),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentMaterial!.description,
            12,
            AppColors.greyS700,
            FontWeight.w400,
            10,
            TextAlign.left,
            1.5,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCard() {
    String instructorName = _currentMaterial!.coaching_name;
    String instructorInitial = instructorName.isNotEmpty ? instructorName[0].toUpperCase() : 'I';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppRichText.setTextPoppinsStyle(
                context,
                instructorInitial,
                20,
                AppColors.white,
                FontWeight.w700,
                1,
                TextAlign.center,
                0.0,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Instructor',
                  10,
                  AppColors.greyS600,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 2),
                AppRichText.setTextPoppinsStyle(
                  context,
                  instructorName,
                  13,
                  AppColors.darkNavy,
                  FontWeight.w600,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 4),

                Html(
                  data: _currentMaterial!.coaching_bio, // ya bioInfo
                ),
                SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: AppColors.tealGreen),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Verified Instructor',
                      10,
                      AppColors.tealGreen,
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    bool canStartLearning = _isPurchased || _isAccessible || _isFree;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (canStartLearning) {
                _handleStartLearning();
              } else {
                _handleSubscribe();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      canStartLearning
                          ? [AppColors.lightGold, AppColors.lightGoldS2]
                          : [AppColors.tealGreen, AppColors.darkNavy],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canStartLearning ? Icons.play_circle_filled : Icons.workspace_premium,
                      color: canStartLearning ? AppColors.darkNavy : AppColors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      canStartLearning ? 'Start Learning' : 'Subscribe Now',
                      14,
                      canStartLearning ? AppColors.darkNavy : AppColors.white,
                      FontWeight.w700,
                      1,
                      TextAlign.center,
                      0.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
