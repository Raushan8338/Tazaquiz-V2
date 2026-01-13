import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'dart:async';

import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class LiveTestScreen extends StatefulWidget {
  final String testTitle;
  final String subject;
  final String Quiz_id;

  LiveTestScreen({required this.testTitle, required this.subject, required this.Quiz_id});

  @override
  _LiveTestScreenState createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> with SingleTickerProviderStateMixin {
  //hyggtt
  int _currentQuestion = 0;
  List<dynamic> _questions = [];
  int totalQuestions = 0;
  int _timeLeft = 5;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctAnswer = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Sample question data
  Map<String, dynamic> _currentQuestionData = {};

  UserModel? _user;
  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _getUserData();
  }

  void _getUserData() async {
    // Fetch and set user data here if needed
    _user = await SessionManager.getUser();
    setState(() {});
    loadQuizData();
  }

  void loadQuizData() async {
    final data = {'user_id': _user?.id, 'quiz_id': widget.Quiz_id, 'score': ''};

    Authrepository authRepository = Authrepository(Api_Client.dio);
    final responseFuture = await authRepository.fetchQuizQuestion(data);

    final Map<String, dynamic> apiResponse =
        responseFuture.data is String
            ? jsonDecode(responseFuture.data)
            : Map<String, dynamic>.from(responseFuture.data);

    _questions = apiResponse['questions'] ?? [];
    totalQuestions = _questions.length;

    if (_questions.isNotEmpty) {
      setQuestionFromApi(0); // 👈 first question load
    }
  }

  void setQuestionFromApi(int index) {
    final question = _questions[index];
    final List answers = question['answers'] ?? [];

    int correctIndex = answers.indexWhere((ans) => ans['is_correct'] == true);

    setState(() {
      _currentQuestion = index;
      _correctAnswer = correctIndex == -1 ? 0 : correctIndex;
      _currentQuestionData = {
        'question': question['question_text'],
        'options': answers.map((a) => a['answer_text']).toList(),
        'correctAnswer': correctIndex == -1 ? 0 : correctIndex,
        'difficulty': question['difficulty_level'] ?? 'Medium',
        'points': question['points'] ?? 0,
        'attempt_id': question['attempt_id'] ?? 0,
        'question_ans_id': question['question_ans_id'] ?? 0,
        'question_id': question['question_id'] ?? 0,
      };
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 10;
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

  void _submitAnswer() async {
    if (_selectedOption == null || _answered) return;

    setState(() {
      _answered = true;
      _timer?.cancel();
      // Score update karo agar correct hai
      if (_selectedOption == _correctAnswer) {
        _score += _currentQuestionData['points'] as int;
      }
    });

    // API call karke answer submit karo
    Authrepository authRepository = Authrepository(Api_Client.dio);

    final data = {
      'attempt_id': _currentQuestionData['attempt_id'].toString(),
      'question_id': _currentQuestionData['question_id'].toString(),
      'answer_id': _currentQuestionData['question_ans_id'].toString(),
      'score': (_selectedOption == _correctAnswer ? _currentQuestionData['points'] : 0).toString(),
      'is_correct': (_selectedOption == _correctAnswer ? '1' : '0'),
      'time_spent': (10 - _timeLeft).toString(),
    };

    try {
      final responseData = await authRepository.submitQuizAnswers(data);
      print('Submit response: ${responseData.statusCode}');
    } catch (e) {
      print('Error submitting answer: $e');
    }

    // ✅ OPTION 1: Agar correct answer SHOW nahi karna chahte
    // Directly next question pe jao
    Future.delayed(Duration(milliseconds: 500), () {
      _nextQuestion();
    });

    // ✅ OPTION 2: Agar correct answer SHOW karna chahte (2 seconds)
    // Uncomment below code and comment above code
    /*
  Future.delayed(Duration(seconds: 2), () {
    _nextQuestion();
  });
  */
  }

  void _autoSubmit() async {
    if (_answered) return;
    setState(() {
      _answered = true;
    });
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {
      'attempt_id': _currentQuestionData['attempt_id'].toString(),
      'question_id': _currentQuestionData['question_id'].toString(),
      'answer_id': _currentQuestionData['question_ans_id'].toString(),
      'score': _currentQuestionData['points'].toString(),
      'is_correct': _selectedOption == _correctAnswer ? '1' : '0'.toString(),
      'time_spent': _timeLeft.toString(),
    };
    print('Auto submitting data: $data');

    final responseData = await authRepository.submitQuizAnswers(data);

    if (responseData.statusCode == 200) {
      Future.delayed(Duration(milliseconds: 500), () {
        _nextQuestion();
      });
    } else {
      print('Failed to submit answer');
    }

    // Future.delayed(Duration(seconds: 2), () {
    //   _nextQuestion();
    // });
  }

  void _nextQuestion() {
    if (_currentQuestion < totalQuestions - 1) {
      // ✅ Change: totalQuestions - 1
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
        _answered = false;
      });
      setQuestionFromApi(_currentQuestion); // ✅ Add this line - yeh bhul gaye the
      _startTimer();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);

    final data = {'attempt_id': _currentQuestionData['attempt_id'].toString(), 'Passingscore': '$_score'};

    final responseData = await authRepository.finalSubmitQuiz(data);

    showDialog(context: context, barrierDismissible: false, builder: (context) => _buildResultDialog());
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty || _currentQuestionData.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        body: Center(child: CircularProgressIndicator(color: AppColors.tealGreen)),
      );
    }
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
                  SizedBox(height: 10),
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
                            13,
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
                        Text(widget.subject, style: TextStyle(fontSize: 11, color: AppColors.lightGold)),
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
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 16),
                    SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '$_score',
                      14,
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
    double progress = _currentQuestion / totalQuestions;
    double timeProgress = _timeLeft / 10;

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
                'Question $_currentQuestion/$totalQuestions',
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
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          _timeLeft <= 5
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
                      Icon(Icons.timer, color: AppColors.white, size: 16),
                      SizedBox(width: 6),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '$_timeLeft',
                        14,
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

  Widget _buildQuestionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(15),
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
                      '${_currentQuestionData['points']} Points',
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
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  widget.subject,
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
          SizedBox(height: 10),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentQuestionData['question'] ?? '',
            15,
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
    //   final List options = _currentQuestionData['options'] ?? [];

    // if (options.isEmpty) {
    //   return const SizedBox(); // 👈 no crash
    // }
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
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isSelected && !_answered
                  ? [BoxShadow(color: AppColors.lightGold.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 5))]
                  : [],
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(color: letterBgColor, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  letter,
                  14,
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
                14,
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
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.tealGreen : AppColors.red,
                  shape: BoxShape.circle,
                ),
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
            boxShadow:
                canSubmit
                    ? [BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))]
                    : [],
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: canSubmit ? AppColors.white : AppColors.greyS500, size: 24),
                SizedBox(width: 12),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Submit Answer',
                  14,
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
    double accuracy = (_score / (totalQuestions * 50) * 100);
    int rank = 1;

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
              child: Icon(Icons.emoji_events, color: AppColors.lightGold, size: 40),
            ),
            SizedBox(height: 24),
            AppRichText.setTextPoppinsStyle(
              context,
              'Test Completed!',
              18,
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
              12,
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
                      13,
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
                          13,
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
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        AppRichText.setTextPoppinsStyle(context, value, 16, color, FontWeight.w900, 2, TextAlign.left, 0.0),

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
      builder:
          (context) => Dialog(
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
                    16,
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
                    11,
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
                            13,
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
                            13,
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
