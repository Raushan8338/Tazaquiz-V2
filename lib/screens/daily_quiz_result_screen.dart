import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/models/daily_quiz_attempt_modal.dart';

class QuizDetailScreen extends StatefulWidget {
  final int userId;
  final String quizDate;
  final int score;
  final int total;

  const QuizDetailScreen({
    Key? key,
    required this.userId,
    required this.quizDate,
    required this.score,
    required this.total,
  }) : super(key: key);

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  List<QuizResultDetail> details = [];
  bool isLoading = true;
  String? error;

  // ── Page-local language override ───────────────────────────────────────────
  // null  → use global app language (default)
  // 'en', 'hi', ... → override only on this page, only this session
  String? _localLang;

  // Global language at the time this screen opened (used to restore on back)
  late final String _globalLang;

  // All languages same as LanguageSelectionPage
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

  // Effective language: local override takes priority, else global
  String get _effectiveLang => _localLang ?? _globalLang;

  bool get _isLocalOverrideActive => _localLang != null && _localLang != _globalLang;

  @override
  void initState() {
    super.initState();
    _globalLang = TranslationService.instance.currentLanguage;
    _fetchDetails();
  }

  @override
  void dispose() {
    // ── KEY: Restore global language when leaving this screen ─────────────
    if (_isLocalOverrideActive) {
      TranslationService.instance.setLanguage(_globalLang);
    }
    super.dispose();
  }

  String _formatDate(String rawDate) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(rawDate));
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _fetchDetails() async {
    try {
      final r = await Authrepository(
        Api_Client.dio,
      ).fetchDailyQuizAttemptDetails({'user_id': widget.userId.toString(), 'quiz_date': widget.quizDate});
      if (r.statusCode == 200) {
        setState(() {
          details = (r.data as List).map((e) => QuizResultDetail.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _optionText(QuizResultDetail d, String key) {
    switch (key) {
      case 'A':
        return d.optionA;
      case 'B':
        return d.optionB;
      case 'C':
        return d.optionC;
      case 'D':
        return d.optionD;
      default:
        return '';
    }
  }

  // ── Apply local language override ─────────────────────────────────────────
  Future<void> _applyLocalLang(String code) async {
    if (code == _effectiveLang) return;

    // Temporarily push to TranslationService so TranslatedText widgets pick it up
    await TranslationService.instance.setLanguage(code);

    setState(() => _localLang = code);
  }

  // ── Reset back to global language ─────────────────────────────────────────
  Future<void> _resetToGlobal() async {
    await TranslationService.instance.setLanguage(_globalLang);
    setState(() => _localLang = null);
  }

  // ── Text widget: uses ValueKey so toggling forces fresh translation ────────
  Widget _t(String text, {TextStyle? style, TextAlign? ta, int? maxLines}) {
    return TranslatedText(
      text,
      key: ValueKey('tr_${_effectiveLang}_$text'),
      style: style,
      textAlign: ta,
      maxLines: maxLines,
    );
  }

  // ── Back navigation: restores global lang before popping ─────────────────
  void _onBack() {
    if (_isLocalOverrideActive) {
      TranslationService.instance.setLanguage(_globalLang);
    }
    Navigator.pop(context);
  }

  // ── Bottom sheet: language picker ─────────────────────────────────────────
  void _showLangSheet() {
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
            },
            onReset: () async {
              Navigator.pop(context);
              await _resetToGlobal();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final correct = details.where((d) => d.isCorrect).length;
    final wrong = details.where((d) => !d.isCorrect).length;

    // Find native name for active language
    final activeLangMap = _languages.firstWhere(
      (l) => l['code'] == _effectiveLang,
      orElse: () => {'code': 'en', 'native': 'English', 'label': 'English'},
    );

    return WillPopScope(
      onWillPop: () async {
        _onBack();
        return false; // we handle the pop ourselves
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A4A4A), Color(0xFF0D6E6E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: _onBack,
          ),
          title: _t(
            'Daily Quiz Result - ${_formatDate(widget.quizDate)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
          // Status strip: shows when local override is active
          bottom:
              _isLocalOverrideActive
                  ? PreferredSize(
                    preferredSize: const Size.fromHeight(22),
                    child: Container(
                      color: Colors.white.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.translate_rounded, size: 10, color: Colors.white60),
                          const SizedBox(width: 5),
                          Text(
                            'Viewing in ${activeLangMap['native']}  •  Page-only, not saved',
                            style: const TextStyle(fontSize: 10, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  )
                  : null,
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D6E6E)))
                : error != null
                ? Center(child: _t(error!))
                : Column(
                  children: [
                    _scoreBanner(correct, wrong),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: details.length,
                        itemBuilder: (_, i) => _questionCard(details[i], i),
                      ),
                    ),
                  ],
                ),

        // ── Bottom Language Bar ────────────────────────────────────────────
        bottomNavigationBar: _BottomLangBar(
          activeLang: activeLangMap,
          isOverrideActive: _isLocalOverrideActive,
          onTap: _showLangSheet,
          onReset: _isLocalOverrideActive ? _resetToGlobal : null,
        ),
      ),
    );
  }

  // ── Score Banner ───────────────────────────────────────────────────────────
  Widget _scoreBanner(int correct, int wrong) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _tile('Score', '${widget.score}/${widget.total}', Icons.star_rounded),
          _vDiv(),
          _tile('Correct', '$correct', Icons.check_circle_rounded),
          _vDiv(),
          _tile('Wrong', '$wrong', Icons.cancel_rounded),
        ],
      ),
    );
  }

  Widget _tile(String label, String val, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.white, size: 20),
      const SizedBox(height: 4),
      _t(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      _t(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
    ],
  );

  Widget _vDiv() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3));

  // ── Question Card ──────────────────────────────────────────────────────────
  Widget _questionCard(QuizResultDetail d, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: d.isCorrect ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0D6E6E), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Q${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _t(
                  d.question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    height: 1.4,
                  ),
                ),
              ),
              Icon(
                d.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: d.isCorrect ? Colors.green : Colors.red,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...['A', 'B', 'C', 'D'].map((key) => _optionRow(d, key)),
          if (!d.isCorrect) _wrongHint(d),
        ],
      ),
    );
  }

  Widget _optionRow(QuizResultDetail d, String key) {
    final isSel = d.selectedAnswer == key;
    final isCorr = d.correctAnswer == key;

    Color bg = Colors.grey.withOpacity(0.06);
    Color border = Colors.grey.withOpacity(0.2);
    Color txt = const Color(0xFF1A1A2E);
    IconData? ic;
    Color? icColor;

    if (isCorr) {
      bg = Colors.green.withOpacity(0.08);
      border = Colors.green.withOpacity(0.5);
      txt = Colors.green.shade800;
      ic = Icons.check_circle_rounded;
      icColor = Colors.green;
    } else if (isSel) {
      bg = Colors.red.withOpacity(0.08);
      border = Colors.red.withOpacity(0.5);
      txt = Colors.red.shade800;
      ic = Icons.cancel_rounded;
      icColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isCorr
                      ? Colors.green
                      : isSel
                      ? Colors.red
                      : Colors.grey.shade300,
            ),
            child: Center(
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: (isCorr || isSel) ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _t(
              _optionText(d, key),
              style: TextStyle(
                fontSize: 12,
                color: txt,
                fontWeight: (isCorr || isSel) ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (ic != null) Icon(ic, size: 16, color: icColor),
        ],
      ),
    );
  }

  Widget _wrongHint(QuizResultDetail d) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'You selected: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  TextSpan(
                    text: '${d.selectedAnswer} • ',
                    style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: 'Correct: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  TextSpan(
                    text: d.correctAnswer,
                    style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom Language Bar
//  Always visible at screen bottom — tap to open language sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BottomLangBar extends StatelessWidget {
  final Map<String, String> activeLang;
  final bool isOverrideActive;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  const _BottomLangBar({required this.activeLang, required this.isOverrideActive, required this.onTap, this.onReset});

  static const _teal = Color(0xFF0D6E6E);
  static const _tealBg = Color(0xFFE1F5EE);
  static const _tealDark = Color(0xFF0A4A4A);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -3))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Language icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isOverrideActive ? _teal.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isOverrideActive ? _teal.withOpacity(0.4) : Colors.grey.withOpacity(0.2)),
            ),
            child: Icon(Icons.translate_rounded, size: 18, color: isOverrideActive ? _teal : Colors.grey),
          ),
          const SizedBox(width: 10),

          // Label area
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOverrideActive ? 'Page language (tap to change)' : 'View questions in… (tap to change)',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(
                        activeLang['native'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isOverrideActive ? _tealDark : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isOverrideActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: _tealBg, borderRadius: BorderRadius.circular(20)),
                          child: const Text(
                            'Page only',
                            style: TextStyle(fontSize: 9, color: _teal, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Change button
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isOverrideActive ? _teal : const Color(0xFF0D6E6E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    isOverrideActive ? 'Change' : 'Select',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          // Reset button (only when override is active)
          if (isOverrideActive) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onReset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.25)),
                ),
                child: const Icon(Icons.refresh_rounded, size: 16, color: Colors.grey),
              ),
            ),
          ],
        ],
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
          // Handle
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
          ),

          // Header
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
                  Text('Only applies to this screen', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // "Back to app language" row (shown when override is active)
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

          // Grid
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
                      // "App lang" dot indicator
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
                      // Selected checkmark
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

          // Info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: _tealBg.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 13, color: _teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This changes language only for this screen. Your app language stays the same.',
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

  String _nativeOf(String code) {
    return languages.firstWhere((l) => l['code'] == code, orElse: () => {'native': code})['native'] ?? code;
  }
}
