import 'package:flutter/material.dart';

// Same languages, same order as the language sheet in the test screens.
const List<Map<String, String>> kPageLanguages = [
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

String pageLanguageNative(String code) =>
    kPageLanguages.firstWhere((l) => l['code'] == code, orElse: () => {'native': code})['native'] ?? code;

String pageLanguageLabel(String code) =>
    kPageLanguages.firstWhere((l) => l['code'] == code, orElse: () => {'label': code})['label'] ?? code;

/// "Page Language" bottom sheet — the same design as the one in the test screens
/// (mockTestScreen), with the title / hint texts as parameters so notes can use it too.
class LangPickerSheet extends StatelessWidget {
  final List<Map<String, String>> languages;
  final String activeLang;
  final String globalLang;
  final ValueChanged<String> onSelect;
  final VoidCallback onReset;
  final String subtitle;
  final String info;

  const LangPickerSheet({
    super.key,
    this.languages = kPageLanguages,
    required this.activeLang,
    required this.globalLang,
    required this.onSelect,
    required this.onReset,
    this.subtitle = 'Only questions & answers will translate',
    this.info = 'Only questions & answers translate. Scores, timer and UI stay as-is.',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Page Language',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                    ),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
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
                    boxShadow: isActive
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
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: _teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(info, style: const TextStyle(fontSize: 11, color: _darkNavy, height: 1.5)),
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
