import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';

/// 📰 Daily Current Affairs Widget - Compact
class HomeDailyCurrentAffairs extends StatelessWidget {
  const HomeDailyCurrentAffairs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = _getFormattedDate();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6E6E), Color(0xFF0A4F4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6E6E).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // TODO: Navigate to Current Affairs Page
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ── Header Row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.newspaper_rounded,
                              color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppRichText.setTextPoppinsStyle(
                              context, 'Aaj Ka Current Affairs', 12,
                              Colors.white, FontWeight.w700, 1, TextAlign.left, 0,
                            ),
                            AppRichText.setTextPoppinsStyle(
                              context, today, 9, Colors.white60,
                              FontWeight.w400, 1, TextAlign.left, 0,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          AppRichText.setTextPoppinsStyle(
                            context, 'Padho', 10, Colors.white,
                            FontWeight.w600, 1, TextAlign.left, 0,
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_ios,
                              size: 9, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(color: Colors.white24, thickness: 1, height: 1),
                const SizedBox(height: 10),

                /// ── News Points — compact ──
                _newsPoint('🇮🇳', 'PM Modi ne naya infrastructure plan launch kiya'),
                const SizedBox(height: 6),
                _newsPoint('💰', 'RBI ne repo rate 6.5% par stable rakhi'),
                const SizedBox(height: 6),
                _newsPoint('🏏', 'India ne T20 series 3-1 se jeeti'),

                const SizedBox(height: 12),

                /// ── Saari News Button — full width ──
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to full current affairs page
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.menu_book_rounded,
                            color: Colors.white, size: 13),
                        SizedBox(width: 6),
                        Text(
                          'Saari News Padho',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.white70, size: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newsPoint(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}