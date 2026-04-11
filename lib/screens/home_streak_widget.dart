import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/daily_quiz_attempt_list.dart';
import 'package:tazaquiznew/screens/daily_quiz_screen.dart';

class HomeStreakWidget extends StatelessWidget {
  final String streakDays;
  final String todayChallengeName;
  final int totalQuestions;
  final int durationMinutes;
  final VoidCallback? onStartQuiz;
  final bool checkattempted;

  const HomeStreakWidget({
    Key? key,
    this.streakDays = "Daily GK Challenge",
    this.todayChallengeName = "Current Affairs · GK · Science",
    this.totalQuestions = 15,
    this.durationMinutes = 8,
    this.onStartQuiz,
    required this.checkattempted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ── Top bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: checkattempted
                      ? const Color(0xFF888780)
                      : const Color(0xFFE05A3A),
                  width: 3,
                ),
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.07),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                /// Live dot
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: checkattempted
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFFE05A3A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  checkattempted ? 'Attempted' : 'Live',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: checkattempted
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFFE05A3A),
                  ),
                ),
                const Spacer(),

                /// Daily badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: checkattempted
                        ? const Color(0xFFF1EFE8)
                        : const Color(0xFFFFF3F0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: checkattempted
                          ? const Color(0xFF888780).withOpacity(0.25)
                          : const Color(0xFFE05A3A).withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '⭐ Daily',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: checkattempted
                          ? const Color(0xFF5F5E5A)
                          : const Color(0xFFC04A2A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Left: title + subtitle + pills
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        streakDays.isNotEmpty
                            ? streakDays
                            : 'Daily GK Challenge',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        todayChallengeName.isNotEmpty
                            ? todayChallengeName
                            : 'Current Affairs · GK · Science',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black.withOpacity(0.45),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          _pill(
                            Icons.help_outline_rounded,
                            '$totalQuestions Qs',
                            const Color(0xFF185FA5),
                            const Color(0xFFE6F1FB),
                          ),
                          const SizedBox(width: 5),
                          _pill(
                            Icons.access_time_rounded,
                            '$durationMinutes min',
                            const Color(0xFF854F0B),
                            const Color(0xFFFAEEDA),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                /// Right: Results + Start/Done buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Results button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ResultsScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5EE),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(0xFF0F6E56).withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 10,
                              color: Color(0xFF0F6E56),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Results',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F6E56),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    /// Start Now / Done button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DailyQuizScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: checkattempted
                              ? const Color(0xFFF1EFE8)
                              : const Color(0xFF1D9E75),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              checkattempted
                                  ? Icons.check_rounded
                                  : Icons.play_arrow_rounded,
                              size: 11,
                              color: checkattempted
                                  ? const Color(0xFF5F5E5A)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              checkattempted ? 'Done!' : 'Start Now',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: checkattempted
                                    ? const Color(0xFF5F5E5A)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}