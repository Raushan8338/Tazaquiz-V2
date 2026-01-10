import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/screens/PDFViewerPage.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/study_material_details_item.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class BuyCoursePage extends StatefulWidget {
  final String contentId;

  BuyCoursePage({
    required this.contentId,
  });

  @override
  _BuyCoursePageState createState() => _BuyCoursePageState();
}

class _BuyCoursePageState extends State<BuyCoursePage> {
  UserModel? _user;
  List<StudyMaterialDetailsItem> _studyMaterials_new = [];
  bool _isLoading = true;
  bool _isPurchased = false;
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
    setState(() {});
    await fetchStudyCategory(_user!.id);
  }

  Future<List<StudyMaterialDetailsItem>> fetchStudyCategory(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'material_id': widget.contentId.toString(),
        'user_id': userid.toString(),
      };

      final responseFuture = await authRepository.get_study_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        final List list = responseData['data'] ?? [];

        _studyMaterials_new = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();

        if (_studyMaterials_new.isNotEmpty) {
          _currentMaterial = _studyMaterials_new.first;
          _isPurchased = _currentMaterial!.isPurchased;
          _isAccessible = _currentMaterial!.isAccessible;
          _isFree = _currentMaterial!.price == 0 || !_currentMaterial!.isPaid;
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
          builder: (context) => PDFViewerPage(
            pdfUrl: _currentMaterial!.filePath,
            title: _currentMaterial!.title,
          ),
        ),
      );
    } else {
      print(_currentMaterial!.contentType);
      launchUrl(Uri.parse(_currentMaterial!.filePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen),
          ),
        ),
      );
    }

    if (_currentMaterial == null) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        appBar: AppBar(
          backgroundColor: AppColors.darkNavy,
          title: Text('Error'),
        ),
        body: Center(
          child: Text('Course not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 16),
                if (_isPurchased || _isAccessible || _isFree) _buildPurchaseStatusBanner(),
                if (_isPurchased || _isAccessible || _isFree) SizedBox(height: 16),
                _buildCourseCard(),
                SizedBox(height: 16),
                _buildDescriptionCard(),
                SizedBox(height: 16),
                _buildInstructorCard(),
                if (!_isPurchased && !_isAccessible && !_isFree) ...[
                  SizedBox(height: 16),
                  _buildSecurePaymentInfo(),
                ],
                SizedBox(height: 100),
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
  message = '🎉 This Study Material is completely FREE!';
  icon = Icons.celebration;
  gradientColors = [AppColors.tealGreen, AppColors.darkNavy];
} else if (_isPurchased) {
  message = '✅ You have already purchased this Course!';
  icon = Icons.check_circle;
  gradientColors = [AppColors.tealGreen, AppColors.darkNavy];
} else {
  message = '🔓 This Content is accessible for you!';
  icon = Icons.lock_open;
  gradientColors = [AppColors.lightGold, AppColors.lightGoldS2];
}


    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: gradientColors[0], size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              message,
              13,
              AppColors.white,
              FontWeight.w600,
              3,
              TextAlign.left,
              1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
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
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: 20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Container(
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightGold.withOpacity(0.4),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentMaterial!.contentType.toUpperCase() == 'PDF'
                            ? Icons.picture_as_pdf
                            : Icons.school,
                        size: 36,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    if (_currentMaterial!.isPaid && _currentMaterial!.price > 0) ...[
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.lightGold, AppColors.lightGoldS2],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 12, color: AppColors.darkNavy),
                            SizedBox(width: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'PREMIUM',
                              10,
                              AppColors.darkNavy,
                              FontWeight.w800,
                              1,
                              TextAlign.center,
                              0.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.tealGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined, size: 13, color: AppColors.tealGreen),
                SizedBox(width: 5),
                AppRichText.setTextPoppinsStyle(
                  context,
                  _currentMaterial!.contentType,
                  11,
                  AppColors.tealGreen,
                  FontWeight.w600,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentMaterial!.title,
            17,
            AppColors.darkNavy,
            FontWeight.w700,
            3,
            TextAlign.left,
            1.4,
          ),
          SizedBox(height: 18),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      _isFree ? 'Free Course' : 'Course Price',
                      12,
                      AppColors.lightGold,
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 5),
                    if (_isFree)
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'FREE',
                        24,
                        AppColors.white,
                        FontWeight.w800,
                        1,
                        TextAlign.left,
                        0.0,
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppRichText.setTextPoppinsStyle(
                            context,
                            '₹',
                            15,
                            AppColors.white,
                            FontWeight.w600,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            _currentMaterial!.price.toStringAsFixed(1),
                            26,
                            AppColors.white,
                            FontWeight.w800,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                        ],
                      ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isFree ? Icons.card_giftcard : Icons.shopping_bag_outlined,
                    color: AppColors.darkNavy,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.access_time, size: 13, color: AppColors.greyS500),
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

  Widget _buildDescriptionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description_outlined, color: AppColors.lightGold, size: 18),
              ),
              SizedBox(width: 10),
              AppRichText.setTextPoppinsStyle(
                context,
                'About This Course',
                14,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 14),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentMaterial!.description,
            13,
            AppColors.greyS700,
            FontWeight.w500,
            10,
            TextAlign.left,
            1.6,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCard() {
    String instructorName = _currentMaterial!.author;
    String instructorInitial = instructorName.isNotEmpty ? instructorName[0].toUpperCase() : 'I';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: AppRichText.setTextPoppinsStyle(
                context,
                instructorInitial,
                24,
                AppColors.white,
                FontWeight.w700,
                1,
                TextAlign.center,
                0.0,
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Instructor',
                  11,
                  AppColors.greyS600,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 3),
                AppRichText.setTextPoppinsStyle(
                  context,
                  instructorName,
                  14,
                  AppColors.darkNavy,
                  FontWeight.w600,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.verified, size: 13, color: AppColors.tealGreen),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Verified Instructor',
                      11,
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

  Widget _buildSecurePaymentInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.security, color: AppColors.darkNavy, size: 18),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Secure Payment',
                      13,
                      AppColors.darkNavy,
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 3),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '100% secure payment with encryption',
                      11,
                      AppColors.greyS600,
                      FontWeight.w500,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.tealGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPaymentMethod(Icons.credit_card, 'Cards'),
                Container(width: 1, height: 28, color: AppColors.greyS300),
                _buildPaymentMethod(Icons.account_balance_wallet, 'UPI'),
                Container(width: 1, height: 28, color: AppColors.greyS300),
                _buildPaymentMethod(Icons.account_balance, 'Banking'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.darkNavy, size: 22),
        SizedBox(height: 5),
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          11,
          AppColors.greyS700,
          FontWeight.w600,
          1,
          TextAlign.center,
          0.0,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    bool showStartLearning = _isPurchased || _isAccessible || _isFree;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!showStartLearning) ...[
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Total Amount',
                      11,
                      AppColors.greyS600,
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          '₹',
                          14,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          _currentMaterial!.price.toStringAsFixed(1),
                          22,
                          AppColors.darkNavy,
                          FontWeight.w800,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
            ],
            Expanded(
              flex: showStartLearning ? 1 : 3,
              child: ElevatedButton(
                onPressed: () {
                  if (showStartLearning) {
                    _handleStartLearning();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          contentType: 'STUDY',
                          contentId: widget.contentId,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: showStartLearning
                          ? [AppColors.lightGold, AppColors.lightGoldS2]
                          : [AppColors.tealGreen, AppColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          showStartLearning ? Icons.play_circle_filled : Icons.lock_outline,
                          color: showStartLearning ? AppColors.darkNavy : AppColors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          showStartLearning ? 'Start Learning' : 'Buy Now',
                          14,
                          showStartLearning ? AppColors.darkNavy : AppColors.white,
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
          ],
        ),
      ),
    );
  }
}