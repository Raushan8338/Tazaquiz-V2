import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'dart:async';

import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class MockTestScreen extends StatefulWidget {
  final String testTitle;
  final String subject;
  final String Quiz_id;

  MockTestScreen({required this.testTitle, required this.subject, required this.Quiz_id});

  @override
  _MockTestScreenState createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> with SingleTickerProviderStateMixin {
  // ── Question State ──────────────────────────────────────────────────────────
  int _currentQuestion = 0;
  List<dynamic> _questions = [];
  int totalQuestions = 0;
  Map<String, dynamic> _currentQuestionData = {};

  // ── Mock-specific State ─────────────────────────────────────────────────────
  // Per question saved answers (index → selected option index)
  Map<int, int> _savedAnswers = {};
  // Mark for review (index → bool)
  Map<int, bool> _markedForReview = {};
  // Visited questions
  Set<int> _visitedQuestions = {};

  // ── Total Timer ─────────────────────────────────────────────────────────────
  int _totalSeconds = 0; // set from API timeLimit
  Timer? _testTimer;
  bool _isPaused = false;

  // ── UI State ────────────────────────────────────────────────────────────────
  int? _selectedOption; // current selected (not yet saved)
  bool _isLoading = true;

  // ── Animation ───────────────────────────────────────────────────────────────
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _getUserData();
  }

  // ── Data Loading ─────────────────────────────────────────────────────────────

  void _getUserData() async {
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

    // timeLimit from API (in minutes) → seconds
    int timeLimitMinutes = int.tryParse(apiResponse['time_limit']?.toString() ?? '30') ?? 30;
    _totalSeconds = timeLimitMinutes * 60;

    if (_questions.isNotEmpty) {
      setQuestionFromApi(0);
      _startTestTimer();
    }

    setState(() => _isLoading = false);
  }

  void setQuestionFromApi(int index) {
    final question = _questions[index];
    final List answers = question['answers'] ?? [];
    int correctIndex = answers.indexWhere((ans) => ans['is_correct'] == true);

    _visitedQuestions.add(index);

    setState(() {
      _currentQuestion = index;
      _currentQuestionData = {
        'question': question['question_text'],
        'options': answers.map((a) => a['answer_text']).toList(),
        'correctAnswer': correctIndex == -1 ? 0 : correctIndex,
        'difficulty': question['difficulty_level'] ?? 'Medium',
        'points': question['points'] ?? 0,
        'attempt_id': question['attempt_id'] ?? 0,
        'question_ans_id': question['question_ans_id'] ?? 0,
        'question_id': question['question_id'] ?? 0,
        // store all answer ids for submission
        'answer_ids': answers.map((a) => a['id']).toList(),
      };
      // Restore previously saved answer for this question
      _selectedOption = _savedAnswers[index];
    });
  }

  // ── Timer ─────────────────────────────────────────────────────────────────────

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      setState(() {
        if (_totalSeconds > 0) {
          _totalSeconds--;
        } else {
          _testTimer?.cancel();
          _finalSubmit();
        }
      });
    });
  }

  String _getTimerText() {
    int h = _totalSeconds ~/ 3600;
    int m = (_totalSeconds % 3600) ~/ 60;
    int s = _totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_totalSeconds <= 60) return AppColors.red;
    if (_totalSeconds <= 300) return AppColors.orange;
    return AppColors.tealGreen;
  }

  // ── Answer Handling ───────────────────────────────────────────────────────────

  void _selectOption(int index) {
    setState(() => _selectedOption = index);
  }

  void _saveAndNext() {
    // Save current answer locally
    if (_selectedOption != null) {
      _savedAnswers[_currentQuestion] = _selectedOption!;
    }
    _goToQuestion(_currentQuestion + 1);
  }

  void _saveCurrent() {
    if (_selectedOption != null) {
      setState(() => _savedAnswers[_currentQuestion] = _selectedOption!);
    }
  }

  void _toggleMarkForReview() {
    _saveCurrent();
    setState(() {
      _markedForReview[_currentQuestion] = !(_markedForReview[_currentQuestion] ?? false);
    });
  }

  void _clearAnswer() {
    setState(() {
      _savedAnswers.remove(_currentQuestion);
      _selectedOption = null;
    });
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= totalQuestions) return;
    _saveCurrent();
    setQuestionFromApi(index);
  }

  // ── Question Status ───────────────────────────────────────────────────────────

  // 0 = not visited (grey)
  // 1 = answered (green)
  // 2 = marked for review (orange)
  // 3 = answered + marked (purple)
  // 4 = visited but not answered (red)
  int _questionStatus(int index) {
    bool answered = _savedAnswers.containsKey(index);
    bool marked = _markedForReview[index] == true;
    bool visited = _visitedQuestions.contains(index);

    if (answered && marked) return 3;
    if (answered) return 1;
    if (marked) return 2;
    if (visited) return 4;
    return 0;
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.tealGreen;
      case 2:
        return AppColors.orange;
      case 3:
        return AppColors.lightGold;
      case 4:
        return AppColors.red;
      default:
        return AppColors.greyS300;
    }
  }

  // ── Final Submit ──────────────────────────────────────────────────────────────

  void _finalSubmit() async {
    _testTimer?.cancel();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.tealGreen),
                  const SizedBox(height: 16),
                  Text('Submitting test...', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
    );

    Authrepository authRepository = Authrepository(Api_Client.dio);

    // Submit each answered question
    for (int i = 0; i < totalQuestions; i++) {
      final question = _questions[i];
      final List answers = question['answers'] ?? [];
      final int savedAnswer = _savedAnswers[i] ?? -1;
      final int correctIndex = answers.indexWhere((ans) => ans['is_correct'] == true);
      final bool isCorrect = savedAnswer == correctIndex && savedAnswer != -1;
      final int points = question['points'] ?? 0;

      final data = {
        'attempt_id': (question['attempt_id'] ?? 0).toString(),
        'question_id': (question['question_id'] ?? 0).toString(),
        'answer_id': savedAnswer != -1 ? (answers[savedAnswer]['id'] ?? 0).toString() : '0',
        'score': (isCorrect ? points : 0).toString(),
        'is_correct': isCorrect ? '1' : '0',
        'time_spent': '0',
      };

      try {
        await authRepository.submitQuizAnswers(data);
      } catch (e) {
        print('Error submitting question $i: $e');
      }
    }

    // Final submit API
    final lastQuestion = _questions[totalQuestions - 1];
    int totalScore = 0;
    _savedAnswers.forEach((qIndex, aIndex) {
      final q = _questions[qIndex];
      final List ans = q['answers'] ?? [];
      final int correct = ans.indexWhere((a) => a['is_correct'] == true);
      if (aIndex == correct) totalScore += (q['points'] ?? 0) as int;
    });

    final finalData = {'attempt_id': (lastQuestion['attempt_id'] ?? 0).toString(), 'Passingscore': '$totalScore'};

    try {
      final responseData = await authRepository.finalSubmitQuiz(finalData);
      final resultRes = jsonDecode(responseData.data);

      if (mounted) Navigator.pop(context); // close loading

      int correctScore = int.tryParse(resultRes['score'].toString()) ?? 0;
      int correctCount = int.tryParse(resultRes['correctCount'].toString()) ?? 0;
      int total = int.tryParse(resultRes['total_question'].toString()) ?? 0;
      int totalMarks = int.tryParse(resultRes['totalMarks'].toString()) ?? 0;
      int wrongQuestions = int.tryParse(resultRes['wrongQuestions'].toString()) ?? 0;
      int skipped = total - _savedAnswers.length;
      double accuracy = total > 0 ? (correctCount / total) * 100 : 0;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => _buildResultDialog(
                correctScore: correctScore,
                correctCount: correctCount,
                totalQuestions: total,
                wrongQuestions: wrongQuestions,
                totalMarks: totalMarks,
                skipped: skipped,
                accuracy: accuracy,
              ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Error in final submit: $e');
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _testTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty || _currentQuestionData.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.tealGreen),
              const SizedBox(height: 16),
              Text(
                'Loading test...',
                style: TextStyle(color: AppColors.greyS600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildQuestionCard(),
                  _buildOptionsSection(),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: _showExitDialog,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close, color: AppColors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Title + subject
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  widget.testTitle,
                  13,
                  AppColors.white,
                  FontWeight.w700,
                  2,
                  TextAlign.left,
                  0.0,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(widget.subject, style: TextStyle(fontSize: 11, color: AppColors.lightGold)),
                    const SizedBox(width: 8),
                    // MOCK badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.lightGold.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.assignment_outlined, color: AppColors.lightGold, size: 10),
                          const SizedBox(width: 3),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'MOCK TEST',
                            9,
                            AppColors.lightGold,
                            FontWeight.w900,
                            1,
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

          // Timer
          ScaleTransition(
            scale: _totalSeconds <= 60 ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _getTimerColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getTimerColor().withOpacity(0.6), width: 1.5),
              ),
              child: Row(
                children: [
                  // Pause/Resume
                  GestureDetector(
                    onTap: () => setState(() => _isPaused = !_isPaused),
                    child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: AppColors.white, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.timer, color: AppColors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _getTimerText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS BAR ────────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    int answered = _savedAnswers.length;
    double progress = totalQuestions > 0 ? answered / totalQuestions : 0;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                'Q ${_currentQuestion + 1} of $totalQuestions',
                13,
                AppColors.darkNavy,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
              // Stats pills
              Row(
                children: [
                  _buildMiniPill(
                    '${_savedAnswers.length}',
                    AppColors.tealGreen,
                    Icons.check_circle_outline,
                    'Answered',
                  ),
                  const SizedBox(width: 6),
                  _buildMiniPill(
                    '${_markedForReview.values.where((v) => v).length}',
                    AppColors.orange,
                    Icons.bookmark_outline,
                    'Review',
                  ),
                  const SizedBox(width: 6),
                  _buildMiniPill(
                    '${totalQuestions - _visitedQuestions.length}',
                    AppColors.greyS600,
                    Icons.radio_button_unchecked,
                    'Left',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.greyS200,
              valueColor: AlwaysStoppedAnimation(AppColors.tealGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String count, Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ─── QUESTION CARD ────────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    bool isMarked = _markedForReview[_currentQuestion] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isMarked ? Border.all(color: AppColors.orange, width: 2) : null,
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Subject tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: AppColors.tealGreen, size: 12),
                    const SizedBox(width: 5),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      widget.subject,
                      11,
                      AppColors.tealGreen,
                      FontWeight.w700,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Points tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: AppColors.darkNavy, size: 12),
                    const SizedBox(width: 5),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '${_currentQuestionData['points']} Pts',
                      11,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Marked for review indicator
              if (isMarked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark, color: AppColors.orange, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Review',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppRichText.setTextPoppinsStyle(
            context,
            _currentQuestionData['question'] ?? '',
            15,
            AppColors.darkNavy,
            FontWeight.w700,
            10,
            TextAlign.left,
            0.0,
          ),
        ],
      ),
    );
  }

  // ─── OPTIONS ──────────────────────────────────────────────────────────────────

  Widget _buildOptionsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: List.generate(
          (_currentQuestionData['options'] as List).length,
          (index) => _buildOptionCard(String.fromCharCode(65 + index), _currentQuestionData['options'][index], index),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text, int index) {
    bool isSelected = _selectedOption == index;
    bool isSaved = _savedAnswers[_currentQuestion] == index;

    Color backgroundColor = AppColors.white;
    Color borderColor = AppColors.greyS200;
    Color letterBgColor = AppColors.greyS1;

    if (isSelected && !isSaved) {
      // Just selected, not yet saved
      backgroundColor = AppColors.lightGold.withOpacity(0.12);
      borderColor = AppColors.lightGold;
      letterBgColor = AppColors.lightGold;
    } else if (isSaved) {
      // Saved answer
      backgroundColor = AppColors.tealGreen.withOpacity(0.08);
      borderColor = AppColors.tealGreen;
      letterBgColor = AppColors.tealGreen;
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              isSaved
                  ? [
                    BoxShadow(color: AppColors.tealGreen.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3)),
                  ]
                  : isSelected
                  ? [BoxShadow(color: AppColors.lightGold.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))]
                  : [],
        ),
        child: Row(
          children: [
            // Letter circle
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: letterBgColor, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  letter,
                  13,
                  (isSelected || isSaved) ? AppColors.white : AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: AppRichText.setTextPoppinsStyle(
                context,
                text,
                13,
                AppColors.darkNavy,
                FontWeight.w500,
                3,
                TextAlign.left,
                0.0,
              ),
            ),
            // Saved tick
            if (isSaved)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: AppColors.tealGreen, shape: BoxShape.circle),
                child: Icon(Icons.check, color: AppColors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  // ─── ACTION BUTTONS ───────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    bool hasSelection = _selectedOption != null;
    bool isSaved = _savedAnswers.containsKey(_currentQuestion);
    bool isMarked = _markedForReview[_currentQuestion] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Row 1: Mark for Review + Clear
          Row(
            children: [
              // Mark for review
              Expanded(
                child: GestureDetector(
                  onTap: _toggleMarkForReview,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isMarked ? AppColors.orange.withOpacity(0.15) : AppColors.greyS1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isMarked ? AppColors.orange : AppColors.greyS300, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isMarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isMarked ? AppColors.orange : AppColors.greyS600,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isMarked ? 'Marked' : 'Mark Review',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isMarked ? AppColors.orange : AppColors.greyS600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Clear answer
              GestureDetector(
                onTap: isSaved || hasSelection ? _clearAnswer : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: (isSaved || hasSelection) ? AppColors.red.withOpacity(0.08) : AppColors.greyS1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isSaved || hasSelection) ? AppColors.red.withOpacity(0.4) : AppColors.greyS300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.clear,
                        color: (isSaved || hasSelection) ? AppColors.red : AppColors.greyS400,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: (isSaved || hasSelection) ? AppColors.red : AppColors.greyS400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Save & Next button
          GestureDetector(
            onTap: hasSelection ? _saveAndNext : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: hasSelection ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
                color: hasSelection ? null : AppColors.greyS200,
                borderRadius: BorderRadius.circular(14),
                boxShadow:
                    hasSelection
                        ? [
                          BoxShadow(
                            color: AppColors.tealGreen.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ]
                        : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: hasSelection ? AppColors.white : AppColors.greyS500,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    _currentQuestion == totalQuestions - 1 ? 'Save Answer' : 'Save & Next',
                    14,
                    hasSelection ? AppColors.white : AppColors.greyS500,
                    FontWeight.w700,
                    1,
                    TextAlign.left,
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

  // ─── BOTTOM NAVIGATION ────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    bool canGoPrev = _currentQuestion > 0;
    bool canGoNext = _currentQuestion < totalQuestions - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: AppColors.darkNavy.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          // Previous
          _buildNavButton(
            icon: Icons.arrow_back_ios_rounded,
            label: 'Prev',
            enabled: canGoPrev,
            onTap: () => _goToQuestion(_currentQuestion - 1),
            isOutline: true,
          ),
          const SizedBox(width: 10),

          // Question Palette
          Expanded(
            child: GestureDetector(
              onTap: _showQuestionPalette,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkNavy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkNavy.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded, color: AppColors.darkNavy, size: 16),
                    const SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Questions',
                      12,
                      AppColors.darkNavy,
                      FontWeight.w700,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Submit / Next
          if (canGoNext)
            _buildNavButton(
              icon: Icons.arrow_forward_ios_rounded,
              label: 'Next',
              enabled: true,
              onTap: () => _goToQuestion(_currentQuestion + 1),
              isOutline: false,
            )
          else
            _buildNavButton(
              icon: Icons.send_rounded,
              label: 'Submit',
              enabled: true,
              onTap: _showFinalSubmitDialog,
              isOutline: false,
              isSubmit: true,
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    required bool isOutline,
    bool isSubmit = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient:
              (!isOutline && enabled)
                  ? LinearGradient(
                    colors:
                        isSubmit
                            ? [AppColors.tealGreen, AppColors.darkNavy]
                            : [AppColors.darkNavy, AppColors.tealGreen],
                  )
                  : null,
          color: isOutline ? (enabled ? AppColors.white : AppColors.greyS1) : null,
          borderRadius: BorderRadius.circular(12),
          border:
              isOutline ? Border.all(color: enabled ? AppColors.darkNavy.withOpacity(0.3) : AppColors.greyS300) : null,
          boxShadow:
              (!isOutline && enabled)
                  ? [
                    BoxShadow(color: AppColors.tealGreen.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3)),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            if (!isOutline) ...[
              Icon(icon, color: enabled ? AppColors.white : AppColors.greyS400, size: 14),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    isOutline
                        ? (enabled ? AppColors.darkNavy : AppColors.greyS400)
                        : (enabled ? AppColors.white : AppColors.greyS400),
              ),
            ),
            if (isOutline) ...[
              const SizedBox(width: 5),
              Icon(icon, color: enabled ? AppColors.darkNavy : AppColors.greyS400, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  // ─── QUESTION PALETTE ─────────────────────────────────────────────────────────

  void _showQuestionPalette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (_, scrollController) => Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(2)),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'Question Palette',
                            15,
                            AppColors.darkNavy,
                            FontWeight.w800,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close, color: AppColors.greyS600, size: 20),
                          ),
                        ],
                      ),
                    ),
                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          _buildLegend(AppColors.tealGreen, 'Answered'),
                          _buildLegend(AppColors.orange, 'Marked'),
                          _buildLegend(AppColors.lightGold, 'Ans+Mark'),
                          _buildLegend(AppColors.red, 'Visited'),
                          _buildLegend(AppColors.greyS300, 'Not Visited'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Grid
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: totalQuestions,
                        itemBuilder: (_, index) {
                          int status = _questionStatus(index);
                          Color bgColor = _statusColor(status);
                          bool isCurrent = index == _currentQuestion;

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _goToQuestion(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: status == 0 ? AppColors.greyS1 : bgColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent ? AppColors.darkNavy : bgColor,
                                  width: isCurrent ? 2.5 : 1.5,
                                ),
                                boxShadow:
                                    isCurrent
                                        ? [
                                          BoxShadow(
                                            color: AppColors.darkNavy.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                    color:
                                        isCurrent ? AppColors.darkNavy : (status == 0 ? AppColors.greyS600 : bgColor),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Submit button
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showFinalSubmitDialog();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.tealGreen.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, color: AppColors.white, size: 18),
                              const SizedBox(width: 8),
                              AppRichText.setTextPoppinsStyle(
                                context,
                                'Submit Test',
                                14,
                                AppColors.white,
                                FontWeight.w800,
                                1,
                                TextAlign.left,
                                0.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── FINAL SUBMIT CONFIRM ─────────────────────────────────────────────────────

  void _showFinalSubmitDialog() {
    int answered = _savedAnswers.length;
    int unanswered = totalQuestions - answered;

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.send_rounded, color: AppColors.tealGreen, size: 36),
                  ),
                  const SizedBox(height: 16),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Submit Test?',
                    16,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                  const SizedBox(height: 12),
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildSubmitRow('Total Questions', '$totalQuestions', AppColors.darkNavy),
                        _buildSubmitRow('Answered', '$answered', AppColors.tealGreen),
                        _buildSubmitRow(
                          'Not Answered',
                          '$unanswered',
                          unanswered > 0 ? AppColors.red : AppColors.greyS600,
                        ),
                        _buildSubmitRow(
                          'Marked for Review',
                          '${_markedForReview.values.where((v) => v).length}',
                          AppColors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.greyS300, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Review',
                            13,
                            AppColors.greyS700,
                            FontWeight.w600,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _finalSubmit();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: AppRichText.setTextPoppinsStyle(
                                context,
                                'Submit',
                                13,
                                AppColors.white,
                                FontWeight.w800,
                                1,
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
          ),
    );
  }

  Widget _buildSubmitRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ─── RESULT DIALOG ────────────────────────────────────────────────────────────

  Widget _buildResultDialog({
    required int correctScore,
    required int correctCount,
    required int totalQuestions,
    required int wrongQuestions,
    required int totalMarks,
    required int skipped,
    required double accuracy,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(28),
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
              // Trophy
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Icon(Icons.emoji_events, color: AppColors.lightGold, size: 38),
              ),
              const SizedBox(height: 20),
              AppRichText.setTextPoppinsStyle(
                context,
                'Mock Test Completed!',
                17,
                AppColors.darkNavy,
                FontWeight.w900,
                2,
                TextAlign.center,
                0.0,
              ),
              const SizedBox(height: 6),
              AppRichText.setTextPoppinsStyle(
                context,
                'Yeh rahi aapki performance',
                11,
                AppColors.greyS600,
                FontWeight.normal,
                2,
                TextAlign.center,
                0.0,
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultStat('Score', '$correctScore', Icons.stars, AppColors.tealGreen),
                  _buildResultStat('Correct', '$correctCount', Icons.check_circle, AppColors.tealGreen),
                  _buildResultStat('Accuracy', '${accuracy.toInt()}%', Icons.percent, AppColors.darkNavy),
                ],
              ),
              const SizedBox(height: 16),

              // Extra stats
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    _buildSubmitRow('Wrong', '$wrongQuestions', AppColors.red),
                    _buildSubmitRow('Skipped/Unattempted', '$skipped', AppColors.orange),
                    _buildSubmitRow('Total Marks', '$totalMarks', AppColors.darkNavy),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // XP card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightGold.withOpacity(0.3), AppColors.lightGoldS2.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightGold),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'Aapne $correctScore XP kamaye!',
                            13,
                            AppColors.darkNavy,
                            FontWeight.w700,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'Practice karte raho, rank badhao!',
                            10,
                            AppColors.greyS700,
                            FontWeight.normal,
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
              const SizedBox(height: 20),

              // Buttons
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Close',
                        13,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Done',
                            13,
                            AppColors.white,
                            FontWeight.w800,
                            1,
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
      ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.greyS600)),
      ],
    );
  }

  // ─── EXIT DIALOG ──────────────────────────────────────────────────────────────

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 38),
                  ),
                  const SizedBox(height: 16),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Test Chhod dein?',
                    16,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    2,
                    TextAlign.center,
                    0.0,
                  ),
                  const SizedBox(height: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Timer chalta rahega. Aapka progress save nahi hoga.',
                    11,
                    AppColors.greyS600,
                    FontWeight.normal,
                    3,
                    TextAlign.center,
                    0.0,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.greyS300),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Wapas Jao',
                            13,
                            AppColors.greyS700,
                            FontWeight.w600,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'Exit',
                            13,
                            AppColors.white,
                            FontWeight.w700,
                            1,
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
