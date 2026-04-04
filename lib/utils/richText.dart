import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'fonts.dart';

class AppRichText {
  /// 🔥 App Header / AppBar Title / Page Title
  static Widget appHeader(String text, {Color? color, TextAlign align = TextAlign.start}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.appHeader.copyWith(color: color))],
    );
  }

  /// 🧩 Section Title (Score Distribution, Top Categories, Answer Breakdown)
  static Widget sectionTitle(String text, {Color? color, TextAlign align = TextAlign.start}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.sectionTitle.copyWith(color: color))],
    );
  }

  /// ❓ Quiz Question
  static Widget question(String text, {TextAlign align = TextAlign.start, int? maxLines}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      spans: [TranslatedSpan(text: text, style: AppFonts.question)],
    );
  }

  /// ✅ Answer Option
  static Widget answer(String text, {TextAlign align = TextAlign.start}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.answer)],
    );
  }

  /// 📝 Normal Body Text
  static Widget body(String text, {TextAlign align = TextAlign.start, Color? color}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.bodyText.copyWith(color: color))],
    );
  }

  /// ⭐ Highlight / Score / Rank / Timer
  static Widget highlight(String text, {Color? color}) {
    return TranslatedRichText(
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.highlight.copyWith(color: color))],
    );
  }

  /// 🔢 Stat Value (Large bold numbers — Score%, Correct, Wrong, Rank in cards)
  static Widget statValue(String text, {Color? color, double? fontSize}) {
    return TranslatedRichText(
      softWrap: true,
      spans: [
        TranslatedSpan(
          text: text,
          style: AppFonts.highlight.copyWith(color: color, fontSize: fontSize ?? 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  /// ⏱️ Caption / Small Label (date, time, chip label, footer text)
  static Widget caption(String text, {Color? color, TextAlign align = TextAlign.start}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      spans: [TranslatedSpan(text: text, style: AppFonts.caption.copyWith(color: color))],
    );
  }

  /// 🔘 Button Text
  static Widget button(String text, {Color? color}) {
    return TranslatedRichText(
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.button.copyWith(color: color))],
    );
  }

  /// 🧩 Mixed Style Text (Bold + Normal)
  static Widget mixed({required String boldText, required String normalText, TextAlign align = TextAlign.start}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      spans: [
        TranslatedSpan(text: boldText, style: AppFonts.bodyText.copyWith(fontWeight: FontWeight.w600)),
        TranslatedSpan(text: normalText, style: AppFonts.bodyText),
      ],
    );
  }

  /// 🎨 Custom Poppins Style (Legacy support)
  static Widget setTextPoppinsStyle(
    context,
    String text,
    double fontSize,
    Color color,
    FontWeight fontWeight,
    int lines,
    TextAlign textAlign,
    double letterSpacing,
  ) {
    return TranslatedRichText(
      overflow: TextOverflow.ellipsis,
      maxLines: lines,
      textAlign: textAlign,
      spans: [
        TranslatedSpan(
          text: text,
          style: TextStyle(
            fontStyle: FontStyle.normal,
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            fontFamily: 'Poppins',
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }

  /// ~~Strikethrough~~ Style (Legacy support)
  static Widget setTextLineThroughStyle(
    context,
    String text,
    double fontSize,
    Color color,
    FontWeight fontWeight,
    int lines,
    TextAlign textAlign,
    double letterSpacing,
  ) {
    return TranslatedRichText(
      overflow: TextOverflow.ellipsis,
      maxLines: lines,
      spans: [
        TranslatedSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            fontFamily: 'Poppins',
            letterSpacing: letterSpacing,
          ),
        ),
      ],
      textAlign: textAlign,
    );
  }
}
