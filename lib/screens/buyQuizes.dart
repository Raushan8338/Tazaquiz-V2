import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizDetailPage extends StatefulWidget {
  final String quizId;
  final bool is_subscribed;

  QuizDetailPage({required this.quizId, required this.is_subscribed});

  @override
  _QuizDetailPageState createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isPurchased = false;
  int _product_sub_id = 0;
  int _isPremium = 0;
  bool _attempted = false;
  bool _isAccessible = false;
  bool _isFree = false;
  bool _isLive = false;
  QuizItem? _currentQuiz;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    await fetchQuizDetails(_user!.id);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> fetchQuizDetails(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'quiz_id': widget.quizId.toString(), 'user_id': userid.toString()};
      print('Fetching quiz details for Quiz ID: ${widget.quizId} and User ID: $userid');

      final responseFuture = await authRepository.get_quizId_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;

        if (responseData['status'] == true && responseData['data'] != null) {
          _currentQuiz = QuizItem.fromJson(responseData['data']);

          setState(() {
            _isPurchased = _currentQuiz!.isPurchased;

            _isAccessible = widget.is_subscribed == true ? true : _currentQuiz!.isAccessible;
            _attempted = _currentQuiz!.is_attempted;
            _isFree = _currentQuiz!.price == 0 || !_currentQuiz!.isPaid;
            _isLive = _currentQuiz!.isLive;
            _isPremium = _currentQuiz!.is_premium;
            _product_sub_id = _currentQuiz!.subscription_id;
            _remainingSeconds = _currentQuiz!.startsInSeconds;
          });

          if (_remainingSeconds > 0) {
            _startCountdown();
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching quiz details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _countdownTimer?.cancel();
          _isLive = true;
        }
      });
    });
  }

  String _getCountdownText() {
    if (_remainingSeconds <= 0) return "LIVE NOW!";

    int hours = _remainingSeconds ~/ 3600;
    int minutes = (_remainingSeconds % 3600) ~/ 60;
    int seconds = _remainingSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }

  void _handleStartQuiz() {
    if (_currentQuiz == null) return;

    print('Navigating to live test with Quiz ID: ${_currentQuiz!.quizId}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LiveTestScreen(
              testTitle: _currentQuiz!.title.toString(),
              subject: _currentQuiz!.difficultyLevel.toString(),
              Quiz_id: widget.quizId.toString(),
            ),
      ),
    );
  }

  void _handleSubscribe() {
    if (_currentQuiz == null) return;

    print('Navigating to checkout with Quiz ID: ${_isPremium}');
    String susb_category;
    String send_product_id;

    if (_isPremium == 1) {
      susb_category = 'QUIZ';
      send_product_id = widget.quizId;
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

    if (_currentQuiz == null) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        appBar: AppBar(backgroundColor: AppColors.darkNavy, title: Text('Error')),
        body: Center(child: Text('Quiz not found')),
      );
    }

    bool canStartQuiz = _isPurchased || _isAccessible || _isFree;
    print('canStartQuiz: $canStartQuiz');
    bool isAvailable = _isLive && canStartQuiz;

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(_currentQuiz!.title.toString()),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 12),
                if (canStartQuiz) _buildStatusBanner(),
                if (canStartQuiz) SizedBox(height: 12),
                if (_isLive && canStartQuiz) _buildLiveBanner(),
                if (_isLive && canStartQuiz) SizedBox(height: 12),

                // Course/Package Info (if part of a course)
                _buildCourseInfo(),
                SizedBox(height: 12),

                _buildQuizHeader(),
                SizedBox(height: 12),
                if (!canStartQuiz) _buildSubscriptionSection() else _buildQuizDetailsSection(),
                SizedBox(height: 12),
                if (_currentQuiz!.description.isNotEmpty) _buildDescriptionCard(),
                if (_currentQuiz!.description.isNotEmpty) SizedBox(height: 12),
                if (_currentQuiz!.instruction.isNotEmpty) _buildInstructionsCard(),
                if (_currentQuiz!.instruction.isNotEmpty) SizedBox(height: 12),
                _buildInfoCard(),
                SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatusBanner() {
    String message;
    IconData icon;
    List<Color> gradientColors;

    if (_isFree) {
      message = '🎉 This Quiz is FREE!';
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

  Widget _buildLiveBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red.shade600, Colors.red.shade800]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.play_circle_filled, color: Colors.red, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              '🔴 LIVE NOW! Join Immediately',
              12,
              AppColors.white,
              FontWeight.w700,
              2,
              TextAlign.left,
              1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(title) {
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
    String? courseTitle = _currentQuiz?.title; // Replace with: _currentQuiz?.courseTitle
    String? category = _currentQuiz?.Material_name; // Replace with: _currentQuiz?.category

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

  Widget _buildQuizHeader() {
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
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: _getStatusColor()),
                    SizedBox(width: 5),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      _currentQuiz!.quizStatus.toUpperCase(),
                      10,
                      _getStatusColor(),
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
              if (_currentQuiz!.difficultyLevel.isNotEmpty) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AppRichText.setTextPoppinsStyle(
                    context,
                    _currentQuiz!.difficultyLevel,
                    10,
                    AppColors.tealGreen,
                    FontWeight.w600,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 10),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentQuiz!.Category_name,
            17,
            AppColors.darkNavy,
            FontWeight.w700,
            3,
            TextAlign.left,
            1.3,
          ),
          SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.help_outline, size: 14, color: AppColors.greyS600),
              SizedBox(width: 5),
              AppRichText.setTextPoppinsStyle(
                context,
                'Series / Courses Name',
                11,
                AppColors.greyS600,
                FontWeight.w500,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 8),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentQuiz!.subscription_description,
            11,
            AppColors.darkNavy,
            FontWeight.normal,
            20,
            TextAlign.left,
            1.3,
          ),
          SizedBox(height: 10),
          if (_remainingSeconds > 0) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, color: Colors.orange.shade700, size: 16),
                  SizedBox(width: 6),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Starts in ${_getCountdownText()}',
                    12,
                    Colors.orange.shade700,
                    FontWeight.w600,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_currentQuiz!.quizStatus.toLowerCase()) {
      case 'live':
        return Colors.red;
      case 'upcoming':
        return Colors.orange;
      case 'completed':
        return AppColors.greyS500;
      default:
        return AppColors.tealGreen;
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
          _buildBenefit(Icons.all_inclusive, 'Unlimited Quiz Access', 'Attempt all quizzes without limits'),
          SizedBox(height: 10),
          _buildBenefit(Icons.menu_book, 'Complete Study Material', 'PDFs, videos, notes & practice sets'),
          SizedBox(height: 10),
          _buildBenefit(Icons.school, 'Expert Guidance', 'Learn from experienced teachers'),
          SizedBox(height: 10),
          _buildBenefit(Icons.bar_chart, 'Performance Analytics', 'Track progress with detailed reports'),
          SizedBox(height: 10),
          _buildBenefit(Icons.update, 'Regular Content Updates', 'New quizzes added every week'),
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

  Widget _buildQuizDetailsSection() {
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
                child: Icon(Icons.access_time, color: AppColors.lightGold, size: 16),
              ),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                context,
                'Quiz Schedule',
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
          _buildDetailRow(Icons.calendar_today, 'Start Time', _currentQuiz!.startDateTime),
          if (_currentQuiz!.endDateTime.isNotEmpty) ...[
            SizedBox(height: 8),
            _buildDetailRow(Icons.event_busy, 'End Time', _currentQuiz!.endDateTime),
          ],
          if (_currentQuiz!.timeLimit.isNotEmpty) ...[
            SizedBox(height: 8),
            _buildDetailRow(Icons.timer, 'Duration', '${_currentQuiz!.timeLimit} min'),
          ],
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
                'About This Quiz',
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
            _currentQuiz!.description,
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

  Widget _buildInstructionsCard() {
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
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.rule, color: AppColors.darkNavy, size: 16),
              ),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                context,
                'Instructions',
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
          _buildInstructionItems(),
        ],
      ),
    );
  }

  Widget _buildInstructionItems() {
    final instructionText = _currentQuiz!.instruction;
    final liRegex = RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true);
    final matches = liRegex.allMatches(instructionText);

    if (matches.isEmpty) {
      return AppRichText.setTextPoppinsStyle(
        context,
        _removeHtmlTags(instructionText),
        12,
        AppColors.greyS700,
        FontWeight.w400,
        10,
        TextAlign.left,
        1.5,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          matches.map((match) {
            String content = match.group(1) ?? '';
            String cleanText = _removeHtmlTags(content);

            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.tealGreen, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      cleanText,
                      11,
                      AppColors.greyS700,
                      FontWeight.w400,
                      10,
                      TextAlign.left,
                      1.4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _removeHtmlTags(String htmlText) {
    String text = htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('\n', ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  Widget _buildInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: AppColors.darkNavy, size: 16),
              ),
              SizedBox(width: 8),
              AppRichText.setTextPoppinsStyle(
                context,
                'Important Information',
                12,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildInfoRow(Icons.check_circle_outline, 'Single attempt only'),
          SizedBox(height: 6),
          _buildInfoRow(Icons.wifi, 'Stable internet required'),
          SizedBox(height: 6),
          _buildInfoRow(Icons.leaderboard, 'Instant results & ranking'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.tealGreen),
        SizedBox(width: 8),
        Expanded(
          child: AppRichText.setTextPoppinsStyle(
            context,
            text,
            11,
            AppColors.greyS700,
            FontWeight.w400,
            1,
            TextAlign.left,
            0.0,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    bool canStartQuiz = _isPurchased || _isAccessible || _isFree;
    bool isAvailable = _isLive && canStartQuiz;

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
              if (_attempted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('You have already attempted this quiz'), backgroundColor: AppColors.greyS600),
                );
                return;
              }

              if (isAvailable) {
                _handleStartQuiz();
              } else if (canStartQuiz) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Quiz will start at scheduled time'), backgroundColor: Colors.orange),
                );
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
                      _attempted
                          ? [Colors.grey.shade500, Colors.grey.shade700]
                          : isAvailable
                          ? [Colors.red.shade600, Colors.red.shade800]
                          : canStartQuiz
                          ? [Color(0xFFF59E0B), Color(0xFFD97706)]
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
                      _attempted
                          ? Icons.check_circle_outline
                          : isAvailable
                          ? Icons.play_arrow_rounded
                          : canStartQuiz
                          ? Icons.schedule
                          : Icons.workspace_premium,
                      color: AppColors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      _attempted
                          ? 'Already Attempted'
                          : isAvailable
                          ? 'Start Quiz'
                          : canStartQuiz
                          ? 'Starts ${_getCountdownText()}'
                          : 'Subscribe Now',
                      14,
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
      ),
    );
  }
}
