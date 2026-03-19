import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'fonts.dart';

class AppRichText {
  /// ❓ Quiz Question (Responsive & Small Screen Safe)
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
  static Widget body(String text, {TextAlign align = TextAlign.start}) {
    return TranslatedRichText(
      textAlign: align,
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.bodyText)],
    );
  }

  /// ⭐ Highlight / Eye Catch
  static Widget highlight(String text, {Color? color}) {
    return TranslatedRichText(
      softWrap: true,
      spans: [TranslatedSpan(text: text, style: AppFonts.highlight.copyWith(color: color))],
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
    // ✅ RichText → TranslatedRichText
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
