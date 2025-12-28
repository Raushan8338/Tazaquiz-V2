import 'package:flutter/material.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/utils/richText.dart';

class BuyCoursePage extends StatefulWidget {
  final String courseTitle;
  final String instructor;
  final double price;
  final double rating;
  final int totalStudents;
  final bool isPremiumUser;

  BuyCoursePage({
    this.courseTitle = 'Complete Mathematics Mastery',
    this.instructor = 'Dr. Sarah Johnson',
    this.price = 2499.00,
    this.rating = 4.8,
    this.totalStudents = 12450,
    this.isPremiumUser = false,
  });

  @override
  _BuyCoursePageState createState() => _BuyCoursePageState();
}

class _BuyCoursePageState extends State<BuyCoursePage> {
   //hyggtt
  int _selectedPlanIndex = 0;

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Single Course',
      'price': 2499,
      'duration': 'Lifetime Access',
      'features': ['This course only', 'Certificate', '24/7 Support'],
    },
    {
      'title': 'Course Bundle',
      'price': 4999,
      'duration': '3 Courses',
      'features': ['3 related courses', 'All certificates', 'Priority support', 'Bonus materials'],
      'badge': 'POPULAR',
    },
    {
      'title': 'Premium Pass',
      'price': 9999,
      'duration': 'Annual',
      'features': ['All courses', 'All certificates', 'VIP support', 'Exclusive content', 'Free updates'],
      'badge': 'BEST VALUE',
    },
  ];

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
                _buildCoursePreview(),
                _buildInstructorCard(),
                _buildWhatYouLearn(),
                _buildCourseContent(),
                _buildPlansSection(),
                _buildPaymentMethods(),
                _buildFAQSection(),
                _buildTestimonials(),
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
      expandedHeight: 200,
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
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.lightGold.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10)),
                        ],
                      ),
                      child: Icon(Icons.school, size: 48, color: AppColors.darkNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursePreview() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating and Students
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: AppColors.lightGold, size: 16),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '${widget.rating}',
                      13,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      1,
                      TextAlign.center,
                      0.0,
                    ),
                   
                  ],
                ),
              ),
              SizedBox(width: 12),

              AppRichText.setTextPoppinsStyle(
                context,
                '${widget.totalStudents.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} students',
                13,
                AppColors.greyS600,
                FontWeight.normal,
                1,
                TextAlign.center,
                0.0,
              ),
            
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppRichText.setTextPoppinsStyle(
                    context,
                    'BESTSELLER',
                    10,
                    AppColors.darkNavy,
                    FontWeight.w900,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
               
              ),
            ],
          ),
          SizedBox(height: 16),
          AppRichText.setTextPoppinsStyle(
            context,
            widget.courseTitle,
            20,
            AppColors.darkNavy,
            FontWeight.w800,
            2,
            TextAlign.left,
            1.3,
          ),
        
          SizedBox(height: 12),

          // Course Info
          Row(
            children: [
              _buildInfoChip(Icons.play_circle_outline, '45 Lessons'),
              SizedBox(width: 12),
              _buildInfoChip(Icons.access_time, '32 Hours'),
              SizedBox(width: 12),
              _buildInfoChip(Icons.language, 'English'),
            ],
          ),
          SizedBox(height: 20),

          // Price Display
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
                        12,
                        AppColors.lightGold,
                        FontWeight.normal,
                        2,
                        TextAlign.left,
                        0.0,
                      ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                         '₹ ${widget.price.toStringAsFixed(0)}',
                          30,
                          AppColors.white,
                          FontWeight.w900,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                       
                        SizedBox(width: 8),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          child:  AppRichText.setTextLineThroughStyle(
                            context,
                            '₹4999',
                            16,
                            AppColors.white.withOpacity(0.5),
                            FontWeight.normal,
                            2,
                            TextAlign.left,
                            0.0,
                        ),
                      
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.lightGold, 
                    borderRadius: BorderRadius.circular(10)),
                  child: AppRichText.setTextPoppinsStyle(
                            context,
                            '50% OFF',
                            14,
                            AppColors.darkNavy,
                            FontWeight.w900,
                            2,
                            TextAlign.center,
                            0.0,
                          ),
                
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.tealGreen),
        SizedBox(width: 4),
        AppRichText.setTextPoppinsStyle(
            context,
            text,
            12,
            AppColors.greyS700,
            FontWeight.w500,
            2,
            TextAlign.left,
            0.0,
          ),
      
      ],
    );
  }

  Widget _buildInstructorCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            widget.instructor[0],
                            24,
                            AppColors.white,
                            FontWeight.w700,
                            2,
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
                            11,
                            AppColors.greyS600,
                            FontWeight.normal,
                            2,
                            TextAlign.center,
                            0.0,
                          ),

                 AppRichText.setTextPoppinsStyle(
                            context,
                            widget.instructor,
                            16,
                            AppColors.darkNavy,
                            FontWeight.w700,
                            2,
                            TextAlign.center,
                            0),          
               
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.tealGreen),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(
                            context,
                            'Verified Expert',
                            11,
                            AppColors.tealGreen,
                            FontWeight.w600,
                            2,
                            TextAlign.center,
                            0),
                   
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.message_outlined, color: AppColors.darkNavy),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouLearn() {
    return Container(
      margin: EdgeInsets.all(16),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_outline, color: AppColors.lightGold, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                            context,
                            'What You\'ll Learn',
                            18,
                            AppColors.darkNavy,
                            FontWeight.w700,
                            2,
                            TextAlign.center,
                            0),
             
            ],
          ),
          SizedBox(height: 20),
          _buildLearningPoint('Master advanced mathematical concepts'),
          _buildLearningPoint('Solve complex problems with confidence'),
          _buildLearningPoint('Apply mathematics in real-world scenarios'),
          _buildLearningPoint('Prepare for competitive examinations'),
          _buildLearningPoint('Develop analytical thinking skills'),
        ],
      ),
    );
  }

  Widget _buildLearningPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.check, size: 14, color: AppColors.tealGreen),
          ),
          SizedBox(width: 12),
          Expanded(
            child:  AppRichText.setTextPoppinsStyle(
                            context,
                            text,
                            14,
                            AppColors.darkNavy,
                            FontWeight.normal,
                            5,
                            TextAlign.left,
                            1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContent() {
    return Container(
      margin: EdgeInsets.all(16),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.darkNavy, Color(0xFF000B58)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book, color: AppColors.lightGold, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                            context,
                            'Course Content',
                            18,
                            AppColors.darkNavy,
                            FontWeight.w700,
                            5,
                            TextAlign.center,
                            0.0),
              
              Spacer(),
               AppRichText.setTextPoppinsStyle(
                            context,
                            '45 Lessons',
                            13,
                            AppColors.tealGreen,
                            FontWeight.w600,
                            1,
                            TextAlign.center,
                            0.0),              
             
             
            ],
          ),
          SizedBox(height: 20),
          _buildContentModule('1', 'Introduction to Mathematics', '8 lessons', '2h 30m', true),
          _buildContentModule('2', 'Algebra Fundamentals', '12 lessons', '4h 15m', true),
          _buildContentModule('3', 'Geometry & Trigonometry', '10 lessons', '3h 45m', false),
          _buildContentModule('4', 'Calculus Basics', '15 lessons', '5h 20m', false),
        ],
      ),
    );
  }

  Widget _buildContentModule(String number, String title, String lessons, String duration, bool isFree) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyS1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyS200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child:  AppRichText.setTextPoppinsStyle(
                            context,
                            number,
                            16,
                            AppColors.white,
                            FontWeight.w700,
                            1,
                            TextAlign.center,
                            0.0),    
             
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 AppRichText.setTextPoppinsStyle(
                            context,
                            title,
                            14,
                            AppColors.darkNavy,
                            FontWeight.w600,
                            1,
                            TextAlign.center,
                            0.0),  
                
                SizedBox(height: 4),
                Row(
                  children: [
                    Text('$lessons • $duration', style: TextStyle(fontSize: 11, color: AppColors.greyS600)),
                    if (isFree) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tealGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AppRichText.setTextPoppinsStyle(
                            context,
                            'FREE',
                            9,
                            AppColors.tealGreen,
                            FontWeight.w900,
                            1,
                            TextAlign.center,
                            0.0), 
                       
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isFree ? Icons.play_circle_outline : Icons.lock_outline,
            color: isFree ? AppColors.tealGreen : AppColors.greyS400,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 AppRichText.setTextPoppinsStyle(
                            context,
                            'Choose Your Plan',
                            20,
                            AppColors.darkNavy,
                            FontWeight.w800,
                            1,
                            TextAlign.center,
                            0.0), 
                 AppRichText.setTextPoppinsStyle(
                            context,
                            'Select the best option for your learning journey',
                            13,
                            AppColors.greyS600,
                            FontWeight.normal,
                            1,
                            TextAlign.left,
                            0.0),            
               
               
              ],
            ),
          ),
          ...List.generate(_plans.length, (index) {
            return _buildPlanCard(index);
          }),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index) {
    final plan = _plans[index];
    final isSelected = _selectedPlanIndex == index;
    final badge = plan['badge'] as String?;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkNavy, AppColors.tealGreen],
                )
              : null,
          color: isSelected ? null : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.tealGreen : AppColors.greyS200, width: isSelected ? 3 : 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))
            else
              BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     AppRichText.setTextPoppinsStyle(
                            context,
                            plan['title'],
                            18,
                            isSelected ? AppColors.white : AppColors.darkNavy,
                            FontWeight.w700,
                            1,
                            TextAlign.left,
                            0.0),   
                   
                    
                    SizedBox(height: 4),
                    AppRichText.setTextPoppinsStyle(
                            context,
                            plan['duration'],
                            12,
                            isSelected ? AppColors.lightGold : AppColors.greyS600,
                            FontWeight.normal,
                            1,
                            TextAlign.left,
                            0.0), 
                    
                  ],
                ),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppRichText.setTextPoppinsStyle(
                            context,
                            badge,
                            9,
                          AppColors.darkNavy,
                            FontWeight.w900,
                            1,
                            TextAlign.left,
                            0.0), 
                   
                  ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                            context,
                            '₹',
                            20,
                            isSelected ? AppColors.lightGold : AppColors.darkNavy,
                            FontWeight.w500,
                            1,
                            TextAlign.left,
                            0.0), 

                 AppRichText.setTextPoppinsStyle(
                            context,
                            plan['price'].toString(),
                            30,
                            isSelected ? AppColors.white : AppColors.darkNavy,
                            FontWeight.w900,
                            1,
                            TextAlign.left,
                            0.0), 
                
              ],
            ),
            SizedBox(height: 16),
            ...List.generate(
              (plan['features'] as List).length,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.white.withOpacity(0.2) : AppColors.tealGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 12, color: isSelected ? AppColors.lightGold : AppColors.tealGreen),
                    ),
                    SizedBox(width: 8),
                    AppRichText.setTextPoppinsStyle(
                            context,
                            plan['features'][i],
                            13,
                            isSelected ? AppColors.white : AppColors.greyS700,
                            FontWeight.normal,
                            1,
                            TextAlign.left,
                            0.0), 
                   
                  ],
                ),
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.darkNavy, size: 18),
                    SizedBox(width: 8),
                    AppRichText.setTextPoppinsStyle(
                            context,
                            'Selected',
                            13,
                            AppColors.darkNavy,
                            FontWeight.w700,
                            1,
                            TextAlign.left,
                            0.0),
               
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: EdgeInsets.all(16),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payment, color: AppColors.darkNavy, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                            context,
                            'Payment Methods',
                            18,
                            AppColors.darkNavy,
                            FontWeight.w700,
                            1,
                            TextAlign.left,
                            0.0),
              
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              _buildPaymentIcon(Icons.credit_card, 'Cards'),
              SizedBox(width: 12),
              _buildPaymentIcon(Icons.account_balance, 'Net Banking'),
              SizedBox(width: 12),
              _buildPaymentIcon(Icons.account_balance_wallet, 'UPI'),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tealGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: AppColors.tealGreen, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Secure payment powered by industry standards',
                            12,
                            AppColors.darkNavy,
                            FontWeight.normal,
                            1,
                            TextAlign.left,
                            0.0),
           
               
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.greyS1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyS200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.darkNavy, size: 28),
            SizedBox(height: 8),
            AppRichText.setTextPoppinsStyle(
              context,
              label,
              11,
              AppColors.darkNavy,
              FontWeight.w600,
              1,
              TextAlign.left,
              0.0),
           
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      margin: EdgeInsets.all(16),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF000B58), AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.help_outline, color: AppColors.lightGold, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                          context,
                          'Frequently Asked Questions',
                          18,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          1,
                          TextAlign.left,
                          0.0),
             
            ],
          ),
          SizedBox(height: 20),
          _buildFAQItem('Can I get a refund?', 'Yes, 30-day money-back guarantee'),
          _buildFAQItem('Is lifetime access really lifetime?', 'Yes, access forever with updates'),
          _buildFAQItem('Are there any prerequisites?', 'Basic math knowledge recommended'),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
                          context,
                          question,
                          14,
                          AppColors.darkNavy,
                          FontWeight.w600,
                          1,
                          TextAlign.left,
                          0.0),
       
          SizedBox(height: 6),
          AppRichText.setTextPoppinsStyle(
                          context,
                          answer,
                          13,
                          AppColors.greyS600,
                          FontWeight.normal,
                          1,
                          TextAlign.left,
                          0.0),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: AppRichText.setTextPoppinsStyle(
                          context,
                          '⭐ Student Reviews',
                          18,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          1,
                          TextAlign.left,
                          0.0),
            
          ),
          Container(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTestimonialCard('Amazing course! Clear explanations.', 'Rahul S.', 5),
                _buildTestimonialCard('Best investment in my education.', 'Priya K.', 5),
                _buildTestimonialCard('Highly recommend to everyone!', 'Amit P.', 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String review, String name, int rating) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightGold.withOpacity(0.3), AppColors.lightGoldS2.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: List.generate(rating, (index) => Icon(Icons.star, color: AppColors.lightGold, size: 18))),
          SizedBox(height: 12),
          AppRichText.setTextPoppinsStyle(
                          context,
                          review,
                          14,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          3,
                          TextAlign.left,
                          1.5),

          Spacer(),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.darkNavy,
                child: AppRichText.setTextPoppinsStyle(
                          context,
                          name[0],
                          14,
                          AppColors.white,
                          FontWeight.w700,
                          3,
                          TextAlign.left,
                          0.0),
               
              ),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                          context,
                          name,
                          13,
                          AppColors.darkNavy,
                          FontWeight.w600,
                          2,
                          TextAlign.left,
                          0.0),
             
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedPlan = _plans[_selectedPlanIndex];
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   AppRichText.setTextPoppinsStyle(
                          context,
                          'Total Amount',
                          12,
                          AppColors.greyS600,
                          FontWeight.normal,
                          2,
                          TextAlign.left,
                          0.0),
                  AppRichText.setTextPoppinsStyle(
                          context,
                          '₹${selectedPlan['price']}',
                          28,
                          AppColors.darkNavy,
                          FontWeight.w900,
                          2,
                          TextAlign.left,
                          0.0),        
                  
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage()));
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
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_checkout, color: AppColors.white, size: 20),
                        SizedBox(width: 8),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Buy Now',
                          16,
                          AppColors.white,
                          FontWeight.w700,
                          2,
                          TextAlign.left,
                          0.0),  
                        
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
