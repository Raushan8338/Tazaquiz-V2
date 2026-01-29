import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:tazaquiz/constants/app_colors.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerPage({Key? key, required this.pdfUrl, required this.title}) : super(key: key);

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
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _loadPdfFromUrl();
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
      final response = await http.get(Uri.parse(url));

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/$filename");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A4D6D), Color(0xFF1A4D6D)],

              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
          if (pages != null && pages! > 0)
            Container(
              margin: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Center(
                child: Text(
                  '${(currentPage ?? 0) + 1}/${pages ?? 0}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.white, AppColors.tealGreen.withOpacity(0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            localPdfPath == null
                ? errorMessage.isEmpty
                    ? _buildLoadingState()
                    : _buildErrorState()
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF1A4D6D).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          PDFView(
                            filePath: localPdfPath!,
                            enableSwipe: true,
                            swipeHorizontal: false,
                            autoSpacing: true,
                            pageFling: true,
                            defaultPage: currentPage ?? 0,
                            fitPolicy: FitPolicy.WIDTH,
                            preventLinkNavigation: false,
                            backgroundColor: Colors.white,
                            onRender: (_pages) {
                              setState(() {
                                pages = _pages;
                                isReady = true;
                              });
                            },
                            onError: (error) {
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
                              _controller.complete(pdfViewController);
                            },
                            onLinkHandler: (String? uri) {
                              print('Clicked link: $uri');
                            },
                            onPageChanged: (int? page, int? total) {
                              setState(() {
                                currentPage = page;
                              });
                            },
                          ),
                          if (!isReady && errorMessage.isEmpty)
                            Container(color: Colors.white, child: _buildLoadingState()),
                          if (errorMessage.isNotEmpty) Container(color: Colors.white, child: _buildErrorState()),
                        ],
                      ),
                    ),
                  ),
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
                BoxShadow(color: Color(0xFF1A4D6D).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading PDF...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkNavy, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text('Please wait', style: TextStyle(fontSize: 14, color: AppColors.darkNavy.withOpacity(0.6))),
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
            BoxShadow(color: Color(0xFF28A194).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF28A194), AppColors.darkNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Oops!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
            const SizedBox(height: 12),
            Text(
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
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
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
