import 'package:flutter/material.dart';
import 'dart:async';

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
      backgroundColor: Color(0xFFF8F9FD),
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
      backgroundColor: Color(0xFF003161),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.favorite_border, color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF003161), Color(0xFF016A67)],
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
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
                        color: Color(0xFFFDEB9E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Color(0xFFFDEB9E).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10)),
                        ],
                      ),
                      child: Icon(Icons.school, size: 48, color: Color(0xFF003161)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 8))],
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
                  color: Color(0xFF016A67).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFFDEB9E), size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${widget.rating}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${widget.totalStudents.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} students',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'BESTSELLER',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Course Title
          Text(
            widget.courseTitle,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF003161), height: 1.3),
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
              gradient: LinearGradient(colors: [Color(0xFF003161), Color(0xFF016A67)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Course Price', style: TextStyle(fontSize: 12, color: Color(0xFFFDEB9E))),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${widget.price.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          child: Text(
                            '₹4999',
                            style: TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Color(0xFFFDEB9E), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '50% OFF',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
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
        Icon(icon, size: 16, color: Color(0xFF016A67)),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildInstructorCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.instructor[0],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructor', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(
                  widget.instructor,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: Color(0xFF016A67)),
                    SizedBox(width: 4),
                    Text(
                      'Verified Expert',
                      style: TextStyle(fontSize: 11, color: Color(0xFF016A67), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.message_outlined, color: Color(0xFF003161)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_outline, color: Color(0xFFFDEB9E), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'What You\'ll Learn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
              ),
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
            decoration: BoxDecoration(color: Color(0xFF016A67).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.check, size: 14, color: Color(0xFF016A67)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: Color(0xFF003161), height: 1.5)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF003161), Color(0xFF000B58)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book, color: Color(0xFFFDEB9E), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Course Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
              ),
              Spacer(),
              Text(
                '45 Lessons',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF016A67)),
              ),
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
        color: Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF003161)),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text('$lessons • $duration', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    if (isFree) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF016A67).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'FREE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF016A67)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isFree ? Icons.play_circle_outline : Icons.lock_outline,
            color: isFree ? Color(0xFF016A67) : Colors.grey[400],
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
                Text(
                  'Choose Your Plan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF003161)),
                ),
                Text(
                  'Select the best option for your learning journey',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
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
                  colors: [Color(0xFF003161), Color(0xFF016A67)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Color(0xFF016A67) : Colors.grey[200]!, width: isSelected ? 3 : 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: Color(0xFF016A67).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))
            else
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5)),
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
                    Text(
                      plan['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Color(0xFF003161),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      plan['duration'],
                      style: TextStyle(fontSize: 12, color: isSelected ? Color(0xFFFDEB9E) : Colors.grey[600]),
                    ),
                  ],
                ),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Color(0xFFFDEB9E) : Color(0xFF003161),
                  ),
                ),
                Text(
                  plan['price'].toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : Color(0xFF003161),
                  ),
                ),
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
                        color: isSelected ? Colors.white.withOpacity(0.2) : Color(0xFF016A67).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 12, color: isSelected ? Color(0xFFFDEB9E) : Color(0xFF016A67)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      plan['features'][i],
                      style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Color(0xFFFDEB9E), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF003161), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Selected',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                    ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payment, color: Color(0xFF003161), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Payment Methods',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
              ),
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
              color: Color(0xFF016A67).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Color(0xFF016A67), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secure payment powered by industry standards',
                    style: TextStyle(fontSize: 12, color: Color(0xFF003161)),
                  ),
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
          color: Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF003161), size: 28),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF003161)),
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF000B58), Color(0xFF003161)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.help_outline, color: Color(0xFFFDEB9E), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
              ),
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
      decoration: BoxDecoration(color: Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF003161)),
          ),
          SizedBox(height: 6),
          Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
            child: Text(
              '⭐ Student Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
            ),
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
          colors: [Color(0xFFFDEB9E).withOpacity(0.3), Color(0xFFFDD835).withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFFDEB9E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: List.generate(rating, (index) => Icon(Icons.star, color: Color(0xFFFDD835), size: 18))),
          SizedBox(height: 12),
          Text(
            review,
            style: TextStyle(fontSize: 14, color: Color(0xFF003161), height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF003161),
                child: Text(
                  name[0],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF003161)),
              ),
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
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    '₹${selectedPlan['price']}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showPaymentSuccessDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Buy Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 48),
              ),
              SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF003161)),
              ),
              SizedBox(height: 12),
              Text(
                'You now have access to the course',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Start Learning',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      textAlign: TextAlign.center,
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
}
