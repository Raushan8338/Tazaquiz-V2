import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({Key? key}) : super(key: key);

  @override
  _DailyQuizScreenState createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> with SingleTickerProviderStateMixin {
  // ── Quiz state ─────────────────────────────────────────────────────────
  int _currentQuestion = 0;
  List<dynamic> _questions = [];
  int totalQuestions = 0;
  int _timeLeft = 30;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;

  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Raw question data only — no separate translated copy (same as LiveTestScreen)
  Map<String, dynamic> _currentQuestionData = {};

  UserModel? _user;
  List<Map<String, dynamic>> _userAnswers = [];
  int _startTimestamp = 0;
  bool _alreadyDone = false;
  Map<String, dynamic> _previousResult = {};

  // ── Page-local language override — EXACT LiveTestScreen pattern ────────
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
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _getUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    // Restore global language — exact same as LiveTestScreen
    if (_isLocalOverrideActive) {
      TranslationService.instance.setLanguage(_globalLang);
    }
    super.dispose();
  }

  // ── Language helpers — EXACT LiveTestScreen ────────────────────────────

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

    // setState → rebuild → activeLangMap recomputes → TranslatedText re-translates
    if (mounted) setState(() => _localLang = code == _globalLang ? null : code);
  }

  Future<void> _resetToGlobal() async {
    await TranslationService.instance.setLanguage(_globalLang);
    setState(() => _localLang = null);
  }

  void _showLangSheet() {
    _timer?.cancel();
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
              if (!_answered && _timeLeft > 0) _resumeTimer();
            },
            onReset: () async {
              Navigator.pop(context);
              await _resetToGlobal();
              if (!_answered && _timeLeft > 0) _resumeTimer();
            },
          ),
    ).then((_) {
      if (!_answered && _timeLeft > 0) _resumeTimer();
    });
  }

  // ── Data loading ───────────────────────────────────────────────────────

  void _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    _loadQuizData();
  }

  void _loadQuizData() async {
    final data = {'action': 'get_questions', 'user_id': _user?.id};
    final responseFuture = await Authrepository(Api_Client.dio).fetchDailyQuizCRUD(data);

    final Map<String, dynamic> apiResponse =
        responseFuture.data is String
            ? jsonDecode(responseFuture.data)
            : Map<String, dynamic>.from(responseFuture.data);

    if (apiResponse['success'] != true) {
      _showSnackbar(apiResponse['message'] ?? 'Quiz load nahi hua');
      return;
    }

    final d = apiResponse['data'];

    if (d['already_done'] == true) {
      setState(() {
        _alreadyDone = true;
        _previousResult = d['attempt'] ?? {};
      });
      return;
    }

    _questions = d['questions'] ?? [];
    totalQuestions = _questions.length;

    if (_questions.isNotEmpty) {
      _startTimestamp = DateTime.now().millisecondsSinceEpoch;
      _setQuestion(0);
      _startTimer();
    }
  }

  // ── Question setup — no batch translate needed, TranslatedText handles it
  void _setQuestion(int index) {
    final q = _questions[index];
    setState(() {
      _currentQuestion = index;
      _currentQuestionData = {
        'question_id': q['id'],
        'question': q['question'],
        'options': [q['option_a'], q['option_b'], q['option_c'], q['option_d']],
        'category': q['category'] ?? '',
      };
    });
  }

  // ── Timer ──────────────────────────────────────────────────────────────

  void _startTimer() {
    _timeLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  // ── Answer logic ───────────────────────────────────────────────────────

  void _selectOption(int index) {
    if (_answered) return;
    setState(() => _selectedOption = index);
  }

  void _submitAnswer() async {
    if (_selectedOption == null || _answered) return;
    setState(() {
      _answered = true;
      _timer?.cancel();
    });
    _userAnswers.add({
      'question_id': _currentQuestionData['question_id'],
      'selected': String.fromCharCode(65 + _selectedOption!),
    });
    Future.delayed(const Duration(milliseconds: 500), _nextQuestion);
  }

  void _autoSubmit() async {
    if (_answered) return;
    setState(() => _answered = true);
    _userAnswers.add({'question_id': _currentQuestionData['question_id'], 'selected': ''});
    Future.delayed(const Duration(milliseconds: 300), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentQuestion < totalQuestions - 1) {
      setState(() {
        _selectedOption = null;
        _answered = false;
      });
      _setQuestion(_currentQuestion + 1);
      _startTimer();
    } else {
      _finalSubmit();
    }
  }

  void _finalSubmit() async {
    int timeTaken = ((DateTime.now().millisecondsSinceEpoch - _startTimestamp) / 1000).round();

    if (_isLocalOverrideActive) {
      await TranslationService.instance.setLanguage(_globalLang);
    }

    final data = {
      'action': 'submit',
      'user_id': _user?.id,
      'answers': jsonEncode(_userAnswers),
      'time_taken': timeTaken,
    };
    final responseFuture = await Authrepository(Api_Client.dio).fetchDailyQuizCRUD(data);
    final Map<String, dynamic> apiResponse =
        responseFuture.data is String
            ? jsonDecode(responseFuture.data)
            : Map<String, dynamic>.from(responseFuture.data);

    if (apiResponse['success'] == true) {
      _showResultDialog(apiResponse['data']);
    } else {
      _showSnackbar(apiResponse['message'] ?? 'Submit failed');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty && !_alreadyDone) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        body: Center(child: CircularProgressIndicator(color: AppColors.tealGreen)),
      );
    }
    if (_alreadyDone) return _buildAlreadyDoneScreen();

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
                  const SizedBox(height: 10),
                  _buildQuestionCard(),
                  _buildOptionsSection(),
                  if (!_answered) _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header — EXACT LiveTestScreen pattern ──────────────────────────────

  Widget _buildHeader() {
    // local variable — recomputed on every setState, same as LiveTestScreen
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
                      'Aaj Ka Daily Quiz',
                      13,
                      AppColors.white,
                      FontWeight.w700,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _currentQuestionData['category'] ?? '',
                          style: TextStyle(fontSize: 11, color: AppColors.lightGold, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tealGreen.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            'DAILY',
                            10,
                            AppColors.white,
                            FontWeight.w900,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.darkNavy, size: 16),
                    const SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '$_score',
                      14,
                      AppColors.darkNavy,
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

          const SizedBox(height: 10),

          // ── Language bar — EXACT LiveTestScreen code ──────────────────
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
                            // activeLangMap['native'] — same as LiveTestScreen
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

  // ── Progress ───────────────────────────────────────────────────────────

  Widget _buildProgressSection() {
    double progress = totalQuestions > 0 ? _currentQuestion / totalQuestions : 0;
    double timeProgress = _timeLeft / 30;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                'Question ${_currentQuestion + 1}/$totalQuestions',
                14,
                AppColors.darkNavy,
                FontWeight.w600,
                2,
                TextAlign.left,
                0.0,
              ),
              ScaleTransition(
                scale: _timeLeft <= 10 ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: AppColors.white, size: 16),
                      const SizedBox(width: 6),
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
          const SizedBox(height: 12),
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
                    const SizedBox(height: 6),
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
              const SizedBox(width: 16),
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
                    const SizedBox(height: 6),
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

  // ── Question card — TranslatedText + ValueKey (EXACT LiveTestScreen) ───

  Widget _buildQuestionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: AppColors.tealGreen, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _currentQuestionData['category'] ?? '',
                      style: TextStyle(fontSize: 12, color: AppColors.tealGreen),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  'Daily Quiz',
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
          const SizedBox(height: 10),
          // TranslatedText + ValueKey — EXACT LiveTestScreen pattern
          TranslatedText(
            _currentQuestionData['question'] ?? '',
            key: ValueKey('dq_q_${_effectiveLang}_$_currentQuestion'),
            style: TextStyle(fontSize: 15, color: AppColors.darkNavy, fontWeight: FontWeight.w700, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Options — TranslatedText + ValueKey (EXACT LiveTestScreen) ─────────

  Widget _buildOptionsSection() {
    final List options = _currentQuestionData['options'] ?? [];
    if (options.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          options.length,
          (i) => _buildOptionCard(String.fromCharCode(65 + i), options[i].toString(), i),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text, int index) {
    bool isSelected = _selectedOption == index;
    Color bgColor = AppColors.white;
    Color borderColor = AppColors.greyS300;
    Color letterBgColor = AppColors.greyS1;

    if (isSelected && !_answered) {
      bgColor = AppColors.lightGold.withOpacity(0.2);
      borderColor = AppColors.lightGold;
      letterBgColor = AppColors.lightGold;
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isSelected && !_answered
                  ? [BoxShadow(color: AppColors.lightGold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
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
                  isSelected && !_answered ? AppColors.white : AppColors.darkNavy,
                  FontWeight.w900,
                  2,
                  TextAlign.left,
                  0.0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              // TranslatedText + ValueKey — EXACT LiveTestScreen pattern
              child: TranslatedText(
                text,
                key: ValueKey('dq_opt_${_effectiveLang}_${_currentQuestion}_$index'),
                style: TextStyle(fontSize: 14, color: AppColors.darkNavy, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit button ──────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    bool canSubmit = _selectedOption != null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: canSubmit ? AppColors.white : AppColors.greyS500, size: 24),
                const SizedBox(width: 12),
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

  // ── Already done ───────────────────────────────────────────────────────

  Widget _buildAlreadyDoneScreen() {
    final score = _previousResult['score'] ?? 0;
    final total = _previousResult['total'] ?? 15;
    final time = _previousResult['time_taken'] ?? 0;
    final mins = (time ~/ 60).toString().padLeft(2, '0');
    final secs = (time % 60).toString().padLeft(2, '0');
    final pct = total > 0 ? ((score / total) * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
              boxShadow: [
                BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Aaj Ka Daily Quiz',
                  13,
                  AppColors.white,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.4), blurRadius: 20)],
                    ),
                    child: Icon(Icons.emoji_events, color: AppColors.lightGold, size: 50),
                  ),
                  const SizedBox(height: 20),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Aaj ka Quiz De Diya! 🎉',
                    22,
                    AppColors.darkNavy,
                    FontWeight.w900,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                  const SizedBox(height: 6),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Kal phir aana naya quiz leke!',
                    13,
                    AppColors.greyS600,
                    FontWeight.normal,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultStat('Score', '$score/$total', Icons.stars, AppColors.tealGreen),
                      _buildResultStat('Accuracy', '$pct%', Icons.percent, AppColors.darkNavy),
                      _buildResultStat('Time', '$mins:$secs', Icons.timer, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Performance',
                              13,
                              AppColors.darkNavy,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              '$pct%',
                              13,
                              AppColors.tealGreen,
                              FontWeight.w900,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: AppColors.greyS200,
                            valueColor: AlwaysStoppedAnimation(AppColors.tealGreen),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: AppRichText.setTextPoppinsStyle(
                          context,
                          'Back to Home',
                          14,
                          AppColors.white,
                          FontWeight.w700,
                          1,
                          TextAlign.center,
                          0.0,
                        ),
                      ),
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

  // ── Result dialog ──────────────────────────────────────────────────────

  void _showResultDialog(Map<String, dynamic> data) {
    final score = data['score'] ?? 0;
    final total = data['total'] ?? 15;
    final percentage = data['percentage'] ?? 0;
    final rank = data['rank'] ?? 0;
    final totalParticipants = data['total_participants'] ?? 0;
    final message = data['message'] ?? '';
    final timeTaken = data['time_taken'] ?? 0;
    final mins = (timeTaken ~/ 60).toString().padLeft(2, '0');
    final secs = (timeTaken % 60).toString().padLeft(2, '0');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(32),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tealGreen.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.emoji_events, color: AppColors.lightGold, size: 40),
                  ),
                  const SizedBox(height: 24),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Quiz Complete!',
                    18,
                    AppColors.darkNavy,
                    FontWeight.w900,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
                  const SizedBox(height: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    message,
                    12,
                    AppColors.greyS600,
                    FontWeight.normal,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultStat('Score', '$score/$total', Icons.stars, AppColors.tealGreen),
                      _buildResultStat('Rank', '#$rank', Icons.leaderboard, AppColors.darkNavy),
                      _buildResultStat('Time', '$mins:$secs', Icons.timer, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.lightGold.withOpacity(0.3), AppColors.lightGoldS2.withOpacity(0.2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightGold),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: AppColors.darkNavy, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppRichText.setTextPoppinsStyle(
                                context,
                                '$totalParticipants students ne aaj diya',
                                12,
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
                        AppRichText.setTextPoppinsStyle(
                          context,
                          '$percentage%',
                          16,
                          AppColors.tealGreen,
                          FontWeight.w900,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                      const SizedBox(width: 12),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
          ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 40),
                  ),
                  const SizedBox(height: 20),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Quiz Chhod Dein?',
                    16,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
                  const SizedBox(height: 12),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Agar ab chode toh aaj ka quiz miss ho jayega!',
                    11,
                    AppColors.greyS600,
                    FontWeight.normal,
                    2,
                    TextAlign.center,
                    0.0,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.greyS300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.red));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Model Download Popup — exact copy from LiveTestScreen
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
//  Language Picker Sheet — exact copy from LiveTestScreen
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

  // exact same as LiveTestScreen
  String _nativeOf(String code) =>
      languages.firstWhere((l) => l['code'] == code, orElse: () => {'native': code})['native'] ?? code;
}
