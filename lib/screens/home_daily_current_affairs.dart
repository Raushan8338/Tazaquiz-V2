import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/models/daily_news_modal.dart';
import 'package:tazaquiznew/screens/blog_Page.dart';
import 'package:tazaquiznew/utils/richText.dart';

class HomeDailyCurrentAffairs extends StatelessWidget {
  DailyNewsModel? dailyNews;
  HomeDailyCurrentAffairs({Key? key, this.dailyNews}) : super(key: key);

  // ── Tag color config ──
  static const _tagConfig = {
    'Economy': _TagStyle(bg: Color(0xFFE1F5EE), text: Color(0xFF0F6E56), dot: Color(0xFF1D9E75)),
    'Infra':   _TagStyle(bg: Color(0xFFE6F1FB), text: Color(0xFF185FA5), dot: Color(0xFF378ADD)),
    'Defence': _TagStyle(bg: Color(0xFFFAECE7), text: Color(0xFF993C1D), dot: Color(0xFFD85A30)),
    'Science': _TagStyle(bg: Color(0xFFEEEDFE), text: Color(0xFF3C3489), dot: Color(0xFF7F77DD)),
    'Sports':  _TagStyle(bg: Color(0xFFFAEEDA), text: Color(0xFF633806), dot: Color(0xFFBA7517)),
    'Polity':  _TagStyle(bg: Color(0xFFFBEAF0), text: Color(0xFF72243E), dot: Color(0xFFD4537E)),
    'World':   _TagStyle(bg: Color(0xFFF1EFE8), text: Color(0xFF444441), dot: Color(0xFF888780)),
    'Health':  _TagStyle(bg: Color(0xFFEAF3DE), text: Color(0xFF27500A), dot: Color(0xFF639922)),
  };

  static const _defaultTag = _TagStyle(
    bg: Color(0xFFF1EFE8),
    text: Color(0xFF5F5E5A),
    dot: Color(0xFF888780),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsPage()),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Current Affairs',
                    13,
                    const Color(0xFF1A1A1A),
                    FontWeight.w600,
                    1,
                    TextAlign.left,
                    0,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NewsPage()),
                    ),
                    child: Row(
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Read all',
                          12,
                          const Color(0xFF1D9E75),
                          FontWeight.w500,
                          1,
                          TextAlign.left,
                          0,
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFF1D9E75),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),

            // ── News List ──
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: dailyNews?.points.length ?? 0,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFEEEEEE),
              ),
              itemBuilder: (context, index) {
                final point = dailyNews!.points[index];
                final text = point['point2']?.toString() ?? '';
                final category = point['category']?.toString() ?? '';
                return _newsItem(text, category);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsItem(String text, String category) {
    final style = _tagConfig[category] ?? _defaultTag;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Colored dot ──
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Color(0xFF1D9E75),  // teal green
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),

          // ── News title (left, flexible) ──
          Expanded(
            child: TranslatedText(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // ── Category tag (right) ──
          if (category.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: style.text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helper class for tag styling ──
class _TagStyle {
  final Color bg;
  final Color text;
  final Color dot;
  const _TagStyle({required this.bg, required this.text, required this.dot});
}