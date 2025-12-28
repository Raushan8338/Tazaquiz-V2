import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'dart:async';

import 'package:tazaquiznew/utils/richText.dart';

class LiveTestScreen extends StatefulWidget {
  final String testTitle;
  final String subject;
  final int totalQuestions;
  final int totalParticipants;

  LiveTestScreen({
    this.testTitle = 'Advanced Mathematics Challenge',
    this.subject = 'Mathematics',
    this.totalQuestions = 25,
    this.totalParticipants = 1234,
  });

  @override
  _LiveTestScreenState createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> with SingleTickerProviderStateMixin {
  int _currentQuestion = 1;
  int _timeLeft = 30;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctAnswer = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Sample question data
  final Map<String, dynamic> _currentQuestionData = {
    'question': 'What is the derivative of x² + 3x + 5?',
    'options': ['2x + 3', 'x² + 3', '2x + 5', '3x + 3'],
    'correctAnswer': 0,
    'difficulty': 'Hard',
    'points': 50,
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 30;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _autoSubmit();
        }
      });
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
    });
  }

  void _submitAnswer() {
    if (_selectedOption == null || _answered) return;

    setState(() {
      _answered = true;
      _timer?.cancel();
      if (_selectedOption == _correctAnswer) {
        // _score += _currentQuestionData['points'];
      }
    });

    Future.delayed(Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _autoSubmit() {
    if (_answered) return;
    setState(() {
      _answered = true;
    });
    Future.delayed(Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < widget.totalQuestions) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => _buildResultDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressSection(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLiveParticipants(),
                  _buildQuestionCard(),
                  _buildOptionsSection(),
                  if (!_answered) _buildSubmitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showExitDialog(),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.close, color: AppColors.white, size: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: AppRichText.setTextPoppinsStyle(
                              context,
                              widget.testTitle,
                              16,
                              AppColors.white,
                              FontWeight.w700,
                              3,
                              TextAlign.left,
                              0.0,
                            ),
                         
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(widget.subject, style: TextStyle(fontSize: 12, color: AppColors.lightGold)),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                              ),
                              SizedBox(width: 4),
                              AppRichText.setTextPoppinsStyle(
                                context,
                                'LIVE',
                                10,
                                AppColors.white,
                                FontWeight.w900,
                                3,
                                TextAlign.left,
                                0.0,
                              ),

                             
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 18),
                    SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                              context,
                              '$_score',
                              16,
                              AppColors.darkNavy,
                              FontWeight.w900,
                              2,
                              TextAlign.left,
                              0.0,
                            ),
                  
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    double progress = _currentQuestion / widget.totalQuestions;
    double timeProgress = _timeLeft / 30;

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppRichText.setTextPoppinsStyle(
                            context,
                            'Question $_currentQuestion/${widget.totalQuestions}',
                            14,
                            AppColors.darkNavy,
                            FontWeight.w600,
                            2,
                            TextAlign.left,
                            0.0,
                          ),
         
              ScaleTransition(
                scale: _timeLeft <= 10 ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _timeLeft <= 5
                          ? [AppColors.red, AppColors.redS1]
                          : _timeLeft <= 10
                          ? [AppColors.orange, AppColors.orangeS1]
                          : [AppColors.tealGreen, AppColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_timeLeft <= 10 ? AppColors.red : AppColors.tealGreen).withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: AppColors.white, size: 18),
                      SizedBox(width: 6),
                         AppRichText.setTextPoppinsStyle(
                              context,
                              '$_timeLeft',
                              18,
                              AppColors.white,
                              FontWeight.w900,
                              2,
                              TextAlign.left,
                              0.0,
                            ),
                      AppRichText.setTextPoppinsStyle(
                              context,
                              's',
                              14,
                              AppColors.white,
                              FontWeight.w600,
                              2,
                              TextAlign.left,
                              0.0,
                            ),
                    
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                          context,
                          'Progress',
                          11,
                          AppColors.greyS600,
                          FontWeight.normal,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.greyS200,
                        valueColor: AlwaysStoppedAnimation(AppColors.tealGreen),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                        context,
                        'Time',
                        11,
                        AppColors.greyS600,
                        FontWeight.normal,
                        2,
                        TextAlign.left,
                        0.0,
                    ),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: timeProgress,
                        backgroundColor: AppColors.greyS200,
                        valueColor: AlwaysStoppedAnimation(
                          _timeLeft <= 5
                              ? AppColors.red
                              : _timeLeft <= 10
                              ? AppColors.orange
                              : AppColors.tealGreen,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveParticipants() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.lightGold.withOpacity(0.3), AppColors.lightGoldS2.withOpacity(0.2)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGold, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              _buildParticipantAvatar('A', 0),
              Padding(padding: EdgeInsets.only(left: 24), child: _buildParticipantAvatar('B', 1)),
              Padding(padding: EdgeInsets.only(left: 48), child: _buildParticipantAvatar('C', 2)),
              Padding(padding: EdgeInsets.only(left: 72), child: _buildParticipantAvatar('+', 3)),
            ],
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 6),
                  AppRichText.setTextPoppinsStyle(
                      context,
                      'Live Participants',
                      11,
                      AppColors.greyS700,
                      FontWeight.w500,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
             
                ],
              ),
               AppRichText.setTextPoppinsStyle(
                      context,
                      '${widget.totalParticipants} competing now',
                      14,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
         
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(String letter, int index) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: Center(
        child:  AppRichText.setTextPoppinsStyle(
                      context,
                      letter,
                      12,
                      AppColors.white,
                      FontWeight.w700,
                      2,
                      TextAlign.left,
                      0.0,
                    ),

      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Icon(Icons.category, color: AppColors.tealGreen, size: 14),
                    SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      widget.subject,
                      12,
                      AppColors.tealGreen,
                      FontWeight.w700,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
              
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: AppColors.darkNavy, size: 14),
                    SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '+${_currentQuestionData['points']} XP',
                      11,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
                   
                  ],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: AppRichText.setTextPoppinsStyle(
                      context,
                      _currentQuestionData['difficulty'],
                      11,
                      AppColors.red,
                      FontWeight.w700,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
       
              ),
            ],
          ),
          SizedBox(height: 20),
          AppRichText.setTextPoppinsStyle(
                      context,
                      _currentQuestionData['question'],
                      20,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
   
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          _currentQuestionData['options'].length,
          (index) => _buildOptionCard(String.fromCharCode(65 + index), _currentQuestionData['options'][index], index),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text, int index) {
    bool isSelected = _selectedOption == index;
    bool isCorrect = _answered && index == _correctAnswer;
    bool isWrong = _answered && isSelected && index != _correctAnswer;

    Color backgroundColor = AppColors.white;
    Color borderColor = AppColors.greyS300;
    Color letterBgColor = AppColors.greyS1;
    Color textColor = AppColors.darkNavy;

    if (isCorrect) {
      backgroundColor = AppColors.tealGreen.withOpacity(0.1);
      borderColor = AppColors.tealGreen;
      letterBgColor = AppColors.tealGreen;
    } else if (isWrong) {
      backgroundColor = AppColors.red.withOpacity(0.1);
      borderColor = AppColors.red;
      letterBgColor = AppColors.red;
    } else if (isSelected) {
      backgroundColor = AppColors.lightGold.withOpacity(0.2);
      borderColor = AppColors.lightGold;
      letterBgColor = AppColors.lightGold;
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected && !_answered
              ? [BoxShadow(color: AppColors.lightGold.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 5))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: letterBgColor, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: AppRichText.setTextPoppinsStyle(
                      context,
                      letter,
                      18,
                      (isCorrect || isWrong || (isSelected && !_answered)) ? AppColors.white : AppColors.darkNavy,
                      FontWeight.w900,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
               
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: AppRichText.setTextPoppinsStyle(
                      context,
                      text,
                      16,
                      textColor,
                      FontWeight.w600,
                      2,
                      TextAlign.left,
                      0.0,
                    ),

            ),
            if (_answered && (isCorrect || isWrong))
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: isCorrect ? AppColors.tealGreen : AppColors.red, shape: BoxShape.circle),
                child: Icon(isCorrect ? Icons.check : Icons.close, color: AppColors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = _selectedOption != null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: canSubmit ? _submitAnswer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          disabledBackgroundColor: AppColors.greyS300,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: canSubmit ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
            color: canSubmit ? null : AppColors.greyS300,
            borderRadius: BorderRadius.circular(16),
            boxShadow: canSubmit
                ? [BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))]
                : [],
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: canSubmit ? AppColors.white : AppColors.greyS500, size: 24),
                SizedBox(width: 12),
                AppRichText.setTextPoppinsStyle(
                      context,
                      'Submit Answer',
                      16,
                      canSubmit ? AppColors.white : AppColors.greyS500,
                      FontWeight.w700,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
         
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultDialog() {
    double accuracy = (_score / (widget.totalQuestions * 50) * 100);
    int rank = (widget.totalParticipants * (1 - accuracy / 100)).toInt() + 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.white, AppColors.greyS1],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Icon(Icons.emoji_events, color: AppColors.lightGold, size: 56),
            ),
            SizedBox(height: 24),
            AppRichText.setTextPoppinsStyle(
                    context,
                    'Test Completed!',
                    26,
                    AppColors.darkNavy,
                    FontWeight.w900,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
          
            SizedBox(height: 8),
            AppRichText.setTextPoppinsStyle(
                    context,
                    'Great job! Here\'s your performance',
                    14,
                    AppColors.greyS600,
                    FontWeight.normal,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultStat('Score', '$_score', Icons.stars, AppColors.tealGreen),
                _buildResultStat('Rank', '#$rank', Icons.leaderboard, AppColors.darkNavy),
                _buildResultStat('Accuracy', '${accuracy.toInt()}%', Icons.percent, Color(0xFF000B58)),
              ],
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightGold.withOpacity(0.3), AppColors.lightGoldS2.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGold),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'You earned $_score XP',
                          14,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                    
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Keep practicing to improve!',
                          11,
                          AppColors.greyS700,
                          FontWeight.normal,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.darkNavy, width: 2),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: AppRichText.setTextPoppinsStyle(
                          context,
                          'Review',
                          15,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
               
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: AppRichText.setTextPoppinsStyle(
                          context,
                          'Done',
                          15,
                          AppColors.white,
                          FontWeight.w700,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                       
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        AppRichText.setTextPoppinsStyle(
                          context,
                          value,
                          20,
                          color,
                          FontWeight.w900,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
    
        AppRichText.setTextPoppinsStyle(
                          context,
                          label,
                          11,
                          AppColors.greyS600,
                          FontWeight.normal,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 40),
              ),
              SizedBox(height: 20),
                AppRichText.setTextPoppinsStyle(
                          context,
                          'Exit Test?',
                          20,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
         
                SizedBox(height: 12),
                AppRichText.setTextPoppinsStyle(
                          context,
                          'Your progress will be lost if you exit now.',
                          14,
                          AppColors.greyS600,
                          FontWeight.normal,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
             
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyS300),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: AppRichText.setTextPoppinsStyle(
                          context,
                          'Cancel',
                          15,
                          AppColors.greyS700,
                          FontWeight.w600,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                  
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: AppRichText.setTextPoppinsStyle(
                          context,
                          'Exit',
                          15,
                          AppColors.white,
                          FontWeight.w700,
                          2,
                          TextAlign.left,
                          0.0,
                        ),
                      
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
