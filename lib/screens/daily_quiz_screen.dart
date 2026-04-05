import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/language_selectionPage.dart';
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

  Map<String, dynamic> _currentQuestionData = {};
  // ── ADDED: translated data ──────────────────
  Map<String, dynamic> _translatedQuestionData = {};

  UserModel? _user;

  List<Map<String, dynamic>> _userAnswers = [];
  int _startTimestamp = 0;
  bool _alreadyDone = false;
  Map<String, dynamic> _previousResult = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _getUserData();
  }

  void _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    _loadQuizData();
  }

  void _loadQuizData() async {
    final data = {'action': 'get_questions', 'user_id': _user?.id};

    Authrepository authRepository = Authrepository(Api_Client.dio);
    final responseFuture = await authRepository.fetchDailyQuizCRUD(data);
    print('Daily Quiz API Response: ${responseFuture.data}');

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

  // ── MODIFIED: translate karo ek baar ────────
  void _setQuestion(int index) {
    final q = _questions[index];
    final raw = {
      'question_id': q['id'],
      'question': q['question'],
      'options': [q['option_a'], q['option_b'], q['option_c'], q['option_d']],
      'category': q['category'] ?? '',
    };
    setState(() {
      _currentQuestion = index;
      _currentQuestionData = raw;
      _translatedQuestionData = raw; // pehle original dikhao
    });
    _translateCurrentQuestion(raw); // background mein translate
  }

  // ── ADDED: batch translate ───────────────────
  Future<void> _translateCurrentQuestion(Map<String, dynamic> raw) async {
    final lang = TranslationService.instance.currentLanguage;
    if (lang == 'en') return; // English hai to skip

    try {
      final results = await TranslationService.instance.translateBatch([
        raw['question'] ?? '',
        raw['category'] ?? '',
        raw['options'][0] ?? '',
        raw['options'][1] ?? '',
        raw['options'][2] ?? '',
        raw['options'][3] ?? '',
      ]);

      if (mounted) {
        setState(() {
          _translatedQuestionData = {
            'question_id': raw['question_id'],
            'question': results[0],
            'category': results[1],
            'options': [results[2], results[3], results[4], results[5]],
          };
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

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

    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {
      'action': 'submit',
      'user_id': _user?.id,
      'answers': jsonEncode(_userAnswers),
      'time_taken': timeTaken,
    };

    final responseFuture = await authRepository.fetchDailyQuizCRUD(data);

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

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty && !_alreadyDone) {
      return Scaffold(
        backgroundColor: AppColors.greyS1,
        body: Center(child: CircularProgressIndicator(color: AppColors.tealGreen)),
      );
    }

    if (_alreadyDone) {
      return _buildAlreadyDoneScreen();
    }

    // ── MODIFIED: Stack mein wrap + TranslationToast ──
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: Stack(
        children: [
          Column(
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
          // ── ADDED: Translation toast ──────────
          // const TranslationToast(),
        ],
      ),
    );
  }

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

  Widget _buildHeader() {
    final langCode = TranslationService.instance.currentLanguage;
    final langNative = TranslationService.supportedLanguages[langCode]?['native'] ?? 'English';

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
                        // ── MODIFIED: translated category ──
                        AppRichText.setTextPoppinsStyle(
                          context,
                          _translatedQuestionData['category'] ?? '',
                          11,
                          AppColors.lightGold,
                          FontWeight.w600,
                          1,
                          TextAlign.left,
                          0.0,
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

          // ── ADDED: Language change bar ────────
          GestureDetector(
            onTap: () async {
              _timer?.cancel();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LanguageSelectionPage(showSkip: false, onDone: () => Navigator.pop(context)),
                ),
              );
              if (mounted) {
                // Re-translate current question in new language
                _translateCurrentQuestion(_currentQuestionData);
                setState(() {});
                if (!_answered && _timeLeft > 0) {
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
                      TranslatedText(
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
                        child: TranslatedText(
                          'Change',
                          style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  TranslatedText(
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
                    // ── MODIFIED: translated ──
                    AppRichText.setTextPoppinsStyle(
                      context,
                      _translatedQuestionData['category'] ?? '',
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
          // ── MODIFIED: translated question ──
          AppRichText.setTextPoppinsStyle(
            context,
            _translatedQuestionData['question'] ?? '',
            15,
            AppColors.darkNavy,
            FontWeight.w700,
            4,
            TextAlign.left,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    // ── MODIFIED: translated options ──
    final List options = _translatedQuestionData['options'] ?? [];
    if (options.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          options.length,
          (index) => _buildOptionCard(String.fromCharCode(65 + index), options[index], index),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text, int index) {
    bool isSelected = _selectedOption == index;
    Color backgroundColor = AppColors.white;
    Color borderColor = AppColors.greyS300;
    Color letterBgColor = AppColors.greyS1;

    if (isSelected && !_answered) {
      backgroundColor = AppColors.lightGold.withOpacity(0.2);
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
          color: backgroundColor,
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
              child: AppRichText.setTextPoppinsStyle(
                context,
                text,
                14,
                AppColors.darkNavy,
                FontWeight.w600,
                2,
                TextAlign.left,
                0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            boxShadow:
                canSubmit
                    ? [
                      BoxShadow(
                        color: AppColors.tealGreen.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : [],
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
        TranslatedText(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        TranslatedText(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: TranslatedText(msg), backgroundColor: AppColors.red));
  }
}
