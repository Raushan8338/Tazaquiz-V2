import 'package:flutter/material.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/utils/richText.dart';

class BuyCoursePage extends StatefulWidget {
  final String courseTitle;
  final String category;
  final String instructor;
  final double price;
  final String description;
  final String contentType;
  final String contentId;
  final bool isPremium;
  final String? updatedAt;

  BuyCoursePage({
    required this.courseTitle,
    required this.category,
    required this.instructor,
    required this.price,
    required this.description,
    required this.contentType,
    required this.contentId,
    this.isPremium = false,
    this.updatedAt,
  });

  @override
  _BuyCoursePageState createState() => _BuyCoursePageState();
}

class _BuyCoursePageState extends State<BuyCoursePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 16),
                _buildCourseCard(),
                SizedBox(height: 16),
                _buildDescriptionCard(),
                SizedBox(height: 16),
                _buildInstructorCard(),
                SizedBox(height: 16),
                _buildSecurePaymentInfo(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
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
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
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
              // Decorative circles
              Positioned(
                right: -50,
                top: 20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              // Center icon
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.lightGold.withOpacity(0.4), blurRadius: 25, offset: Offset(0, 10)),
                        ],
                      ),
                      child: Icon(
                        widget.contentType.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.school,
                        size: 40,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    if (widget.isPremium) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 14, color: AppColors.darkNavy),
                            SizedBox(width: 6),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'PREMIUM',
                              11,
                              AppColors.darkNavy,
                              FontWeight.w900,
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
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined, size: 14, color: AppColors.tealGreen),
                SizedBox(width: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  widget.category,
                  12,
                  AppColors.tealGreen,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Course Title
          AppRichText.setTextPoppinsStyle(
            context,
            widget.courseTitle,
            22,
            AppColors.darkNavy,
            FontWeight.w900,
            3,
            TextAlign.left,
            1.3,
          ),

          SizedBox(height: 24),

          // Price Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Course Price',
                      13,
                      AppColors.lightGold,
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          '₹',
                          20,
                          AppColors.white,
                          FontWeight.w600,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          widget.price.toStringAsFixed(1),
                          32,
                          AppColors.white,
                          FontWeight.w900,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.shopping_bag_outlined, color: AppColors.darkNavy, size: 28),
                ),
              ],
            ),
          ),

          // Updated Date
          if (widget.updatedAt != null) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.greyS500),
                SizedBox(width: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Updated ${widget.updatedAt}',
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
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_outlined, color: AppColors.lightGold, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'About This Course',
                17,
                AppColors.darkNavy,
                FontWeight.w800,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 16),
          AppRichText.setTextPoppinsStyle(
            context,
            widget.description,
            14,
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: AppRichText.setTextPoppinsStyle(
                context,
                widget.instructor.isNotEmpty ? widget.instructor[0].toUpperCase() : 'I',
                26,
                AppColors.white,
                FontWeight.w800,
                1,
                TextAlign.center,
                0.0,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Instructor',
                  12,
                  AppColors.greyS600,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 4),
                AppRichText.setTextPoppinsStyle(
                  context,
                  widget.instructor,
                  16,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.tealGreen),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.security, color: AppColors.darkNavy, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Secure Payment',
                      15,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '100% secure payment with encryption',
                      12,
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
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tealGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPaymentMethod(Icons.credit_card, 'Cards'),
                Container(width: 1, height: 30, color: AppColors.greyS300),
                _buildPaymentMethod(Icons.account_balance_wallet, 'UPI'),
                Container(width: 1, height: 30, color: AppColors.greyS300),
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
        Icon(icon, color: AppColors.darkNavy, size: 24),
        SizedBox(height: 6),
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
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Total Amount',
                    13,
                    AppColors.greyS600,
                    FontWeight.w600,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '₹',
                        18,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        widget.price.toStringAsFixed(1),
                        28,
                        AppColors.darkNavy,
                        FontWeight.w900,
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
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(contentType: widget.contentType, contentId: widget.contentId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: AppColors.white, size: 20),
                        SizedBox(width: 10),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Enroll Now',
                          16,
                          AppColors.white,
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
