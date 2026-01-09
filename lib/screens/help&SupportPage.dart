import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/my_ticket_page.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';
import 'dart:ui';

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedIssueType = 'Technical Problem';
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Technical Problem',
    'Account Help',
    'Payment Issue',
    'Quiz Content',
    'Feature Request',
    'Other',
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I login with OTP?',
      'answer':
          'Tap on "Login with OTP" → Enter your registered mobile number → You will receive a 6-digit OTP → Enter the OTP → You\'re logged in!',
      'icon': Icons.phone_android,
      'color': AppColors.tealGreen,
    },
    {
      'question': 'How can I access study materials?',
      'answer':
          'Go to Home → Select your course/subject → Tap on "Study Materials" tab → Choose topic → Download or view PDFs, notes, and videos',
      'icon': Icons.menu_book,
      'color': AppColors.darkNavy,
    },
    {
      'question': 'How do I attempt a quiz?',
      'answer':
          'Select your subject → Choose quiz difficulty → Tap "Start Quiz" → Answer all questions → Submit to see your score and detailed analysis',
      'icon': Icons.quiz,
      'color': AppColors.oxfordBlue,
    },
    {
      'question': 'Can I review my quiz answers?',
      'answer':
          'Yes! After submitting quiz → Tap "View Solutions" → See correct answers with detailed explanations for each question',
      'icon': Icons.fact_check,
      'color': AppColors.tealGreen,
    },
    {
      'question': 'How to track my progress?',
      'answer':
          'Go to Profile → Tap "My Progress" → View your quiz scores, completion percentage, strengths, weaknesses, and performance graphs',
      'icon': Icons.analytics,
      'color': AppColors.darkNavy,
    },
    {
      'question': 'Why can\'t I download study materials?',
      'answer':
          'Check your internet connection → Ensure you have storage space → Some materials are premium only → Contact support if issue persists',
      'icon': Icons.download,
      'color': AppColors.oxfordBlue,
    },
    {
      'question': 'How do I change my profile details?',
      'answer':
          'Go to Profile → Tap edit icon (top right) → Update your name, email, phone, or profile photo → Save changes',
      'icon': Icons.edit,
      'color': AppColors.tealGreen,
    },
    {
      'question': 'Why is my payment not reflecting?',
      'answer':
          'Payments reflect within 5-10 minutes. If delayed → Check bank statement → Wait 24 hours → Contact support with transaction ID and screenshot',
      'icon': Icons.payment,
      'color': AppColors.darkNavy,
    },
  ];
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _animationController.reset();
        _animationController.forward();
      }
    });
    _getUserData();
  }

  void _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {
      'userId': _user?.id.toString() ?? '',
      'reason': _selectedIssueType,
      'issueDescription': _messageController.text.trim(),
    };
    final responseFuture = await authRepository.generateServiceRequest(data);

    if (responseFuture.statusCode == 200) {
      // Handle success
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    } else {
      // Handle error
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: BouncingScrollPhysics(),
              children: [_buildFAQTab(), _buildContactFormTab()],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Help & Support',
            16,
            AppColors.white,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)],
                ),
              ),
              SizedBox(width: 6),
              Flexible(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  'Available 24/7',
                  10.5,
                  AppColors.lightGold,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => All_Raised_Ticket_Page()));
                //  _showTicketStatusDialog();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number_outlined, color: AppColors.white, size: 18),
                    SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Track',
                      11,
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy.withOpacity(0.05), AppColors.tealGreen.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.2), width: 1),
      ),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 4))],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.tealGreen, AppColors.darkNavy],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 3))],
          ),
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.darkNavy,
          labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.help_outline_rounded, size: 20), SizedBox(width: 8), Text('FAQs')],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.contact_support_outlined, size: 20), SizedBox(width: 8), Text('Contact Us')],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.lightGold.withOpacity(0.15), AppColors.lightGold.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGold.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.lightGold.withOpacity(0.4), AppColors.lightGold.withOpacity(0.2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.lightbulb_outline, color: AppColors.darkNavy, size: 26),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      'Quick answers to common questions',
                      14,
                      AppColors.darkNavy,
                      FontWeight.w600,
                      2,
                      TextAlign.left,
                      1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            ...List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 60)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: Opacity(opacity: value, child: _buildFAQCard(faq, index)),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent, splashColor: AppColors.tealGreen.withOpacity(0.05)),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            padding: EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [(faq['color'] as Color).withOpacity(0.15), (faq['color'] as Color).withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(faq['icon'] ?? Icons.help_outline, color: faq['color'] as Color, size: 22),
          ),
          title: Padding(
            padding: EdgeInsets.only(right: 8),
            child: AppRichText.setTextPoppinsStyle(
              context,
              faq['question'],
              13.5,
              AppColors.darkNavy,
              FontWeight.w700,
              3,
              TextAlign.left,
              1.3,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greyS1.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.tealGreen.withOpacity(0.1)),
              ),
              child: AppRichText.setTextPoppinsStyle(
                context,
                faq['answer'],
                12.5,
                AppColors.greyS700,
                FontWeight.w500,
                15,
                TextAlign.left,
                1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStillNeedHelpCard() {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.tealGreen],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.35), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.headset_mic_outlined, color: AppColors.lightGold, size: 36),
          ),
          SizedBox(height: 14),
          AppRichText.setTextPoppinsStyle(
            context,
            'Still Need Help?',
            17,
            AppColors.white,
            FontWeight.w900,
            1,
            TextAlign.center,
            1.2,
          ),
          SizedBox(height: 6),
          AppRichText.setTextPoppinsStyle(
            context,
            'Can\'t find what you\'re looking for?\nOur support team is ready to assist!',
            13,
            AppColors.white.withOpacity(0.9),
            FontWeight.w500,
            5,
            TextAlign.center,
            1.5,
          ),
          SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _tabController.animateTo(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppColors.tealGreen, size: 20),
                  SizedBox(width: 10),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Contact Support',
                    15,
                    AppColors.tealGreen,
                    FontWeight.w700,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFormTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.tealGreen.withOpacity(0.1), AppColors.darkNavy.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.tealGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.support_agent, color: AppColors.white, size: 26),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'Get in Touch',
                            15,
                            AppColors.darkNavy,
                            FontWeight.w900,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                          SizedBox(height: 2),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'We\'ll respond within 24 hours',
                            12,
                            AppColors.greyS700,
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
              ),
              SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // _buildTextField('Full Name', _nameController, Icons.person_outline, 'Enter your full name'),
                    // SizedBox(height: 14),
                    // _buildTextField(
                    //   'Email Address',
                    //   _emailController,
                    //   Icons.email_outlined,
                    //   'Enter your email',
                    //   keyboardType: TextInputType.emailAddress,
                    // ),
                    // SizedBox(height: 14),
                    // _buildTextField(
                    //   'Phone Number',
                    //   _phoneController,
                    //   Icons.phone_outlined,
                    //   'Enter your phone number',
                    //   keyboardType: TextInputType.phone,
                    // ),
                    SizedBox(height: 14),
                    _buildIssueTypeDropdown(),
                    SizedBox(height: 14),
                    _buildMessageField(),
                    SizedBox(height: 22),
                    _buildSubmitButton(),
                  ],
                ),
              ),
              SizedBox(height: 22),
              _buildQuickContactOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          13.5,
          AppColors.darkNavy,
          FontWeight.w700,
          1,
          TextAlign.left,
          0.0,
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tealGreen.withOpacity(0.25), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.darkNavy,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.greyS400),
              prefixIcon: Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.tealGreen, size: 20),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (label == 'Email Address' && !value.contains('@')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIssueTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          'Issue Type',
          13.5,
          AppColors.darkNavy,
          FontWeight.w700,
          1,
          TextAlign.left,
          0.0,
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tealGreen.withOpacity(0.25), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedIssueType,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.tealGreen, size: 24),
              items:
                  _issueTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getIssueIcon(type), color: AppColors.tealGreen, size: 20),
                          SizedBox(width: 12),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            type,
                            14,
                            AppColors.darkNavy,
                            FontWeight.w600,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedIssueType = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIssueIcon(String type) {
    switch (type) {
      case 'Technical Problem':
        return Icons.bug_report;
      case 'Account Help':
        return Icons.account_circle;
      case 'Payment Issue':
        return Icons.payment;
      case 'Quiz Content':
        return Icons.quiz;
      case 'Feature Request':
        return Icons.lightbulb_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          'Your Message',
          13.5,
          AppColors.darkNavy,
          FontWeight.w700,
          1,
          TextAlign.left,
          0.0,
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tealGreen.withOpacity(0.25), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: TextFormField(
            controller: _messageController,
            maxLines: 5,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.darkNavy,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Describe your issue or query in detail...',
              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.greyS400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your issue';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSubmitting ? [Colors.grey, Colors.grey.shade600] : [AppColors.tealGreen, AppColors.darkNavy],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow:
                _isSubmitting
                    ? []
                    : [BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 5))],
          ),
          child: Container(
            alignment: Alignment.center,
            child:
                _isSubmitting
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: AppColors.white, size: 20),
                        SizedBox(width: 10),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Submit Message',
                          15,
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
    );
  }

  Widget _buildQuickContactOptions() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Other Ways to Reach Us',
            15,
            AppColors.darkNavy,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 14),
          _buildContactOption(Icons.email_outlined, 'Email', 'info@tazaquiz.com', AppColors.tealGreen),
          SizedBox(height: 10),
          // _buildContactOption(Icons.phone_outlined, 'Phone', '+91 98765 43210', AppColors.darkNavy),
          // SizedBox(height: 10),
          _buildContactOption(Icons.access_time, 'Working Hours', 'Mon - Sat, 9:00 AM - 6:00 PM', AppColors.oxfordBlue),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                title,
                13,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
              SizedBox(height: 2),
              AppRichText.setTextPoppinsStyle(
                context,
                subtitle,
                12,
                AppColors.greyS700,
                FontWeight.w500,
                2,
                TextAlign.left,
                1.2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 30, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green.shade700]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                              ],
                            ),
                            child: Icon(Icons.check_rounded, color: AppColors.white, size: 46),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 22),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Message Sent!',
                      21,
                      AppColors.darkNavy,
                      FontWeight.w900,
                      1,
                      TextAlign.center,
                      1.2,
                    ),
                    SizedBox(height: 10),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Thank you for contacting us!\nWe\'ll get back to you within 24 hours.',
                      14,
                      AppColors.greyS700,
                      FontWeight.w500,
                      5,
                      TextAlign.center,
                      1.5,
                    ),
                    SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _formKey.currentState!.reset();
                          _nameController.clear();
                          _emailController.clear();
                          _phoneController.clear();
                          _messageController.clear();
                          setState(() {
                            _selectedIssueType = 'Technical Problem';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: AppRichText.setTextPoppinsStyle(
                              context,
                              'Done',
                              16,
                              AppColors.white,
                              FontWeight.w700,
                              1,
                              TextAlign.center,
                              0.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
