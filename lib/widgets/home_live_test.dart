import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/quizListDetailsPage.dart';
import 'package:tazaquiznew/utils/richText.dart';

class Home_live_test extends StatefulWidget {
  final List<QuizItem> liveTests;
  final HomeSection homeSections;

  Home_live_test({super.key, required this.liveTests, required this.homeSections});

  @override
  State<Home_live_test> createState() => _Home_live_testState();
}

class _Home_live_testState extends State<Home_live_test> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const List<List<Color>> _placeholderGradients = [
    [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
    [Color(0xFF1A2340), Color(0xFF2D5F8A)],
    [Color(0xFF6B21A8), Color(0xFF9333EA)],
    [Color(0xFF991B1B), Color(0xFFDC2626)],
    [Color(0xFF065F46), Color(0xFF059669)],
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// ── Section Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  /// Pulsing red dot
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(_pulseAnim.value * 0.2),
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.6 + _pulseAnim.value * 0.4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Tests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkNavy,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        '⚡ Abhi join karo, rank badhao!',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.tealGreen),
                      ),
                    ],
                  ),
                ],
              ),

              /// View All button
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QuizListScreen('1')));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.tealGreen.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(fontSize: 11, color: AppColors.tealGreen, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.tealGreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// ── Cards ──
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.liveTests.length,
            padding: const EdgeInsets.only(left: 2),
            itemBuilder: (context, index) {
              final quiz = widget.liveTests[index];
              final isLive = quiz.quizStatus == 'live';
              final gradientColors = _placeholderGradients[index % _placeholderGradients.length];
              final hasImage = quiz.banner != null && quiz.banner!.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizDetailPage(quizId: quiz.quizId, is_subscribed: false)),
                  );
                },
                child: Container(
                  width: 195,
                  margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: gradientColors[0].withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        /// Background
                        Positioned.fill(
                          child:
                              hasImage
                                  ? Image.network(
                                    quiz.banner!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: gradientColors,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                        ),
                                  )
                                  : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                        ),

                        /// Dark overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        /// Content
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /// Top — status + icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLive ? Colors.red : Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isLive) ...[
                                          AnimatedBuilder(
                                            animation: _pulseAnim,
                                            builder:
                                                (context, _) => Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white.withOpacity(_pulseAnim.value),
                                                  ),
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          isLive ? 'LIVE' : 'UPCOMING',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 13),
                                  ),
                                ],
                              ),

                              /// Bottom — title + level + button
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.bar_chart_rounded, size: 11, color: Colors.white70),
                                      const SizedBox(width: 3),
                                      Text(
                                        quiz.difficultyLevel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => QuizDetailPage(quizId: quiz.quizId, is_subscribed: false),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        minimumSize: const Size(0, 32),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isLive ? '⚡ Join Now' : '🔔 Remind Me',
                                        style: TextStyle(
                                          color: gradientColors[0],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
