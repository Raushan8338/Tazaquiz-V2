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

class LiveTestScreen extends StatefulWidget {
  final String testTitle;
  final String subject;
  final String Quiz_id;
  final int timeLimit;

  LiveTestScreen({
    required this.testTitle,
    required this.subject,
    required this.Quiz_id,
    required this.timeLimit,
  });

  @override
  _LiveTestScreenState createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestion = 0;
  List<dynamic> _questions = [];
  int totalQuestions = 0;
  int _timeLeft = 30;
  int _perQuestionTime = 30;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctAnswer = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Saves selected answer per question index so Previous restores it
  Map<int, int?> _savedAnswers = {};

  Map<String, dynamic> _currentQuestionData = {};
  UserModel? _user;

  // ── Language state ──────────────────────────────────────────────────────────
  // _activeLang is single source of truth. Changing it forces TranslatedText
  // widgets to rebuild via their ValueKey.
  late String _activeLang;
  late final String _globalLang;
  bool _isOverride = false;

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

  static const _mlCodeMap = {
    'hi': 'hi', 'mr': 'mr', 'bn': 'bn', 'ta': 'ta',
    'te': 'te', 'gu': 'gu', 'kn': 'kn', 'ml': 'ml',
    'pa': 'pa', 'ur': 'ur',
  };

  @override
  void initState() {
    super.initState();
    _globalLang = TranslationService.instance.currentLanguage;
    _activeLang = _globalLang;
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _getUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    if (_isOverride) TranslationService.instance.setLanguage(_globalLang);
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  void _getUserData() async {
    _user = await SessionManager.getUser();
    if (mounted) setState(() {});
    await loadQuizData();
  }

  Future<void> loadQuizData() async {
    int retryCount = 0;
    const maxRetries = 3;
    while (retryCount < maxRetries) {
      try {
        final data = {
          'user_id': _user?.id,
          'quiz_id': widget.Quiz_id,
          'score': ''
        };
        final responseFuture =
            await Authrepository(Api_Client.dio).fetchQuizQuestion(data);
        final Map<String, dynamic> apiResponse =
            responseFuture.data is String
                ? jsonDecode(responseFuture.data)
                : Map<String, dynamic>.from(responseFuture.data);
        _questions = apiResponse['questions'] ?? [];
        totalQuestions = _questions.length;
        if (_questions.isNotEmpty) {
          _calculatePerQuestionTime();
          setQuestionFromApi(0);
          _startTimer();
        }
        break;
      } catch (e) {
        retryCount++;
        print('❌ Retry $retryCount/$maxRetries failed: $e');
      }
    }
  }

  void _calculatePerQuestionTime() {
    if (totalQuestions <= 0 || widget.timeLimit <= 0) {
      _perQuestionTime = 30;
      return;
    }
    int totalSeconds = widget.timeLimit * 60;
    _perQuestionTime = (totalSeconds / totalQuestions).floor().clamp(10, 120);
  }

  void setQuestionFromApi(int index) {
    final question = _questions[index];
    final List answers = question['answers'] ?? [];
    int correctIndex = answers.indexWhere((ans) => ans['is_correct'] == true);

    setState(() {
      _currentQuestion = index;
      _correctAnswer = correctIndex == -1 ? 0 : correctIndex;
      _selectedOption = _savedAnswers[index]; // restore saved answer
      _currentQuestionData = {
        'question': question['question_text'],
        'options': answers.map((a) => a['answer_text']).toList(),
        'correctAnswer': correctIndex == -1 ? 0 : correctIndex,
        'difficulty': question['difficulty_level'] ?? 'Medium',
        'points': question['points'] ?? 0,
        'attempt_id': question['attempt_id'] ?? 0,
        'question_ans_id': question['question_ans_id'] ?? 0,
        'question_id': question['question_id'] ?? 0,
        'is_translation_allowed':
            (question['is_translation_allowed'] ?? 0).toString(),
      };
    });
  }

  // ── Timer ──────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _perQuestionTime;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
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

  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
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

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Language change ────────────────────────────────────────────────────────
  Future<void> _applyLang(String code) async {
  if (code == _activeLang) return;

  _pauseTimer();

  final mlCode = _mlCodeMap[code];
  bool needsDownload = false;

  if (mlCode != null) {
    final modelManager = OnDeviceTranslatorModelManager();
    needsDownload = !(await modelManager.isModelDownloaded(mlCode));
  }

  if (needsDownload && mounted) {
    final langName = _languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'native': code},
    )['native'] ?? code;

    final completer = Completer<void>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ModelDownloadPopup(
        langName: langName,
        langCode: code,
        onDownloadComplete: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    await completer.future;

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    // ✅ KEY FIX: Popup ne model download kiya,
    // ab parent explicitly setLanguage call karta hai
    // taaki TranslatedText rebuild hone se pehle
    // TranslationService ka state ready ho
    await TranslationService.instance.setLanguage(code);
  } else {
    await TranslationService.instance.setLanguage(code);
  }

  if (mounted) {
    setState(() {
      _activeLang = code;
      _isOverride = code != _globalLang;
    });
  }

  if (mounted && !_answered && _timeLeft > 0) {
    _resumeTimer();
  }
}

  Future<void> _resetToGlobal() async {
    if (_activeLang == _globalLang) return;
    _pauseTimer();
    await TranslationService.instance.setLanguage(_globalLang);
    if (mounted) {
      setState(() {
        _activeLang = _globalLang;
        _isOverride = false;
      });
    }
    if (mounted && !_answered && _timeLeft > 0) _resumeTimer();
  }

  // ── Answer handling ────────────────────────────────────────────────────────
  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _savedAnswers[_currentQuestion] = index;
    });
  }

  void _submitAnswer() async {
    if (_selectedOption == null || _answered) return;
    setState(() {
      _answered = true;
      _timer?.cancel();
      if (_selectedOption == _correctAnswer)
        _score += _currentQuestionData['points'] as int;
    });
    final data = {
      'attempt_id': _currentQuestionData['attempt_id'].toString(),
      'question_id': _currentQuestionData['question_id'].toString(),
      'answer_id': _currentQuestionData['question_ans_id'].toString(),
      'score': (_selectedOption == _correctAnswer
              ? _currentQuestionData['points']
              : 0)
          .toString(),
      'is_correct': (_selectedOption == _correctAnswer ? '1' : '0'),
      'time_spent': (_perQuestionTime - _timeLeft).toString(),
    };
    try {
      await Authrepository(Api_Client.dio).submitQuizAnswers(data);
    } catch (e) {
      print('Submit error: $e');
    }
    Future.delayed(Duration(milliseconds: 500), () => _nextQuestion());
  }

  void _autoSubmit() async {
    if (_answered) return;
    setState(() => _answered = true);
    final data = {
      'attempt_id': _currentQuestionData['attempt_id'].toString(),
      'question_id': _currentQuestionData['question_id'].toString(),
      'answer_id': _currentQuestionData['question_ans_id'].toString(),
      'score': '0',
      'is_correct': '0',
      'time_spent': _perQuestionTime.toString(),
    };
    try {
      final r = await Authrepository(Api_Client.dio).submitQuizAnswers(data);
      if (r.statusCode == 200)
        Future.delayed(Duration(milliseconds: 500), () => _nextQuestion());
    } catch (e) {
      print('AutoSubmit error: $e');
    }
  }

  void _nextQuestion() {
    if (_currentQuestion < totalQuestions - 1) {
      setState(() => _answered = false);
      setQuestionFromApi(_currentQuestion + 1);
      _startTimer();
    } else {
      _showResultDialog();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestion <= 0) return;
    _pauseTimer();
    setState(() => _answered = false);
    setQuestionFromApi(_currentQuestion - 1);
    _startTimer();
  }

  void _showResultDialog() async {
    final data = {
      'attempt_id': _currentQuestionData['attempt_id'].toString(),
      'Passingscore': '$_score'
    };
    await Authrepository(Api_Client.dio).finalSubmitQuiz(data);
    if (_isOverride) await TranslationService.instance.setLanguage(_globalLang);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => QuizReviewPage(
          attemptId:
              int.tryParse(_currentQuestionData['attempt_id'].toString()) ?? 0,
          userId: int.tryParse(_user!.id.toString()) ?? 0,
          quizTitle: widget.testTitle,
          pageType: 0,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  // ── Language sheet ─────────────────────────────────────────────────────────
  void _showLangSheet() {
    _pauseTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LangPickerSheet(
        languages: _languages,
        activeLang: _activeLang,
        globalLang: _globalLang,
        onSelect: (code) async {
          Navigator.pop(context);
          await _applyLang(code);
        },
        onReset: () async {
          Navigator.pop(context);
          await _resetToGlobal();
        },
      ),
    ).then((_) {
      // User dismissed without selecting — resume timer
      if (mounted && !_answered && _timeLeft > 0) _resumeTimer();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty || _currentQuestionData.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.tealGreen)),
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
                  if (!_answered) _buildBottomButtons(),
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
    final activeLangMap = _languages.firstWhere(
      (l) => l['code'] == _activeLang,
      orElse: () => {'code': 'en', 'native': 'English', 'label': 'English'},
    );
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          bottom: 12),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
        boxShadow: [
          BoxShadow(
              color: AppColors.darkNavy.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showExitDialog,
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
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(widget.subject,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.lightGold)),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle),
                              ),
                              SizedBox(width: 4),
                              Text('LIVE',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w900)),
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
                decoration: BoxDecoration(
                    color: AppColors.lightGold,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events,
                        color: AppColors.darkNavy, size: 16),
                    SizedBox(width: 6),
                    Text('$_score',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.darkNavy,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _showLangSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _isOverride
                    ? AppColors.white.withOpacity(0.15)
                    : AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isOverride
                      ? AppColors.white.withOpacity(0.4)
                      : AppColors.white.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.translate_rounded,
                      size: 14, color: AppColors.white.withOpacity(0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOverride
                              ? 'Page language (tap to change)'
                              : 'View questions in… (tap to change)',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              activeLangMap['native'] ?? 'English',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                            if (_isOverride) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.tealGreen.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Page only',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      _isOverride ? 'Change' : 'Select',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
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

  Widget _buildProgressSection() {
    double progress =
        totalQuestions > 0 ? _currentQuestion / totalQuestions : 0;
    double timeProgress =
        _perQuestionTime > 0 ? _timeLeft / _perQuestionTime : 0;
    final bool timerPaused = _timer == null && !_answered;

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestion + 1}/$totalQuestions',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w600),
              ),
              ScaleTransition(
                scale: _timeLeft <= (_perQuestionTime * 0.3).floor()
                    ? _pulseAnimation
                    : AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: timerPaused
                          ? [Colors.grey.shade500, Colors.grey.shade700]
                          : _timeLeft <= (_perQuestionTime * 0.2).floor()
                              ? [AppColors.red, AppColors.redS1]
                              : _timeLeft <= (_perQuestionTime * 0.3).floor()
                                  ? [AppColors.orange, AppColors.orangeS1]
                                  : [AppColors.tealGreen, AppColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (timerPaused
                                ? Colors.grey
                                : _timeLeft <= (_perQuestionTime * 0.3).floor()
                                    ? AppColors.red
                                    : AppColors.tealGreen)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        timerPaused ? Icons.pause_circle_outline : Icons.timer,
                        color: AppColors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        timerPaused ? 'Paused' : '$_timeLeft',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                            fontWeight: FontWeight.w900),
                      ),
                      if (!timerPaused)
                        Text('s',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600)),
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
                    Text('Progress',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.greyS600)),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.greyS200,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.tealGreen),
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
                    Text('Time',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.greyS600)),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: timerPaused ? timeProgress : timeProgress,
                        backgroundColor: AppColors.greyS200,
                        valueColor: AlwaysStoppedAnimation(
                          timerPaused
                              ? Colors.grey.shade400
                              : _timeLeft <= (_perQuestionTime * 0.2).floor()
                                  ? AppColors.red
                                  : _timeLeft <=
                                          (_perQuestionTime * 0.3).floor()
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
    final isTranslationAllowed =
        _currentQuestionData['is_translation_allowed'] == '1';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 8))
        ],
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
                    Text(widget.subject,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.tealGreen)),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: AppColors.darkNavy, size: 14),
                    SizedBox(width: 6),
                    Text('${_currentQuestionData['points']} Points',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.darkNavy)),
                  ],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_perQuestionTime}s / Q',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.tealGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Key includes _activeLang — forces rebuild when language changes
          isTranslationAllowed
              ? Text(
                  _currentQuestionData['question'] ?? '',
                  style: TextStyle(
                      fontSize: 15,
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.w700,
                      height: 1.4),
                )
              : TranslatedText(
                  _currentQuestionData['question'] ?? '',
                  key: ValueKey('q_${_activeLang}_$_currentQuestion'),
                  style: TextStyle(
                      fontSize: 15,
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.w700,
                      height: 1.4),
                ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    final options = _currentQuestionData['options'] as List? ?? [];
    final isTranslationAllowed =
        _currentQuestionData['is_translation_allowed'] == '1';
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          options.length,
          (i) => _buildOptionCard(
              String.fromCharCode(65 + i),
              options[i].toString(),
              i,
              isTranslationAllowed),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      String letter, String text, int index, bool isTranslationAllowed) {
    bool isSelected = _selectedOption == index;
    Color backgroundColor = AppColors.white;
    Color borderColor = AppColors.greyS300;
    Color letterBgColor = AppColors.greyS1;
    Color textColor = AppColors.darkNavy;
    if (isSelected) {
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected && !_answered
              ? [
                  BoxShadow(
                      color: AppColors.lightGold.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 5))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                  color: letterBgColor,
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected && !_answered
                        ? AppColors.white
                        : AppColors.darkNavy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              // Key includes _activeLang — forces rebuild when language changes
              child: isTranslationAllowed
                  ? Text(text,
                      style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w600))
                  : TranslatedText(
                      text,
                      key: ValueKey(
                          'opt_${_activeLang}_${_currentQuestion}_$index'),
                      style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Previous + Submit buttons ──────────────────────────────────────────────
  Widget _buildBottomButtons() {
    bool canSubmit = _selectedOption != null;
    bool canGoBack = _currentQuestion > 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (canGoBack) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToPreviousQuestion,
                icon: Icon(Icons.arrow_back_ios_rounded,
                    size: 14, color: AppColors.darkNavy),
                label: Text('Previous',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkNavy,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  side: BorderSide(color: AppColors.greyS300, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            flex: canGoBack ? 2 : 1,
            child: ElevatedButton(
              onPressed: canSubmit ? _submitAnswer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                disabledBackgroundColor: AppColors.greyS300,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: canSubmit
                      ? LinearGradient(
                          colors: [AppColors.tealGreen, AppColors.darkNavy])
                      : null,
                  color: canSubmit ? null : AppColors.greyS300,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canSubmit
                      ? [
                          BoxShadow(
                              color: AppColors.tealGreen.withOpacity(0.4),
                              blurRadius: 20,
                              offset: Offset(0, 10))
                        ]
                      : [],
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: canSubmit
                              ? AppColors.white
                              : AppColors.greyS500,
                          size: 22),
                      SizedBox(width: 10),
                      Text('Submit Answer',
                          style: TextStyle(
                              fontSize: 13,
                              color: canSubmit
                                  ? AppColors.white
                                  : AppColors.greyS500,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Exit dialog ────────────────────────────────────────────────────────────
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.warning_amber_rounded,
                    color: AppColors.red, size: 40),
              ),
              SizedBox(height: 20),
              Text('Exit Test?',
                  style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 12),
              Text('Your progress will be lost if you exit now.',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.greyS600)),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyS300),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.greyS700,
                              fontWeight: FontWeight.w600)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Exit',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.white,
                              fontWeight: FontWeight.w700)),
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
//  Model Download Popup
//  FIXED: Popup itself handles download + shows real animated progress bar
//  Calls onDownloadComplete() when done → parent resumes timer
// ─────────────────────────────────────────────────────────────────────────────
class _ModelDownloadPopup extends StatefulWidget {
  final String langName;
  final String langCode;
  final VoidCallback onDownloadComplete;

  const _ModelDownloadPopup({
    required this.langName,
    required this.langCode,
    required this.onDownloadComplete,
  });

  @override
  State<_ModelDownloadPopup> createState() => _ModelDownloadPopupState();
}

class _ModelDownloadPopupState extends State<_ModelDownloadPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;

  double _progress = 0.0;
  Timer? _fakeProgressTimer;
  bool _downloadDone = false;

  // ✅ ML code map — popup ko directly chahiye model download ke liye
  static const _mlCodeMap = {
    'hi': 'hi', 'mr': 'mr', 'bn': 'bn', 'ta': 'ta',
    'te': 'te', 'gu': 'gu', 'kn': 'kn', 'ml': 'ml',
    'pa': 'pa', 'ur': 'ur',
  };

  @override
  void initState() {
    super.initState();

    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _iconAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));

    _fakeProgressTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (t) {
        if (!mounted) return;
        setState(() {
          if (!_downloadDone && _progress < 0.88) {
            _progress += 0.013 + (_progress * 0.007);
            if (_progress > 0.88) _progress = 0.88;
          }
        });
      },
    );

    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      // ✅ KEY FIX: Sirf ML model download karo
      // setLanguage() parent (_applyLang) karega
      // Isse ensure hota hai ki parent setState se
      // pehle service properly initialized ho
      final mlCode = _mlCodeMap[widget.langCode];
      if (mlCode != null) {
        final modelManager = OnDeviceTranslatorModelManager();
        await modelManager.downloadModel(mlCode);
      }
    } catch (e) {
      print('Download error: $e');
    }

    if (!mounted) return;

    _fakeProgressTimer?.cancel();
    setState(() {
      _downloadDone = true;
      _progress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // ✅ mounted check AFTER delay bhi zaroori hai
    if (mounted) {
      widget.onDownloadComplete();
    }
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _fakeProgressTimer?.cancel();
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _downloadDone
                  ? const AlwaysStoppedAnimation(1.0)
                  : _iconAnim,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D6E6E).withOpacity(0.2),
                  border: Border.all(
                      color: const Color(0xFF0D6E6E), width: 2),
                ),
                child: Icon(
                  _downloadDone
                      ? Icons.check_rounded
                      : Icons.download_rounded,
                  color: const Color(0xFF14A3A3),
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _downloadDone
                  ? 'Download Complete!'
                  : 'Downloading Language Model',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _downloadDone
                  ? '${widget.langName} is ready. Resuming Test...'
                  : 'Downloading ${widget.langName} for the first time. Please wait…',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Download progress',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5))),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 11,
                      color: _downloadDone
                          ? const Color(0xFF14A3A3)
                          : Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: const Color(0x33FFFFFF),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF14A3A3)),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.amber.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _downloadDone
                        ? Icons.timer_rounded
                        : Icons.timer_off_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _downloadDone
                          ? 'Test timer will resume now.'
                          : 'Test timer is paused. It will resume automatically once download is complete.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade200,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: Color(0xFF14A3A3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'One-time download (upto 5 MB). Future language switches will be instant.',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.5),
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
            decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)),
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
                child: const Icon(Icons.translate_rounded,
                    size: 18, color: _teal),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Page Language',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E))),
                  Text('Only questions & answers will translate',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded,
                        size: 15, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reset to app language (${_nativeOf(globalLang)})',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7D5200),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: Colors.amber),
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
                    color: isActive
                        ? _darkNavy
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isActive ? _teal : Colors.grey.withOpacity(0.2),
                      width: isActive ? 1.8 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: _teal.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 3))
                          ]
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
                            decoration: const BoxDecoration(
                                color: _tealLight,
                                shape: BoxShape.circle),
                          ),
                        ),
                      if (isActive)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                                color: _teal, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded,
                                size: 11, color: Colors.white),
                          ),
                        ),
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang['native']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? _teal.withOpacity(0.2)
                                      : _tealBg.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  lang['label']!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isActive
                                        ? const Color(0xFF5DCAA5)
                                        : Colors.grey.shade600,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: _tealBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 13, color: _teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only questions & answers translate. Scores, timer and UI stay as-is.',
                    style: TextStyle(
                        fontSize: 11, color: _darkNavy, height: 1.5),
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
      languages
          .firstWhere((l) => l['code'] == code,
              orElse: () => {'native': code})['native'] ??
      code;
}