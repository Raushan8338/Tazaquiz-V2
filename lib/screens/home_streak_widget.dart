import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/daily_quiz_attempt_list.dart';
import 'package:tazaquiznew/screens/daily_quiz_screen.dart';
import 'package:tazaquiznew/utils/richText.dart';

/// 🔥 Daily Streak Widget
class HomeStreakWidget extends StatelessWidget {
  final String streakDays;
  final String todayChallengeName;
  final int totalQuestions;
  final int durationMinutes;
  final VoidCallback? onStartQuiz;
  final bool checkattempted;

  const HomeStreakWidget({
    Key? key,
    this.streakDays = "Today's Quiz",
    this.todayChallengeName = "Today's Quiz",
    this.totalQuestions = 10,
    this.durationMinutes = 5,
    this.onStartQuiz,
    required this.checkattempted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Left – Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      streakDays,
                      15,
                      AppColors.darkNavy,
                      FontWeight.w800,
                      1,
                      TextAlign.left,
                      0,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  todayChallengeName,
                  12,
                  AppColors.greyS600,
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  0,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pill(Icons.help_outline, '$totalQuestions Qs', Colors.blue),
                    const SizedBox(width: 8),
                    _pill(Icons.timer_outlined, '$durationMinutes min', Colors.orange),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// Right – Two buttons stacked vertically
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// View Results Button
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ResultsScreen()));
                },
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6E6E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0D6E6E).withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 13, color: Color(0xFF0D6E6E)),
                      const SizedBox(width: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'View Results',
                        10,
                        const Color(0xFF0D6E6E),
                        FontWeight.w600,
                        1,
                        TextAlign.center,
                        0,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// Start Now / Done Button
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DailyQuizScreen()));
                },
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D6E6E).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        checkattempted ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        checkattempted ? 'Done!' : 'Start Now',
                        10,
                        Colors.white,
                        FontWeight.w700,
                        1,
                        TextAlign.center,
                        0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
