import 'package:flutter/material.dart';
import 'fonts.dart';

class AppRichText {
  /// ❓ Quiz Question (Responsive & Small Screen Safe)
  static Widget question(String text, {TextAlign align = TextAlign.start, int? maxLines}) {
    return RichText(
      textAlign: align,
      textScaleFactor: WidgetsBinding.instance.platformDispatcher.textScaleFactor,
      softWrap: true,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      text: TextSpan(text: text, style: AppFonts.question),
    );
  }

  /// ✅ Answer Option
  static Widget answer(String text, {TextAlign align = TextAlign.start}) {
    return RichText(
      textAlign: align,
      softWrap: true,
      text: TextSpan(text: text, style: AppFonts.answer),
    );
  }

  /// 📝 Normal Body Text
  static Widget body(String text, {TextAlign align = TextAlign.start}) {
    return RichText(
      textAlign: align,
      softWrap: true,
      text: TextSpan(text: text, style: AppFonts.bodyText),
    );
  }

  /// ⭐ Highlight / Eye Catch
  static Widget highlight(String text, {Color? color}) {
    return RichText(
      softWrap: true,
      text: TextSpan(
        text: text,
        style: AppFonts.highlight.copyWith(color: color),
      ),
    );
  }

  /// 🧩 Mixed Style Text (Bold + Normal)
  static Widget mixed({required String boldText, required String normalText, TextAlign align = TextAlign.start}) {
    return RichText(
      textAlign: align,
      softWrap: true,
      text: TextSpan(
        children: [
          TextSpan(
            text: boldText,
            style: AppFonts.bodyText.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: normalText, style: AppFonts.bodyText),
        ],
      ),
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
    double letterSpacing
  ) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: lines,
      text: TextSpan(
        style: TextStyle(
          fontStyle: FontStyle.normal,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontFamily: 'Poppins',
          letterSpacing : letterSpacing
        ),
        text: text,
      ),
      textAlign: textAlign,
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
    double letterSpacing
  ) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: lines,
      
      text: TextSpan(
        style: TextStyle(
          decoration: TextDecoration.lineThrough,
          fontStyle: FontStyle.normal,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontFamily: 'Poppins',
          letterSpacing : letterSpacing
          
        ),
        text: text,
      ),
      textAlign: textAlign,
    );
  }

}
