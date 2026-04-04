import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/language_selectionPage.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/quiz_review_page.dart';
import 'dart:async';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class MockTestScreen extends StatefulWidget {
  final String testTitle;
  final String subject;
  final String Quiz_id;
  final int timeLimit;

  MockTestScreen({required this.testTitle, required this.subject, required this.Quiz_id, required this.timeLimit});

  @override
  _MockTestScreenState createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> with SingleTickerProviderStateMixin {
  int _currentQuestion = 0;
  List<dynamic> _questions = [];
  int totalQuestions = 0;
  Map<String, dynamic> _currentQuestionData = {};
  // ── ADDED ──────────────────────────────────
  Map<String, dynamic> _translatedQuestionData = {};

  Map<int, int> _savedAnswers = {};
  Map<int, bool> _markedForReview = {};
  Set<int> _visitedQuestions = {};

  int _totalSeconds = 0;
  Timer? _testTimer;
  bool _isPaused = false;

  int? _selectedOption;
  bool _isLoading = true;

  bool _isSubmitting = false;
  double _submitProgress = 0.0;
  String _submitStatusText = 'Preparing submission...';
  int _submittedCount = 0;

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

  void _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    loadQuizData();
    _totalSeconds = widget.timeLimit * 60;
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

    // int timeLimitMinutes = int.tryParse(apiResponse['time_limit']?.toString() ?? '30') ?? 30;
    // _totalSeconds = timeLimitMinutes * 60;

    if (_questions.isNotEmpty) {
      setQuestionFromApi(0);
      _startTestTimer();
    }

    setState(() => _isLoading = false);
  }

  // ── MODIFIED: translate karo ────────────────
  void setQuestionFromApi(int index) {
    final question = _questions[index];
    final List answers = question['answers'] ?? [];
    int correctIndex = answers.indexWhere((ans) => ans['is_correct'] == true);

    _visitedQuestions.add(index);

    final raw = {
      'question': question['question_text'],
      'options': answers.map((a) => a['answer_text']).toList(),
      'correctAnswer': correctIndex == -1 ? 0 : correctIndex,
      'difficulty': question['difficulty_level'] ?? 'Medium',
      'points': question['points'] ?? 0,
      'attempt_id': question['attempt_id'] ?? 0,
      'question_ans_id': question['question_ans_id'] ?? 0,
      'question_id': question['question_id'] ?? 0,
      'answer_ids':
          answers.map((a) {
            final id =
                a['id'] ?? a['answer_id'] ?? a['ans_id'] ?? a['ID'] ?? a['answerId'] ?? a['optionId'] ?? a['option_id'];
            return id?.toString() ?? '0';
          }).toList(),
    };

    setState(() {
      _currentQuestion = index;
      _currentQuestionData = raw;
      _translatedQuestionData = raw; // pehle original
      _selectedOption = _savedAnswers[index];
    });

    _translateCurrentQuestion(raw); // background translate
  }

  // ── ADDED ──────────────────────────────────
  Future<void> _translateCurrentQuestion(Map<String, dynamic> raw) async {
    final lang = TranslationService.instance.currentLanguage;
    if (lang == 'en') return;

    try {
      final List<String> optionTexts = (raw['options'] as List).map((o) => o.toString()).toList();
      final toTranslate = [raw['question'] ?? '', ...optionTexts];
      final results = await TranslationService.instance.translateBatch(toTranslate.cast<String>());

      if (mounted) {
        setState(() {
          _translatedQuestionData = {...raw, 'question': results[0], 'options': results.sublist(1)};
        });
      }
    } catch (_) {}
  }

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
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_totalSeconds <= 60) return AppColors.red;
    if (_totalSeconds <= 300) return AppColors.orange;
    return AppColors.tealGreen;
  }

  void _selectOption(int index) => setState(() => _selectedOption = index);

  void _saveAndNext() {
    if (_selectedOption != null) _savedAnswers[_currentQuestion] = _selectedOption!;
    if (_currentQuestion == totalQuestions - 1) {
      setState(() {});
      _showFinalSubmitDialog();
    } else {
      _goToQuestion(_currentQuestion + 1);
    }
  }

  void _saveCurrent() {
    if (_selectedOption != null) setState(() => _savedAnswers[_currentQuestion] = _selectedOption!);
  }

  void _toggleMarkForReview() {
    _saveCurrent();
    setState(() => _markedForReview[_currentQuestion] = !(_markedForReview[_currentQuestion] ?? false));
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

  void _finalSubmit() async {
    _testTimer?.cancel();
    setState(() {
      _isSubmitting = true;
      _submitProgress = 0.0;
      _submittedCount = 0;
      _submitStatusText = 'Preparing submission...';
    });

    Authrepository authRepository = Authrepository(Api_Client.dio);
    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < totalQuestions; i++) {
      final question = _questions[i];
      final List answers = question['answers'] ?? [];
      final int savedAnswer = _savedAnswers[i] ?? -1;
      final int correctIndex = answers.indexWhere((ans) => ans['is_correct'] == true);
      final bool isCorrect = savedAnswer != -1 && savedAnswer == correctIndex;
      final int points = question['points'] ?? 0;

      String answerId = '0';
      if (savedAnswer != -1 && savedAnswer < answers.length) {
        final ans = answers[savedAnswer] as Map;
        final ansId =
            ans['id'] ??
            ans['answer_id'] ??
            ans['ans_id'] ??
            ans['ID'] ??
            ans['answerId'] ??
            ans['optionId'] ??
            ans['option_id'];
        answerId = (ansId != null) ? ansId.toString() : '0';
      }

      final data = {
        'attempt_id': (question['attempt_id'] ?? 0).toString(),
        'question_id': (question['question_id'] ?? 0).toString(),
        'answer_id': answerId,
        'score': (isCorrect ? points : 0).toString(),
        'is_correct': isCorrect ? '1' : '0',
        'time_spent': '1',
      };

      try {
        var response = await authRepository.submitQuizAnswers(data);
        print('Response Q$i: ${response.data}');
      } catch (e) {
        print('Error Q$i: $e');
      }

      setState(() {
        _submittedCount = i + 1;
        _submitProgress = (i + 1) / totalQuestions;
        _submitStatusText = 'Submitting question ${i + 1} of $totalQuestions...';
      });
      await Future.delayed(const Duration(milliseconds: 80));
    }

    setState(() {
      _submitProgress = 0.95;
      _submitStatusText = 'Finalizing your result...';
    });

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

      setState(() {
        _submitProgress = 1.0;
        _submitStatusText = 'Test submitted successfully!';
      });
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        setState(() => _isSubmitting = false);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (_) => QuizReviewPage(
                  attemptId: int.tryParse(lastQuestion['attempt_id'].toString()) ?? 0,
                  userId: int.tryParse(_user!.id.toString()) ?? 0,
                  quizTitle: widget.testTitle,
                  pageType: 4,
                ),
          ),
          (route) => route.isFirst, // 🔥 IMPORTANT (sab clear karega)
        );
      }
    } catch (e) {
      print('Error in final submit: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('Submission failed. Please try again.'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

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
              TranslatedText(
                'Loading test...',
                style: TextStyle(color: AppColors.greyS600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.greyS1,
          body: Stack(
            children: [
              Column(
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
              // ── ADDED: Translation toast ──
              // const TranslationToast(),
            ],
          ),
        ),
        if (_isSubmitting) _buildSubmitOverlay(),
      ],
    );
  }

  Widget _buildSubmitOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tealGreen.withOpacity(0.15),
                    border: Border.all(color: AppColors.tealGreen.withOpacity(0.5), width: 2),
                  ),
                  child:
                      _submitProgress >= 1.0
                          ? Icon(Icons.check_rounded, color: AppColors.tealGreen, size: 34)
                          : Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(value: null, color: AppColors.tealGreen, strokeWidth: 2.5),
                          ),
                ),
                const SizedBox(height: 16),
                TranslatedText(
                  _submitProgress >= 1.0 ? 'Test Submitted!' : 'Submitting Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
                const SizedBox(height: 6),
                TranslatedText(
                  _submitStatusText,
                  style: TextStyle(fontSize: 12, color: AppColors.white.withOpacity(0.55)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TranslatedText(
                      'Questions submitted',
                      style: TextStyle(fontSize: 12, color: AppColors.white.withOpacity(0.55)),
                    ),
                    TranslatedText(
                      '$_submittedCount / $totalQuestions',
                      style: TextStyle(fontSize: 13, color: AppColors.tealGreen, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          width: barWidth,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          height: 10,
                          width: barWidth * _submitProgress.clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.tealGreen, const Color(0xFF00E5CC)]),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.5), blurRadius: 8)],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TranslatedText(
                  '${(_submitProgress * 100).toInt()}% complete',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOverlayStat(
                      '${_savedAnswers.length}',
                      'Answered',
                      Icons.check_circle_outline,
                      AppColors.tealGreen,
                    ),
                    _buildOverlayDivider(),
                    _buildOverlayStat(
                      '${totalQuestions - _savedAnswers.length}',
                      'Skipped',
                      Icons.radio_button_unchecked,
                      AppColors.orange,
                    ),
                    _buildOverlayDivider(),
                    _buildOverlayStat(
                      '${_markedForReview.values.where((v) => v).length}',
                      'Marked',
                      Icons.bookmark_outline,
                      AppColors.lightGold,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TranslatedText(
                  'Please do not close the app',
                  style: TextStyle(fontSize: 10, color: AppColors.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        TranslatedText(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 2),
        TranslatedText(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.white.withOpacity(0.5), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildOverlayDivider() => Container(height: 36, width: 1, color: AppColors.white.withOpacity(0.1));

  Widget _buildHeader() {
    // ── ADDED: language vars ──────────────────
    final langCode = TranslationService.instance.currentLanguage;
    final langNative = TranslationService.supportedLanguages[langCode]?['native'] ?? 'English';

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      // ── MODIFIED: Column wrap for language bar ──
      child: Column(
        children: [
          Row(
            children: [
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
                      GestureDetector(
                        onTap: () => setState(() => _isPaused = !_isPaused),
                        child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: AppColors.white, size: 16),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.timer, color: AppColors.white, size: 14),
                      const SizedBox(width: 4),
                      TranslatedText(
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

          const SizedBox(height: 10),

          // ── ADDED: Language change bar ────────
          GestureDetector(
            onTap: () async {
              _isPaused = true; // pause timer
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LanguageSelectionPage(showSkip: false, onDone: () => Navigator.pop(context)),
                ),
              );
              if (mounted) {
                _isPaused = false;
                _translateCurrentQuestion(_currentQuestionData);
                setState(() {});
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.white.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.translate_rounded, size: 14, color: AppColors.white.withOpacity(0.9)),
                      const SizedBox(width: 8),
                      Text(
                        'Content Language:  $langNative',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tealGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Changing language may take up to 40 seconds. Please wait.',
                    style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          TranslatedText(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

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
                      TranslatedText(
                        'Review',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // ── MODIFIED: translated question ──
          AppRichText.setTextPoppinsStyle(
            context,
            _translatedQuestionData['question'] ?? '',
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

  Widget _buildOptionsSection() {
    // ── MODIFIED: translated options ──
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: List.generate(
          (_translatedQuestionData['options'] as List).length,
          (index) =>
              _buildOptionCard(String.fromCharCode(65 + index), _translatedQuestionData['options'][index], index),
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
      backgroundColor = AppColors.lightGold.withOpacity(0.12);
      borderColor = AppColors.lightGold;
      letterBgColor = AppColors.lightGold;
    } else if (isSaved) {
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

  Widget _buildActionButtons() {
    bool hasSelection = _selectedOption != null;
    bool isSaved = _savedAnswers.containsKey(_currentQuestion);
    bool isMarked = _markedForReview[_currentQuestion] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
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
                        TranslatedText(
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
                      TranslatedText(
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
          GestureDetector(
            onTap: (hasSelection || isSaved) ? _saveAndNext : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient:
                    (hasSelection || isSaved)
                        ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy])
                        : null,
                color: (hasSelection || isSaved) ? null : AppColors.greyS200,
                borderRadius: BorderRadius.circular(14),
                boxShadow:
                    (hasSelection || isSaved)
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
                    _currentQuestion == totalQuestions - 1 ? Icons.send_rounded : Icons.check_circle_outline,
                    color: (hasSelection || isSaved) ? AppColors.white : AppColors.greyS500,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    _currentQuestion == totalQuestions - 1 ? 'Save & Submit' : 'Save & Next',
                    14,
                    (hasSelection || isSaved) ? AppColors.white : AppColors.greyS500,
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
          _buildNavButton(
            icon: Icons.arrow_back_ios_rounded,
            label: 'Prev',
            enabled: canGoPrev,
            onTap: () => _goToQuestion(_currentQuestion - 1),
            isOutline: true,
          ),
          const SizedBox(width: 10),
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
            TranslatedText(
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
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(2)),
                    ),
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
                                child: TranslatedText(
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
          TranslatedText(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
          TranslatedText(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
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
        TranslatedText(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 3),
        TranslatedText(label, style: TextStyle(fontSize: 11, color: AppColors.greyS600)),
      ],
    );
  }

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
