import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/notes_translate_page.dart';
import 'package:tazaquiznew/widgets/lang_picker_sheet.dart';

// "Desk" colour behind the pages, so every page reads as a separate sheet of paper.
const Color kReaderDesk = Color(0xFFE4E7EC);
const Color kReaderBar = Color(0xFF1A4D6D);

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;
  // Shows the Translate button only for notes the admin allowed
  // (study_materials.is_translation_allowed). English-language notes stay as they are.
  final bool allowTranslate;

  const PDFViewerPage({Key? key, required this.pdfUrl, required this.title, this.allowTranslate = true})
      : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> with SingleTickerProviderStateMixin {
  String? localPdfPath;
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // App language — notes translate into it, like the rest of the app
  String _appLang = 'en';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _loadPdfFromUrl();
    TranslationService.instance.init().then((_) {
      if (mounted) setState(() => _appLang = TranslationService.instance.currentLanguage);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfFromUrl() async {
    try {
      final url = widget.pdfUrl;
      final filename = url.substring(url.lastIndexOf("/") + 1);
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/$filename");

      // Already downloaded (e.g. opened before) — skip the network round
      // trip entirely instead of re-fetching the same PDF every time.
      if (await file.exists() && await file.length() > 0) {
        setState(() {
          localPdfPath = file.path;
        });
        _animationController.forward();
        return;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        setState(() {
          errorMessage = "Failed to load PDF (server returned ${response.statusCode}).";
        });
        return;
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);

      setState(() {
        localPdfPath = file.path;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load PDF: ${e.toString()}";
      });
    }
  }

  // Language button (same "Page Language" sheet as the test screens). On-device
  // translation exists on Android / iOS only.
  bool get _canTranslate =>
      widget.allowTranslate && localPdfPath != null && isReady && (Platform.isAndroid || Platform.isIOS);

  void _showLangSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => LangPickerSheet(
        activeLang: 'en', // the PDF itself is shown as it is
        globalLang: _appLang,
        subtitle: 'The notes will be shown in this language',
        info: 'Only the text of the notes translates. Use "Original" to see the PDF text again.',
        onSelect: (code) {
          Navigator.pop(sheetContext);
          _openTranslated(code);
        },
        onReset: () {
          Navigator.pop(sheetContext);
          _openTranslated(_appLang);
        },
      ),
    );
  }

  void _openTranslated(String code) {
    if (code == 'en') return; // English = the PDF as it is
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotesTranslatePage(
          pdfPath: localPdfPath!,
          title: widget.title,
          targetLang: code,
          startPage: currentPage ?? 0,
        ),
      ),
    );
  }

  Future<void> _goTo(int page) async {
    if (!_controller.isCompleted || pages == null) return;
    if (page < 0 || page >= pages!) return;
    final c = await _controller.future;
    await c.setPage(page);
  }

  @override
  Widget build(BuildContext context) {
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
        title: TranslatedText(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_canTranslate)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Center(
                child: InkWell(
                  onTap: _showLangSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.translate_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Text('English',
                            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: localPdfPath == null
          ? (errorMessage.isEmpty ? _buildLoadingState() : _buildErrorState())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // Book-style reading: one page at a time, swipe left/right to turn,
                        // grey desk around each page.
                        PDFView(
                          filePath: localPdfPath!,
                          enableSwipe: true,
                          swipeHorizontal: true,
                          autoSpacing: true,
                          pageFling: true,
                          pageSnap: true,
                          defaultPage: currentPage ?? 0,
                          fitPolicy: FitPolicy.BOTH,
                          preventLinkNavigation: false,
                          backgroundColor: kReaderDesk,
                          onRender: (_pages) {
                            setState(() {
                              pages = _pages;
                              isReady = true;
                            });
                          },
                          onError: (error) {
                            // Delete the local file — it may be a stale corrupted download.
                            // Without this, "Try Again" would keep reloading the same bad file.
                            if (localPdfPath != null) {
                              File(localPdfPath!).delete().catchError((_) => File(''));
                            }
                            setState(() {
                              errorMessage = error.toString();
                            });
                          },
                          onPageError: (page, error) {
                            setState(() {
                              errorMessage = 'Error on page $page: ${error.toString()}';
                            });
                          },
                          onViewCreated: (PDFViewController pdfViewController) {
                            if (!_controller.isCompleted) _controller.complete(pdfViewController);
                          },
                          onLinkHandler: (String? uri) {},
                          onPageChanged: (int? page, int? total) {
                            setState(() {
                              currentPage = page;
                            });
                          },
                        ),
                        if (!isReady && errorMessage.isEmpty)
                          Container(color: kReaderDesk, child: _buildLoadingState()),
                        if (errorMessage.isNotEmpty) Container(color: kReaderDesk, child: _buildErrorState()),
                      ],
                    ),
                  ),
                  if (isReady && (pages ?? 0) > 0)
                    ReaderPageBar(
                      page: currentPage ?? 0,
                      total: pages ?? 0,
                      onPrev: () => _goTo((currentPage ?? 0) - 1),
                      onNext: () => _goTo((currentPage ?? 0) + 1),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A4D6D), Color(0xFF28A194)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF1A4D6D).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          TranslatedText(
            'Loading PDF...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkNavy, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          TranslatedText('Please wait', style: TextStyle(fontSize: 14, color: AppColors.darkNavy.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF28A194).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF28A194), AppColors.darkNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            TranslatedText(
              'Oops!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.darkNavy.withOpacity(0.7), height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  errorMessage = '';
                  localPdfPath = null;
                  isReady = false;
                });
                _loadPdfFromUrl();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const TranslatedText('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar of the reader: ‹  Page 2 of 6  ›  (shared with the translated view)
class ReaderPageBar extends StatelessWidget {
  final int page; // 0-based
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const ReaderPageBar({super.key, required this.page, required this.total, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final bool canPrev = page > 0;
    final bool canNext = page < total - 1;
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: canPrev ? onPrev : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: kReaderBar,
                disabledColor: Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Page ${page + 1} of $total',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkNavy)),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : (page + 1) / total,
                        minHeight: 3,
                        color: AppColors.tealGreen,
                        backgroundColor: kReaderDesk,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: canNext ? onNext : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: kReaderBar,
                disabledColor: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
