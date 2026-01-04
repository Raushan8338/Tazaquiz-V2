import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AppHtmlText extends StatelessWidget {
  final String html;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final double lineHeight;
  final TextAlign textAlign;
  final int? maxLines;

  const AppHtmlText({
    Key? key,
    required this.html,
    this.fontSize = 12,
    this.color = Colors.black,
    this.fontWeight = FontWeight.w400,
    this.lineHeight = 1.4,
    this.textAlign = TextAlign.left,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Html(
      data: html,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          textAlign: textAlign,
          maxLines: maxLines,
          textOverflow: TextOverflow.ellipsis,
        ),
        "p": Style(
          fontSize: FontSize(fontSize),
          color: color,
          fontWeight: fontWeight,
          lineHeight: LineHeight(lineHeight),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "*": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      },
    );
  }
}
