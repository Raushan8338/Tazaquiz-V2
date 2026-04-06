import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
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

  // ── Page-local language override ──────────────────────────────────────────
  String? _localLang;
  late final String _globalLang;

  static const _languages = [
    {'code': 'en', 'native': 'English', 'label': 'English'},
    {'code': 'hi', 'native': 'हिंदी', 'label': 'Hindi'},
    {'code': 'mr', 'native': 'मराठी', 'label': 'Marathi'},
    {'code': 'bn', 'native': 'বাংলা', 'label': 'Bengali'},
    {'code': 'ta', 'native': 'தமிழ்', 'label': 'Tamil'},
    {'code': 'te', 'native': 'తెలుగు', 'label': 'Telugu'},
    {'code': 'gu', 'native': 'ગુજરાતી', 'label': 'Gujarati'},
    {'code': 'kn', 'native': 'ಕನ್ನಡ', 'label': 'Kannada'},
    {'code': 'ml', 'native': 'മലയാളം', 'label': 'Malayalam'},
    {'code': 'pa', 'native': 'ਪੰਜਾਬੀ', 'label': 'Punjabi'},
    {'code': 'ur', 'native': 'اردو', 'label': 'Urdu'},
  ];

  String get _effectiveLang => _localLang ?? _globalLang;
  bool get _isLocalOverrideActive => _localLang != null && _localLang != _globalLang;

  @override
  void initState() {
    super.initState();
    _globalLang = TranslationService.instance.currentLanguage;
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _getUserData();
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _animationController.dispose();
    if (_isLocalOverrideActive) TranslationService.instance.setLanguage(_globalLang);
    super.dispose();
  }

  void _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    loadQuizData();
    _totalSeconds = widget.timeLimit * 60;
  }

  void loadQuizData() async {
    final data = {'user_id': _user?.id, 'quiz_id': widget.Quiz_id, 'score': ''};
    final responseFuture = await Authrepository(Api_Client.dio).fetchQuizQuestion(data);
    final Map<String, dynamic> apiResponse =
        responseFuture.data is String
            ? jsonDecode(responseFuture.data)
            : Map<String, dynamic>.from(responseFuture.data);
    _questions = apiResponse['questions'] ?? [];
    totalQuestions = _questions.length;
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
      _selectedOption = _savedAnswers[index];
      _currentQuestionData = {
        'question': question['question_text'],
        'options': answers.map((a) => a['answer_text']).toList(),
        'correctAnswer': correctIndex == -1 ? 0 : correctIndex,
        'difficulty': question['difficulty_level'] ?? 'Medium',
        'points': question['points'] ?? 0,
        'attempt_id': question['attempt_id'] ?? 0,
        'question_ans_id': question['question_ans_id'] ?? 0,
        'question_id': question['question_id'] ?? 0,
        'is_translation_allowed': (question['is_translation_allowed'] ?? 0).toString(),
        'answer_ids':
            answers.map((a) {
              final id =
                  a['id'] ??
                  a['answer_id'] ??
                  a['ans_id'] ??
                  a['ID'] ??
                  a['answerId'] ??
                  a['optionId'] ??
                  a['option_id'];
              return id?.toString() ?? '0';
            }).toList(),
      };
    });
  }

  // ── Check model downloaded, show popup if not ─────────────────────────────
  Future<void> _applyLocalLang(String code) async {
    if (code == _effectiveLang) return;

    if (code != 'en') {
      final modelManager = OnDeviceTranslatorModelManager();
      final mlCodeMap = {
        'hi': 'hi',
        'mr': 'mr',
        'bn': 'bn',
        'ta': 'ta',
        'te': 'te',
        'gu': 'gu',
        'kn': 'kn',
        'ml': 'ml',
        'pa': 'pa',
        'ur': 'ur',
      };
      final mlCode = mlCodeMap[code];
      if (mlCode != null) {
        final isDownloaded = await modelManager.isModelDownloaded(mlCode);
        if (!isDownloaded && mounted) {
          final langName =
              _languages.firstWhere((l) => l['code'] == code, orElse: () => {'native': code})['native'] ?? code;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _ModelDownloadPopup(langName: langName),
          );
          await TranslationService.instance.setLanguage(code);
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
        } else {
          await TranslationService.instance.setLanguage(code);
        }
      } else {
        await TranslationService.instance.setLanguage(code);
      }
    } else {
      await TranslationService.instance.setLanguage(code);
    }

    if (mounted) setState(() => _localLang = code == _globalLang ? null : code);
  }

  Future<void> _resetToGlobal() async {
    await TranslationService.instance.setLanguage(_globalLang);
    setState(() => _localLang = null);
  }

  void _showLangSheet() {
    final wasRunning = !_isPaused;
    if (wasRunning) setState(() => _isPaused = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _LangPickerSheet(
            languages: _languages,
            activeLang: _effectiveLang,
            globalLang: _globalLang,
            onSelect: (code) async {
              Navigator.pop(context);
              await _applyLocalLang(code);
              if (wasRunning && mounted) setState(() => _isPaused = false);
            },
            onReset: () async {
              Navigator.pop(context);
              await _resetToGlobal();
              if (wasRunning && mounted) setState(() => _isPaused = false);
            },
          ),
    ).then((_) {
      if (wasRunning && mounted) setState(() => _isPaused = false);
    });
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
    int h = _totalSeconds ~/ 3600, m = (_totalSeconds % 3600) ~/ 60, s = _totalSeconds % 60;
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
    } else
      _goToQuestion(_currentQuestion + 1);
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
    bool answered = _savedAnswers.containsKey(index),
        marked = _markedForReview[index] == true,
        visited = _visitedQuestions.contains(index);
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
    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < totalQuestions; i++) {
      final question = _questions[i];
      final List answers = question['answers'] ?? [];
      final int savedAnswer = _savedAnswers[i] ?? -1;
      final int correctIndex = answers.indexWhere((ans) => ans['is_correct'] == true);
      final bool isCorrect = savedAnswer != -1 && savedAnswer == correctIndex;
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
      try {
        await Authrepository(Api_Client.dio).submitQuizAnswers({
          'attempt_id': (question['attempt_id'] ?? 0).toString(),
          'question_id': (question['question_id'] ?? 0).toString(),
          'answer_id': answerId,
          'score': (isCorrect ? (question['points'] ?? 0) : 0).toString(),
          'is_correct': isCorrect ? '1' : '0',
          'time_spent': '1',
        });
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
      if (aIndex == ans.indexWhere((a) => a['is_correct'] == true)) totalScore += (q['points'] ?? 0) as int;
    });

    try {
      await Authrepository(
        Api_Client.dio,
      ).finalSubmitQuiz({'attempt_id': (lastQuestion['attempt_id'] ?? 0).toString(), 'Passingscore': '$totalScore'});
      setState(() {
        _submitProgress = 1.0;
        _submitStatusText = 'Test submitted successfully!';
      });
      await Future.delayed(const Duration(milliseconds: 700));
      if (_isLocalOverrideActive) await TranslationService.instance.setLanguage(_globalLang);
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
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      print('Error final submit: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed. Please try again.'), backgroundColor: AppColors.red));
      }
    }
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
              Text(
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
                Text(
                  _submitProgress >= 1.0 ? 'Test Submitted!' : 'Submitting Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _submitStatusText,
                  style: TextStyle(fontSize: 12, color: AppColors.white.withOpacity(0.55)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions submitted',
                      style: TextStyle(fontSize: 12, color: AppColors.white.withOpacity(0.55)),
                    ),
                    Text(
                      '$_submittedCount / $totalQuestions',
                      style: TextStyle(fontSize: 13, color: AppColors.tealGreen, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          height: 10,
                          width: constraints.maxWidth * _submitProgress.clamp(0.0, 1.0),
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
                Text(
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
                    Container(height: 36, width: 1, color: AppColors.white.withOpacity(0.1)),
                    _buildOverlayStat(
                      '${totalQuestions - _savedAnswers.length}',
                      'Skipped',
                      Icons.radio_button_unchecked,
                      AppColors.orange,
                    ),
                    Container(height: 36, width: 1, color: AppColors.white.withOpacity(0.1)),
                    _buildOverlayStat(
                      '${_markedForReview.values.where((v) => v).length}',
                      'Marked',
                      Icons.bookmark_outline,
                      AppColors.lightGold,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
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
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.white.withOpacity(0.5), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final activeLangMap = _languages.firstWhere(
      (l) => l['code'] == _effectiveLang,
      orElse: () => {'code': 'en', 'native': 'English', 'label': 'English'},
    );
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
      ),
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
                              Text(
                                'MOCK TEST',
                                style: TextStyle(fontSize: 9, color: AppColors.lightGold, fontWeight: FontWeight.w900),
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
          const SizedBox(height: 10),
          // Language bar
          GestureDetector(
            onTap: _showLangSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _isLocalOverrideActive ? AppColors.white.withOpacity(0.15) : AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isLocalOverrideActive ? AppColors.white.withOpacity(0.4) : AppColors.white.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.translate_rounded, size: 14, color: AppColors.white.withOpacity(0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLocalOverrideActive
                              ? 'Page language (tap to change)'
                              : 'View questions in… (tap to change)',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              activeLangMap['native'] ?? 'English',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            if (_isLocalOverrideActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.tealGreen.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Page only',
                                  style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      _isLocalOverrideActive ? 'Change' : 'Select',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
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

  Widget _buildProgressBar() {
    double progress = totalQuestions > 0 ? _savedAnswers.length / totalQuestions : 0;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Q ${_currentQuestion + 1} of $totalQuestions',
                style: TextStyle(fontSize: 13, color: AppColors.darkNavy, fontWeight: FontWeight.w700),
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
          Text(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    bool isMarked = _markedForReview[_currentQuestion] == true;
    final isTranslationAllowed = _currentQuestionData['is_translation_allowed'] == '1';
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
                    Text(
                      widget.subject,
                      style: TextStyle(fontSize: 11, color: AppColors.tealGreen, fontWeight: FontWeight.w700),
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
                    Text(
                      '${_currentQuestionData['points']} Pts',
                      style: TextStyle(fontSize: 11, color: AppColors.darkNavy, fontWeight: FontWeight.w700),
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
          // ── ONLY question text translates ──────────────────────────────────
          isTranslationAllowed
              ? Text(
                _currentQuestionData['question'] ?? '',
                style: TextStyle(fontSize: 15, color: AppColors.darkNavy, fontWeight: FontWeight.w700, height: 1.4),
              )
              : TranslatedText(
                _currentQuestionData['question'] ?? '',
                key: ValueKey('mock_q_${_effectiveLang}_$_currentQuestion'),
                style: TextStyle(fontSize: 15, color: AppColors.darkNavy, fontWeight: FontWeight.w700, height: 1.4),
              ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    final options = _currentQuestionData['options'] as List? ?? [];
    final isTranslationAllowed = _currentQuestionData['is_translation_allowed'] == '1';
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          options.length,
          (i) => _buildOptionCard(String.fromCharCode(65 + i), options[i].toString(), i, isTranslationAllowed),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text, int index, bool isTranslationAllowed) {
    bool isSelected = _selectedOption == index;
    bool isSaved = _savedAnswers[_currentQuestion] == index;
    Color backgroundColor = AppColors.white, borderColor = AppColors.greyS200, letterBgColor = AppColors.greyS1;
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
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
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 13,
                    color: (isSelected || isSaved) ? AppColors.white : AppColors.darkNavy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              // ── ONLY option text translates ──────────────────────────────
              child:
                  isTranslationAllowed
                      ? Text(
                        text,
                        style: TextStyle(fontSize: 13, color: AppColors.darkNavy, fontWeight: FontWeight.w500),
                      )
                      : TranslatedText(
                        text,
                        key: ValueKey('mock_opt_${_effectiveLang}_${_currentQuestion}_$index'),
                        style: TextStyle(fontSize: 13, color: AppColors.darkNavy, fontWeight: FontWeight.w500),
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
    bool hasSelection = _selectedOption != null,
        isSaved = _savedAnswers.containsKey(_currentQuestion),
        isMarked = _markedForReview[_currentQuestion] == true;
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
                  Text(
                    _currentQuestion == totalQuestions - 1 ? 'Save & Submit' : 'Save & Next',
                    style: TextStyle(
                      fontSize: 14,
                      color: (hasSelection || isSaved) ? AppColors.white : AppColors.greyS500,
                      fontWeight: FontWeight.w700,
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

  Widget _buildBottomNav() {
    bool canGoPrev = _currentQuestion > 0, canGoNext = _currentQuestion < totalQuestions - 1;
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
                    Text(
                      'Questions',
                      style: TextStyle(fontSize: 12, color: AppColors.darkNavy, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          canGoNext
              ? _buildNavButton(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'Next',
                enabled: true,
                onTap: () => _goToQuestion(_currentQuestion + 1),
                isOutline: false,
              )
              : _buildNavButton(
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
                          Text(
                            'Question Palette',
                            style: TextStyle(fontSize: 15, color: AppColors.darkNavy, fontWeight: FontWeight.w800),
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
                              Text(
                                'Submit Test',
                                style: TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.w800),
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
    int answered = _savedAnswers.length, unanswered = totalQuestions - answered;
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
                  Text(
                    'Submit Test?',
                    style: TextStyle(fontSize: 16, color: AppColors.darkNavy, fontWeight: FontWeight.w800),
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
                          child: Text(
                            'Review',
                            style: TextStyle(fontSize: 13, color: AppColors.greyS700, fontWeight: FontWeight.w600),
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
                              child: Text(
                                'Submit',
                                style: TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w800),
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
                  Text(
                    'Test Chhod dein?',
                    style: TextStyle(fontSize: 16, color: AppColors.darkNavy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Timer chalta rahega. Aapka progress save nahi hoga.',
                    style: TextStyle(fontSize: 11, color: AppColors.greyS600),
                    textAlign: TextAlign.center,
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
                          child: Text(
                            'Wapas Jao',
                            style: TextStyle(fontSize: 13, color: AppColors.greyS700, fontWeight: FontWeight.w600),
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
                          child: Text(
                            'Exit',
                            style: TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w700),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Model Download Popup  (shared by Live & Mock)
// ─────────────────────────────────────────────────────────────────────────────
class _ModelDownloadPopup extends StatefulWidget {
  final String langName;
  const _ModelDownloadPopup({required this.langName});
  @override
  State<_ModelDownloadPopup> createState() => _ModelDownloadPopupState();
}

class _ModelDownloadPopupState extends State<_ModelDownloadPopup> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A4A4A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _anim,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D6E6E).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFF0D6E6E), width: 2),
                ),
                child: const Icon(Icons.download_rounded, color: Color(0xFF14A3A3), size: 30),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Downloading Language Model',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.langName} is being downloaded for the first time. Please wait…',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), height: 1.5),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                backgroundColor: Color(0x33FFFFFF),
                valueColor: AlwaysStoppedAnimation(Color(0xFF14A3A3)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF14A3A3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'One-time download (~10MB). Future use will be instant.',
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Language Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LangPickerSheet extends StatelessWidget {
  final List<Map<String, String>> languages;
  final String activeLang;
  final String globalLang;
  final ValueChanged<String> onSelect;
  final VoidCallback onReset;

  const _LangPickerSheet({
    required this.languages,
    required this.activeLang,
    required this.globalLang,
    required this.onSelect,
    required this.onReset,
  });

  static const _teal = Color(0xFF0D6E6E);
  static const _tealBg = Color(0xFFE1F5EE);
  static const _tealLight = Color(0xFF14A3A3);
  static const _darkNavy = Color(0xFF0A4A4A);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _teal.withOpacity(0.3)),
                ),
                child: const Icon(Icons.translate_rounded, size: 18, color: _teal),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Page Language',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                  ),
                  Text('Only questions & answers will translate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activeLang != globalLang) ...[
            GestureDetector(
              onTap: onReset,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, size: 15, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reset to app language (${_nativeOf(globalLang)})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7D5200), fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.amber),
                  ],
                ),
              ),
            ),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.35,
            ),
            itemCount: languages.length,
            itemBuilder: (_, i) {
              final lang = languages[i];
              final code = lang['code']!;
              final isActive = code == activeLang;
              final isGlobal = code == globalLang;
              return GestureDetector(
                onTap: () => onSelect(code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isActive ? _darkNavy : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? _teal : Colors.grey.withOpacity(0.2),
                      width: isActive ? 1.8 : 1,
                    ),
                    boxShadow:
                        isActive
                            ? [BoxShadow(color: _teal.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 3))]
                            : [],
                  ),
                  child: Stack(
                    children: [
                      if (isGlobal && !isActive)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: _tealLight, shape: BoxShape.circle),
                          ),
                        ),
                      if (isActive)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                          ),
                        ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang['native']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : const Color(0xFF1A1A2E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? _teal.withOpacity(0.2) : _tealBg.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  lang['label']!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isActive ? const Color(0xFF5DCAA5) : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: _tealBg.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 13, color: _teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only questions & answers translate. Scores, timer and UI stay as-is.',
                    style: TextStyle(fontSize: 11, color: _darkNavy, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _nativeOf(String code) =>
      languages.firstWhere((l) => l['code'] == code, orElse: () => {'native': code})['native'] ?? code;
}
