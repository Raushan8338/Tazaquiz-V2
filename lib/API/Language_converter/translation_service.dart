// ─────────────────────────────────────────────────────────────
//  TranslationService — Master File
//  Usage: TranslationService.instance.translate("your text")
// ─────────────────────────────────────────────────────────────
//
//  pubspec.yaml mein add karo:
//  dependencies:
//    google_mlkit_translation: ^0.11.0
//    google_mlkit_language_id: ^0.11.0
//    shared_preferences: ^2.2.2
//
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
//  TranslationService
// ─────────────────────────────────────────────────────────────
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final Map<String, OnDeviceTranslator> _translators = {};
  final Map<String, String> _cache = {};
  final _modelManager = OnDeviceTranslatorModelManager();

  LanguageIdentifier? _langIdentifier;
  String _targetLang = 'en';
  bool _initialized = false;

  static const Map<String, Map<String, String>> supportedLanguages = {
    'en': {'label': 'English', 'native': 'English', 'flag': '🇬🇧'},
    'hi': {'label': 'Hindi', 'native': 'हिंदी', 'flag': '🇮🇳'},
    'mr': {'label': 'Marathi', 'native': 'मराठी', 'flag': '🇮🇳'},
    'bn': {'label': 'Bengali', 'native': 'বাংলা', 'flag': '🇮🇳'},
    'ta': {'label': 'Tamil', 'native': 'தமிழ்', 'flag': '🇮🇳'},
    'te': {'label': 'Telugu', 'native': 'తెలుగు', 'flag': '🇮🇳'},
    'gu': {'label': 'Gujarati', 'native': 'ગુજરાતી', 'flag': '🇮🇳'},
    'kn': {'label': 'Kannada', 'native': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    'ml': {'label': 'Malayalam', 'native': 'മലയാളം', 'flag': '🇮🇳'},
    'pa': {'label': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
    'ur': {'label': 'Urdu', 'native': 'اردو', 'flag': '🇵🇰'},
  };

  Future<void> init() async {
    if (_initialized) return;
    _langIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
    _targetLang = await _getSavedLanguage();
    _initialized = true;
  }

  String get currentLanguage => _targetLang;
  bool get isInitialized => _initialized;

  Future<void> setLanguage(String langCode) async {
    if (_targetLang == langCode) return;
    _targetLang = langCode;
    _cache.clear();
    await _saveLanguage(langCode);
  }

  Future<String> translate(String text) async {
    if (text.trim().isEmpty) return text;
    if (!_initialized) await init();

    final cacheKey = '${_targetLang}_$text';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final sourceLang = await _langIdentifier!.identifyLanguage(text);
      final effectiveSource = (sourceLang == 'und') ? 'en' : sourceLang;

      if (effectiveSource == _targetLang) {
        _cache[cacheKey] = text;
        return text;
      }

      final source = _mlKitLang(effectiveSource);
      final target = _mlKitLang(_targetLang);

      if (source == null || target == null) return text;

      await _ensureModel(source);
      await _ensureModel(target);

      final key = '${effectiveSource}_$_targetLang';
      final translator = _translators.putIfAbsent(
        key,
        () => OnDeviceTranslator(sourceLanguage: source, targetLanguage: target),
      );

      final translated = await translator.translateText(text);
      if (translated.trim().isEmpty) return text;

      _cache[cacheKey] = translated;
      return translated;
    } catch (_) {
      return text;
    }
  }

  Future<List<String>> translateBatch(List<String> texts) async {
    return Future.wait(texts.map((t) => translate(t)));
  }

  Future<List<String>> translateSpans(List<String> texts) async {
    return Future.wait(texts.map((t) => translate(t)));
  }

  // ─────────────────────────────────────────────────────────────
  //  warmUp — translator ko pehle se memory mein load karo
  //  Call karo: screen open hone pe ya language change hone pe
  //  Isse pehli baar translate fast lagti hai (cold start nahi hota)
  // ─────────────────────────────────────────────────────────────
  Future<void> warmUp() async {
    if (!_initialized) await init();
    if (_targetLang == 'en') return; // English ke liye kuch nahi karna

    try {
      final source = _mlKitLang('en');
      final target = _mlKitLang(_targetLang);
      if (source == null || target == null) return;

      await _ensureModel(source);
      await _ensureModel(target);

      final key = 'en_$_targetLang';
      final translator = _translators.putIfAbsent(
        key,
        () => OnDeviceTranslator(sourceLanguage: source, targetLanguage: target),
      );
      // Ek dummy call — translator ko memory mein warm karta hai
      await translator.translateText('hello');
    } catch (_) {}
  }

  Future<void> _ensureModel(TranslateLanguage lang) async {
    final isDownloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
    if (!isDownloaded) await _modelManager.downloadModel(lang.bcpCode);
  }

  TranslateLanguage? _mlKitLang(String code) {
    final map = {
      'en': TranslateLanguage.english,
      'hi': TranslateLanguage.hindi,
      'mr': TranslateLanguage.marathi,
      'bn': TranslateLanguage.bengali,
      'ta': TranslateLanguage.tamil,
      'te': TranslateLanguage.telugu,
      'gu': TranslateLanguage.gujarati,
      'kn': TranslateLanguage.kannada,
      'ur': TranslateLanguage.urdu,
    };
    return map[code];
  }

  Future<String> _getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_language') ?? 'en';
  }

  Future<void> _saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }

  void clearCache() => _cache.clear();

  void dispose() {
    _langIdentifier?.close();
    for (final t in _translators.values) t.close();
  }
}

// ─────────────────────────────────────────────────────────────
//  1. TranslatedText
//     - No shimmer — original text dikhao, translate hone pe replace
//     - StatefulWidget — future ek baar banao, rebuild pe nahi
//
//  Usage: TranslatedText('Weekly Progress', style: TextStyle(...))
// ─────────────────────────────────────────────────────────────
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = TranslationService.instance.translate(widget.text);
  }

  @override
  void didUpdateWidget(TranslatedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _future = TranslationService.instance.translate(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? widget.text,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. TranslatedSpan
// ─────────────────────────────────────────────────────────────
class TranslatedSpan {
  final String text;
  final TextStyle? style;

  const TranslatedSpan({required this.text, this.style});
}

// ─────────────────────────────────────────────────────────────
//  3. TranslatedRichText
//     - No shimmer — original spans dikhao, translate hone pe replace
//     - StatefulWidget — future ek baar banao
//
//  Usage:
//    TranslatedRichText(
//      spans: [
//        TranslatedSpan(text: 'Bold text', style: TextStyle(fontWeight: FontWeight.w800)),
//        TranslatedSpan(text: ' normal text'),
//      ],
//    )
// ─────────────────────────────────────────────────────────────
class TranslatedRichText extends StatefulWidget {
  final List<TranslatedSpan> spans;
  final TextAlign? textAlign;
  final TextStyle? defaultStyle;
  final bool softWrap;
  final int? maxLines;
  final TextOverflow overflow;
  final TextScaler? textScaler;

  const TranslatedRichText({
    super.key,
    required this.spans,
    this.textAlign,
    this.defaultStyle,
    this.softWrap = true,
    this.maxLines,
    this.overflow = TextOverflow.visible,
    this.textScaler,
  });

  @override
  State<TranslatedRichText> createState() => _TranslatedRichTextState();
}

class _TranslatedRichTextState extends State<TranslatedRichText> {
  late Future<List<String>> _future;

  String _spansKey(List<TranslatedSpan> spans) => spans.map((s) => s.text).join('||');

  @override
  void initState() {
    super.initState();
    _future = TranslationService.instance.translateSpans(widget.spans.map((s) => s.text).toList());
  }

  @override
  void didUpdateWidget(TranslatedRichText old) {
    super.didUpdateWidget(old);
    if (_spansKey(old.spans) != _spansKey(widget.spans)) {
      _future = TranslationService.instance.translateSpans(widget.spans.map((s) => s.text).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snapshot) {
        final translatedTexts = snapshot.data;
        return RichText(
          textAlign: widget.textAlign ?? TextAlign.start,
          softWrap: widget.softWrap,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          textScaler: widget.textScaler ?? TextScaler.noScaling,
          text: TextSpan(
            style: widget.defaultStyle,
            children:
                widget.spans.asMap().entries.map((entry) {
                  final i = entry.key;
                  final span = entry.value;
                  return TextSpan(text: translatedTexts?[i] ?? span.text, style: span.style);
                }).toList(),
          ),
        );
      },
    );
  }
}
