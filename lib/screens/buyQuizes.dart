import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizDetailPage extends StatefulWidget {
  final String quizId;

  QuizDetailPage({
    required this.quizId,
  });

  @override
  _QuizDetailPageState createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isPurchased = false;
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
    setState(() {});
    await fetchQuizDetails(_user!.id);
  }

  Future<void> fetchQuizDetails(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'quiz_id': widget.quizId.toString(),
        'user_id': userid.toString(),
      };

      final responseFuture = await authRepository.get_quizId_wise_details(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        
        if (responseData['status'] == true && responseData['data'] != null) {
          _currentQuiz = QuizItem.fromJson(responseData['data']);
          _isPurchased = _currentQuiz!.isPurchased;
          _isAccessible = _currentQuiz!.isAccessible;
          _isFree = _currentQuiz!.price == 0 || !_currentQuiz!.isPaid;
          _isLive = _currentQuiz!.isLive;
          _remainingSeconds = _currentQuiz!.startsInSeconds;

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

    // TODO: Navigate to quiz page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting quiz...'),
        backgroundColor: AppColors.tealGreen,
      ),
    );
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

    if (_currentQuiz == null) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        appBar: AppBar(
          backgroundColor: AppColors.darkNavy,
          title: Text('Error'),
        ),
        body: Center(
          child: Text('Quiz not found'),
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
                if (_isPurchased || _isAccessible || _isFree) _buildStatusBanner(),
                if (_isPurchased || _isAccessible || _isFree) SizedBox(height: 16),
                if (_isLive && (_isPurchased || _isAccessible || _isFree)) _buildLiveBanner(),
                if (_isLive && (_isPurchased || _isAccessible || _isFree)) SizedBox(height: 16),
                _buildQuizCard(),
                SizedBox(height: 16),
                _buildTimingCard(),
                SizedBox(height: 16),
                _buildDescriptionCard(),
                SizedBox(height: 16),
                _buildInstructionsCard(),
                SizedBox(height: 16),
                _buildQuizInfoCard(),
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

  Widget _buildStatusBanner() {
    String message;
    IconData icon;
    List<Color> gradientColors;

   if (_isFree) {
  message = '🎉 This Quiz is completely FREE!';
  icon = Icons.celebration;
  gradientColors = [AppColors.tealGreen, AppColors.darkNavy];
} else if (_isPurchased) {
  message = '✅ You have already purchased this Quiz!';
  icon = Icons.check_circle;
  gradientColors = [AppColors.tealGreen, AppColors.darkNavy];
} else {
  message = '🔓 This Quiz is accessible for you!';
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

  Widget _buildLiveBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 20,
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
            child: Icon(Icons.play_circle_filled, color: Colors.red, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              '🔴 LIVE NOW! Quiz Started - Join Immediately!',
              13,
              AppColors.white,
              FontWeight.w700,
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
                        Icons.quiz,
                        size: 36,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    if (_currentQuiz!.isPaid && _currentQuiz!.price > 0) ...[
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

  Widget _buildQuizCard() {
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 13, color: _getStatusColor()),
                    SizedBox(width: 5),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      _currentQuiz!.quizStatus.toUpperCase(),
                      11,
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppRichText.setTextPoppinsStyle(
                    context,
                    _currentQuiz!.difficultyLevel,
                    11,
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
          SizedBox(height: 14),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentQuiz!.title,
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
                      _isFree ? 'Free Quiz' : 'Entry Fee',
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
                            _currentQuiz!.price.toStringAsFixed(0),
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
                    _isFree ? Icons.card_giftcard : Icons.paid,
                    color: AppColors.darkNavy,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildTimingCard() {
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
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.access_time, color: AppColors.lightGold, size: 18),
              ),
              SizedBox(width: 10),
              AppRichText.setTextPoppinsStyle(
                context,
                'Quiz Timing',
                14,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTimingRow(Icons.calendar_today, 'Start Time', _currentQuiz!.startDateTime),
          if (_currentQuiz!.endDateTime.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildTimingRow(Icons.event_busy, 'End Time', _currentQuiz!.endDateTime),
          ],
          if (_currentQuiz!.timeLimit.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildTimingRow(Icons.timer, 'Duration', '${_currentQuiz!.timeLimit} minutes'),
          ],
          if (_remainingSeconds > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_bottom, color: AppColors.white, size: 20),
                  SizedBox(width: 10),
                  Column(
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Starts In',
                        11,
                        AppColors.white,
                        FontWeight.w500,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                      SizedBox(height: 2),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        _getCountdownText(),
                        18,
                        AppColors.white,
                        FontWeight.w800,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimingRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.tealGreen),
        SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                label,
                12,
                AppColors.greyS600,
                FontWeight.w500,
                1,
                TextAlign.left,
                0.0,
              ),
              AppRichText.setTextPoppinsStyle(
                context,
                value,
                12,
                AppColors.darkNavy,
                FontWeight.w600,
                1,
                TextAlign.right,
                0.0,
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
                'About This Quiz',
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
            _currentQuiz!.description.isNotEmpty 
                ? _currentQuiz!.description 
                : 'Test your knowledge with this exciting quiz!',
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

  Widget _buildInstructionsCard() {
    if (_currentQuiz!.instruction.isEmpty) return SizedBox.shrink();

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
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.rule, color: AppColors.darkNavy, size: 18),
              ),
              SizedBox(width: 10),
              AppRichText.setTextPoppinsStyle(
                context,
                'Instructions',
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
          _buildInstructionItems(),
        ],
      ),
    );
  }

  Widget _buildInstructionItems() {
    // Parse HTML and extract li elements
    final instructionText = _currentQuiz!.instruction;
    final liRegex = RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true);
    final matches = liRegex.allMatches(instructionText);

    if (matches.isEmpty) {
      return AppRichText.setTextPoppinsStyle(
        context,
        _removeHtmlTags(instructionText),
        13,
        AppColors.greyS700,
        FontWeight.w500,
        10,
        TextAlign.left,
        1.6,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: matches.map((match) {
        String content = match.group(1) ?? '';
        String cleanText = _removeHtmlTags(content);
        
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 5),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.tealGreen,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildFormattedText(cleanText),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormattedText(String text) {
    // Extract bold text patterns
    final strongRegex = RegExp(r'\*\*(.*?)\*\*');
    final parts = <TextSpan>[];
    int lastIndex = 0;

    for (final match in strongRegex.allMatches(text)) {
      // Add normal text before bold
      if (match.start > lastIndex) {
        parts.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.greyS700,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ));
      }

      // Add bold text
      parts.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.darkNavy,
          fontWeight: FontWeight.w700,
          height: 1.6,
        ),
      ));

      lastIndex = match.end;
    }

    // Add remaining normal text
    if (lastIndex < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.greyS700,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: parts),
    );
  }

  String _removeHtmlTags(String htmlText) {
    // Remove HTML tags
    String text = htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('\n', ' ');
    // Replace multiple spaces with single space
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // Mark bold text with **
    text = text.replaceAll(RegExp(r'<strong[^>]*>(.*?)</strong>'), '**\$1**');
    return text.trim();
  }

  Widget _buildQuizInfoCard() {
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
                child: Icon(Icons.info_outline, color: AppColors.darkNavy, size: 18),
              ),
              SizedBox(width: 10),
              AppRichText.setTextPoppinsStyle(
                context,
                'Quiz Information',
                13,
                AppColors.darkNavy,
                FontWeight.w600,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 14),
          _buildInfoItem(Icons.check_circle_outline, 'One-time attempt only'),
          SizedBox(height: 10),
          _buildInfoItem(Icons.wifi_off, 'Stable internet required'),
          SizedBox(height: 10),
          _buildInfoItem(Icons.leaderboard, 'Instant results & ranking'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.tealGreen),
        SizedBox(width: 10),
        Expanded(
          child: AppRichText.setTextPoppinsStyle(
            context,
            text,
            12,
            AppColors.greyS700,
            FontWeight.w500,
            1,
            TextAlign.left,
            0.0,
          ),
        ),
      ],
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
    bool canStartQuiz = _isPurchased || _isAccessible || _isFree;
    bool isAvailable = _isLive && canStartQuiz;

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
            if (!canStartQuiz) ...[
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Entry Fee',
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
                          _currentQuiz!.price.toStringAsFixed(0),
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
              flex: canStartQuiz ? 1 : 3,
              child: ElevatedButton(
                onPressed: () {
                  if (isAvailable) {
                    _handleStartQuiz();
                  } else if (canStartQuiz) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Quiz will start at scheduled time'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          contentType: 'QUIZ',
                          contentId: widget.quizId,
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
                      colors: isAvailable
                          ? [Colors.red.shade600, Colors.red.shade800]
                          : canStartQuiz
                              ? [Colors.orange.shade400, Colors.orange.shade600]
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
                          isAvailable
                              ? Icons.play_arrow
                              : canStartQuiz
                                  ? Icons.schedule
                                  : Icons.lock_outline,
                          color: AppColors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          isAvailable
                              ? 'Start Quiz Now'
                              : canStartQuiz
                                  ? 'Registered - ${_getCountdownText()}'
                                  : 'Buy Now',
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
          ],
        ),
      ),
    );
  }
}