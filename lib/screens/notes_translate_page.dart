import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/PDFViewerPage.dart' show ReaderPageBar, kReaderDesk, kReaderBar;
import 'package:tazaquiznew/widgets/lang_picker_sheet.dart';

class _RawLine {
  final String text;
  final double fontSize;
  const _RawLine(this.text, this.fontSize);
}

// Runs in a background isolate (compute) so a long PDF does not freeze the screen.
// extractText() gave one WORD per line for our notes, so lines are read with
// extractTextLines(), which also gives the font size (used to spot headings).
List<List<_RawLine>> _extractPdfPages(Uint8List bytes) {
  final doc = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(doc);
  final pages = <List<_RawLine>>[];
  for (int i = 0; i < doc.pages.count; i++) {
    try {
      final lines = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
      pages.add([for (final l in lines) _RawLine(l.text, l.fontSize)]);
    } catch (_) {
      pages.add(const []);
    }
  }
  doc.dispose();
  return pages;
}

class _Para {
  final String original;
  final bool isHeading;
  final bool isBullet;
  String? translated;
  _Para(this.original, {this.isHeading = false, this.isBullet = false});
}

enum _Stage { reading, preparing, ready, noText, sameLanguage, failed, unsupported }

/// Notes PDF as text in the app language (on-device ML Kit, the same language pack the
/// rest of the app uses). Book-style: one page at a time, swipe to turn. Only the page
/// on screen is translated right away (all its paragraphs together); the next page is
/// prepared in the background, so the reader does not wait for the whole PDF.
class NotesTranslatePage extends StatefulWidget {
  final String pdfPath; // local file, already downloaded by PDFViewerPage
  final String title;
  final String targetLang; // app language: 'hi', 'mr', ...
  final int startPage;

  const NotesTranslatePage({
    super.key,
    required this.pdfPath,
    required this.title,
    required this.targetLang,
    this.startPage = 0,
  });

  @override
  State<NotesTranslatePage> createState() => _NotesTranslatePageState();
}

class _NotesTranslatePageState extends State<NotesTranslatePage> {
  final _ts = TranslationService.instance;
  _Stage _stage = _Stage.reading;
  List<List<_Para>> _pages = [];
  final Map<int, Future<void>> _pageJobs = {};
  bool _showOriginal = false;
  String _sourceLang = 'en';
  late int _current;
  late final PageController _pager;
  late String _target; // can be changed from the language sheet on this screen
  String _allText = '';

  String get _targetName => pageLanguageNative(_target);
  String get _targetLabel => pageLanguageLabel(_target);

  @override
  void initState() {
    super.initState();
    _target = widget.targetLang;
    _current = widget.startPage;
    _pager = PageController(initialPage: widget.startPage);
    _run();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _stage = _Stage.reading);

    // 1. Text of every page (background isolate)
    List<List<_RawLine>> rawPages;
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      rawPages = await compute(_extractPdfPages, bytes);
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.noText);
      return;
    }
    final bodySize = _bodyFontSize(rawPages);
    final pages = rawPages.map((p) => _toParagraphs(p, bodySize)).toList();
    final allText = pages.expand((p) => p).map((e) => e.original).join(' ').trim();
    if (!mounted) return;
    if (allText.length < 20) {
      setState(() => _stage = _Stage.noText); // scanned PDF — no text in it
      return;
    }
    _pages = pages;
    _allText = allText;
    if (_current >= _pages.length) _current = 0;
    await _startTranslation();
  }

  // Steps 2-4 for the current _target (run again when the language is changed)
  Future<void> _startTranslation() async {
    final allText = _allText;
    if (!_ts.canTranslateTo(_target)) {
      setState(() => _stage = _Stage.unsupported);
      return;
    }

    // 2. Language of the notes
    _sourceLang = await _ts.detectLanguage(allText.length > 1500 ? allText.substring(0, 1500) : allText);
    if (!mounted) return;
    if (_sourceLang == _target) {
      setState(() {
        _stage = _Stage.sameLanguage;
        _showOriginal = true;
      });
      return;
    }

    // 3. Language packs — already on the phone when the user picked this app language,
    //    so this is normally instant.
    setState(() => _stage = _Stage.preparing);
    try {
      await _ts.prepareLanguage(_sourceLang);
      await _ts.prepareLanguage(_target);
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.failed);
      return;
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.ready);

    // 4. Page on screen first, then the next one in the background
    _translatePage(_current);
    _translatePage(_current + 1);
  }

  Future<void> _translatePage(int index) {
    if (index < 0 || index >= _pages.length) return Future.value();
    return _pageJobs.putIfAbsent(index, () async {
      final paras = _pages[index];
      // all paragraphs of the page at once — much faster than one after another
      await Future.wait(paras.map((p) async {
        p.translated ??= await _ts.translateTo(p.original, _sourceLang, _target);
      }));
      if (mounted) setState(() {});
    });
  }

  // Same "Page Language" sheet as the test screens
  void _showLangSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => LangPickerSheet(
        activeLang: _target,
        globalLang: _ts.currentLanguage,
        subtitle: 'The notes will be shown in this language',
        info: 'Only the text of the notes translates. Use "Original" to see the PDF text again.',
        onSelect: (code) {
          Navigator.pop(sheetContext);
          _changeLanguage(code);
        },
        onReset: () {
          Navigator.pop(sheetContext);
          _changeLanguage(_ts.currentLanguage);
        },
      ),
    );
  }

  void _changeLanguage(String code) {
    if (code == 'en') {
      Navigator.pop(context); // English = back to the PDF as it is
      return;
    }
    if (code == _target) return;
    for (final page in _pages) {
      for (final p in page) {
        p.translated = null;
      }
    }
    _pageJobs.clear();
    setState(() {
      _target = code;
      _showOriginal = false;
    });
    if (_pages.isEmpty) {
      _run();
    } else {
      _startTranslation();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _current = index);
    if (_stage == _Stage.ready) {
      _translatePage(index);
      _translatePage(index + 1);
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= _pages.length) return;
    _pager.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  // Most common font size (by amount of text) = normal body text.
  static double _bodyFontSize(List<List<_RawLine>> pages) {
    final weight = <int, int>{};
    for (final page in pages) {
      for (final l in page) {
        final k = l.fontSize.round();
        weight[k] = (weight[k] ?? 0) + l.text.length;
      }
    }
    if (weight.isEmpty) return 12;
    return weight.entries.reduce((a, b) => a.value >= b.value ? a : b).key.toDouble();
  }

  // PDF lines are joined back into paragraphs so the translator gets whole sentences:
  //  - bigger font than the body  -> heading
  //  - starts with ● ○ • ▪ - or "1." -> new point
  //  - smaller font (superscript like the 2 in m/s²) -> stuck to the text before it
  //  - anything else continues the current paragraph
  static final _bulletMark = RegExp(r'^[•▪●◦○■□➢➤►\-–*]\s*');
  static final _numbered = RegExp(r'^(\d+[.)]|[a-zA-Z][.)]|\(\w\))\s');

  static List<_Para> _toParagraphs(List<_RawLine> lines, double bodySize) {
    final paras = <_Para>[];
    final buf = StringBuffer();
    bool bufIsBullet = false;

    void flush() {
      final s = buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (s.isNotEmpty) paras.add(_Para(s, isBullet: bufIsBullet));
      buf.clear();
      bufIsBullet = false;
    }

    for (final raw in lines) {
      var line = raw.text.trim();
      if (line.isEmpty) continue;

      if (raw.fontSize >= bodySize * 1.15) {
        flush();
        paras.add(_Para(line, isHeading: true));
        continue;
      }
      if (raw.fontSize <= bodySize * 0.8 && buf.isNotEmpty) {
        buf.write(line); // superscript / subscript
        continue;
      }
      if (_bulletMark.hasMatch(line)) {
        flush();
        line = line.replaceFirst(_bulletMark, '');
        bufIsBullet = true;
      } else if (_numbered.hasMatch(line)) {
        flush();
      }
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(line);
      if (buf.length > 900) flush(); // keep each translation call a sensible size
    }
    flush();
    return paras;
  }

  @override
  Widget build(BuildContext context) {
    final bool showBook = _pages.isNotEmpty && (_stage == _Stage.ready || _stage == _Stage.sameLanguage);

    return Scaffold(
      backgroundColor: kReaderDesk,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kReaderBar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          if (showBook && _stage == _Stage.ready)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(child: _langToggle()),
            ),
          // opens the same "Page Language" sheet to pick another language
          IconButton(
            tooltip: 'Page language',
            onPressed: _showLangSheet,
            icon: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: showBook
          ? Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pager,
                    itemCount: _pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) => _buildSheet(i),
                  ),
                ),
                ReaderPageBar(
                  page: _current,
                  total: _pages.length,
                  onPrev: () => _goTo(_current - 1),
                  onNext: () => _goTo(_current + 1),
                ),
              ],
            )
          : _buildStatus(),
    );
  }

  // [ हिंदी | Original ] switch in the app bar
  Widget _langToggle() {
    Widget seg(String label, bool selected, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? kReaderBar : Colors.white)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(_targetName, !_showOriginal, () => setState(() => _showOriginal = false)),
          seg('Original', _showOriginal, () => setState(() => _showOriginal = true)),
        ],
      ),
    );
  }

  // One page = a sheet of paper on the desk
  Widget _buildSheet(int index) {
    final paras = _pages[index];
    final bool translating =
        !_showOriginal && _stage == _Stage.ready && paras.any((p) => p.translated == null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            if (translating)
              LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.tealGreen,
                backgroundColor: AppColors.tealGreen.withOpacity(0.12),
              ),
            Expanded(
              child: paras.isEmpty
                  ? Center(
                      child: Text('This page has no text.',
                          style: TextStyle(fontSize: 13, color: AppColors.darkNavy.withOpacity(0.5))),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                      children: [for (final p in paras) _buildPara(p)],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${index + 1}',
                  style: TextStyle(fontSize: 11, color: AppColors.darkNavy.withOpacity(0.45))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPara(_Para para) {
    final pending = !_showOriginal && para.translated == null && _stage == _Stage.ready;
    final text = _showOriginal ? para.original : (para.translated ?? para.original);
    final style = TextStyle(
      fontSize: para.isHeading ? 16 : 14.5,
      height: 1.6,
      fontWeight: para.isHeading ? FontWeight.w800 : FontWeight.w400,
      color: pending ? AppColors.darkNavy.withOpacity(0.3) : const Color(0xFF1F2937),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: para.isHeading ? 8 : 10, top: para.isHeading ? 6 : 0),
      child: para.isBullet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 2),
                  child: Text('•', style: style.copyWith(fontWeight: FontWeight.w800, color: AppColors.tealGreen)),
                ),
                Expanded(child: SelectableText(text, style: style)),
              ],
            )
          : SelectableText(text, style: style),
    );
  }

  Widget _buildStatus() {
    IconData icon;
    String title;
    String sub = '';
    bool spinner = false;
    bool retry = false;
    switch (_stage) {
      case _Stage.preparing:
        icon = Icons.translate_rounded;
        title = 'Getting $_targetLabel ready…';
        sub = 'If the $_targetLabel language pack is not on this phone yet, it downloads once.';
        spinner = true;
        break;
      case _Stage.noText:
        icon = Icons.image_not_supported_rounded;
        title = 'These notes cannot be translated';
        sub = 'This PDF is made of scanned images, so it has no text to translate. Please read the original PDF.';
        break;
      case _Stage.unsupported:
        icon = Icons.translate_rounded;
        title = 'Notes are not available in $_targetLabel yet';
        sub = 'Please pick another language from the 🌐 button above.';
        break;
      case _Stage.failed:
        icon = Icons.wifi_off_rounded;
        title = 'Could not get the $_targetLabel language pack';
        sub = 'Please check your internet connection and try again.';
        retry = true;
        break;
      default:
        icon = Icons.menu_book_rounded;
        title = 'Opening the notes…';
        spinner = true;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: AppColors.tealGreen),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.darkNavy.withOpacity(0.6))),
            ],
            if (spinner) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.tealGreen),
              ),
            ],
            if (retry) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _run,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
