import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'translation_service.dart';

class LanguageSelectionPage extends StatefulWidget {
  final VoidCallback onDone;
  final bool showSkip;

  const LanguageSelectionPage({super.key, required this.onDone, this.showSkip = false});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> with SingleTickerProviderStateMixin {
  String _selected = 'en';
  late AnimationController _animController;

  static const _darkNavy = Color(0xFF0D1B2A);
  static const _navyMid = Color(0xFF112233);
  static const _navyLight = Color(0xFF1A2E42);
  static const _teal = Color(0xFF1D9E75);
  static const _tealLight = Color(0xFF25C48F);
  static const _white = Color(0xFFFFFFFF);
  // Soft blue-grey background — navy se match karta hai, white se better
  static const _pageBg = Color(0xFFEEF2F7);
  static const _cardBg = Color(0xFFF8FAFC);
  static const _grey400 = Color(0xFF94A3B8);
  static const _grey500 = Color(0xFF64748B);
  static const _grey900 = Color(0xFF0F172A);

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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

    TranslationService.instance.init().then((_) {
      if (mounted) setState(() => _selected = TranslationService.instance.currentLanguage);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onSelect(String code) async {
    setState(() => _selected = code);
    await TranslationService.instance.setLanguage(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _darkNavy,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                if (!widget.showSkip)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _navyLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: _white),
                    ),
                  ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.language_rounded, color: _teal, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LANGUAGE',
                      style: TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    ),
                    const Text(
                      'Choose Yours',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _white, height: 1.2),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.showSkip)
                  TextButton(
                    onPressed: widget.onDone,
                    child: Text('Skip', style: TextStyle(color: _grey400, fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Teal-tinted info strip ──────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.07),
              border: Border(bottom: BorderSide(color: _teal.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: _teal),
                const SizedBox(width: 7),
                Text(
                  'All quiz content will auto-translate to your language',
                  style: TextStyle(fontSize: 11.5, color: _teal.withOpacity(0.85), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // ── Grid ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.25,
                ),
                itemCount: _languages.length,
                itemBuilder: (ctx, i) {
                  final lang = _languages[i];
                  final isSelected = _selected == lang['code'];
                  return _buildCard(lang, isSelected, i);
                },
              ),
            ),
          ),

          _buildBottomPanel(context),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, String> lang, bool isSelected, int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final delay = (index * 0.06).clamp(0.0, 0.7);
        final progress = ((_animController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 18 * (1 - progress)),
          child: Opacity(opacity: progress, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _onSelect(lang['code']!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? _darkNavy : _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? _teal : _grey400.withOpacity(0.2), width: isSelected ? 1.8 : 1),
            boxShadow:
                isSelected
                    ? [BoxShadow(color: _teal.withOpacity(0.22), blurRadius: 14, offset: const Offset(0, 4))]
                    : [BoxShadow(color: _grey900.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 12, color: _white),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? _white : _darkNavy,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? _teal.withOpacity(0.2) : _pageBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lang['label']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? _tealLight : _grey500,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    final selectedLang = _languages.firstWhere((l) => l['code'] == _selected);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: _grey900.withOpacity(0.09), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: _grey400.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _teal.withOpacity(0.25)),
                ),
                child: const Icon(Icons.translate_rounded, size: 20, color: _teal),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected language', style: TextStyle(fontSize: 10, color: _grey400)),
                  const SizedBox(height: 2),
                  Text(
                    selectedLang['native']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkNavy),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _teal.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: _teal),
                    const SizedBox(width: 4),
                    Text('Active', style: TextStyle(fontSize: 11, color: _teal, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: widget.onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_teal, _tealLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _teal.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: _white),
                  SizedBox(width: 8),
                  Text(
                    'Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _white, letterSpacing: 0.5),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: _white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
