// ─────────────────────────────────────────────────────────────────────────────
//  locale_override.dart
//
//  Sirf yeh file project mein add karo.
//  Language page mein KUCH BHI mat badlo.
//
//  Kisi bhi screen pe use karna ho:
//    Step 1: Scaffold ko LocaleOverrideScope mein wrap karo
//    Step 2: AppBar actions mein → LangToggleButton()
//    Step 3: AppBar bottom mein  → LangStatusBanner()
//    Step 4: TranslatedText → SmartText (drop-in, same params)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  1. _LocaleNotifier  —  ChangeNotifier (private)
// ─────────────────────────────────────────────────────────────────────────────
class _LocaleNotifier extends ChangeNotifier {
  bool _isEnglish = false;
  bool get isEnglish => _isEnglish;

  void toggle() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  2. LocaleOverride  —  InheritedNotifier
// ─────────────────────────────────────────────────────────────────────────────
class LocaleOverride extends InheritedNotifier<_LocaleNotifier> {
  const LocaleOverride({super.key, required _LocaleNotifier notifier, required super.child})
    : super(notifier: notifier);

  static _LocaleNotifier of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<LocaleOverride>();
    assert(result != null, 'LocaleOverride.of() called outside of a LocaleOverrideScope');
    return result!.notifier!;
  }

  static _LocaleNotifier? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleOverride>()?.notifier;
}

// ─────────────────────────────────────────────────────────────────────────────
//  3. LocaleOverrideScope  —  Scaffold ke upar wrap karo
// ─────────────────────────────────────────────────────────────────────────────
class LocaleOverrideScope extends StatefulWidget {
  final Widget child;
  const LocaleOverrideScope({super.key, required this.child});

  @override
  State<LocaleOverrideScope> createState() => _LocaleOverrideScopeState();
}

class _LocaleOverrideScopeState extends State<LocaleOverrideScope> {
  final _notifier = _LocaleNotifier();

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocaleOverride(notifier: _notifier, child: widget.child);
}

// ─────────────────────────────────────────────────────────────────────────────
//  4. SmartText  —  Drop-in for TranslatedText
//
//  THE KEY FIX:
//  Jab isEnglish toggle hota hai, hum ValueKey('$isEnglish-$text') pass karte
//  hain. Flutter is key change ko dekh ke pura widget destroy + recreate
//  karta hai — iska matlab TranslatedText ka cached _future wipe ho jata hai
//  aur naya future banता hai. Isliye mix content nahi aata.
// ─────────────────────────────────────────────────────────────────────────────
class SmartText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SmartText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  @override
  Widget build(BuildContext context) {
    final notifier = LocaleOverride.maybeOf(context);
    final isEnglish = notifier?.isEnglish ?? false;

    if (isEnglish) {
      // Instant — koi future nahi, koi async nahi
      return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
    }

    // ValueKey force karta hai ki TranslatedText destroy+recreate ho
    // jab bhi isEnglish false se true se false ho — stale cache nahi bachega
    return TranslatedText(
      text,
      key: ValueKey('translated-$text'),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  5. LangToggleButton  —  AppBar actions: [ LangToggleButton() ]
//     App already English mein ho to automatically hide ho jata hai
// ─────────────────────────────────────────────────────────────────────────────
class LangToggleButton extends StatelessWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (TranslationService.instance.currentLanguage == 'en') {
      return const SizedBox.shrink();
    }

    final notifier = LocaleOverride.of(context);
    final isEnglish = notifier.isEnglish;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: notifier.toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isEnglish ? const Color(0xFF0D6E6E) : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isEnglish ? const Color(0xFF25C49A) : Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isEnglish ? Icons.translate_rounded : Icons.language_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                isEnglish ? 'EN' : 'APP',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  6. LangStatusBanner  —  AppBar bottom: bottom: LangStatusBanner()
//     App already English mein ho to automatically hide ho jata hai
// ─────────────────────────────────────────────────────────────────────────────
class LangStatusBanner extends StatelessWidget implements PreferredSizeWidget {
  const LangStatusBanner({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(26);

  @override
  Widget build(BuildContext context) {
    if (TranslationService.instance.currentLanguage == 'en') {
      return const SizedBox.shrink();
    }

    final notifier = LocaleOverride.of(context);
    final isEnglish = notifier.isEnglish;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      height: 26,
      color: isEnglish ? const Color(0xFF0D6E6E).withOpacity(0.9) : Colors.white.withOpacity(0.07),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isEnglish ? Icons.translate_rounded : Icons.language_rounded, size: 11, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            isEnglish ? 'Viewing in English  •  Tap EN to switch back' : 'Tap EN to view in English',
            style: const TextStyle(fontSize: 10.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
