import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/mock_test_detail_page.dart';
import 'package:tazaquiznew/screens/quizListDetailsPage.dart';

class HomeMockTest extends StatefulWidget {
  final List<QuizItem> mockTests;
  final HomeSection homeSections;

  HomeMockTest({super.key, required this.mockTests, required this.homeSections});

  @override
  State<HomeMockTest> createState() => _HomeMockTestState();
}

class _HomeMockTestState extends State<HomeMockTest> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  // Mock test ke liye alag color palette — professional/study feel
  static const List<List<Color>> _mockGradients = [
    [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
    [Color(0xFF1A2340), Color(0xFF2D5F8A)],
    [Color(0xFF6B21A8), Color(0xFF9333EA)],
    [Color(0xFF991B1B), Color(0xFFDC2626)],
    [Color(0xFF065F46), Color(0xFF059669)],
  ];

  static const List<List<Color>> _safeGradients = [
    [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
    [Color(0xFF1A2340), Color(0xFF2D5F8A)],
    [Color(0xFF6B21A8), Color(0xFF9333EA)],
    [Color(0xFF991B1B), Color(0xFFDC2626)],
    [Color(0xFF065F46), Color(0xFF059669)],
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _shimmerAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Section Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Pencil icon with animated glow
                  AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (context, child) {
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1a237e).withOpacity(_shimmerAnim.value * 0.15),
                          border: Border.all(
                            color: const Color(0xFF1a237e).withOpacity(_shimmerAnim.value * 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(child: TranslatedText('📝', style: TextStyle(fontSize: 16))),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mock Tests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkNavy,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TranslatedText(
                        '🎯 Practice karo, exam crack karo!',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF1a237e)),
                      ),
                    ],
                  ),
                ],
              ),

              // View All button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // quiz_type=2 for mock tests — aapke QuizListScreen mein filter pass karo
                      builder: (context) => QuizListScreen('1', '4'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a237e).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1a237e).withOpacity(0.25), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TranslatedText(
                        'View All',
                        style: TextStyle(fontSize: 11, color: const Color(0xFF1a237e), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: const Color(0xFF1a237e)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Cards ──
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.mockTests.length,
            padding: const EdgeInsets.only(left: 2),
            itemBuilder: (context, index) {
              final quiz = widget.mockTests[index];
              final gradientColors = _safeGradients[index % _safeGradients.length];
              final hasImage = quiz.banner != null && quiz.banner!.isNotEmpty;

              // Mock test status
              final isCompleted = quiz.quizStatus == 'completed';
              final isAttempted = quiz.is_attempted;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MockTestDetailPage(quizId: quiz.quizId)),
                  );
                },
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // ── Background ──
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

                        // Subtle pattern overlay — mock test feel
                        Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

                        // Dark overlay bottom
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.65)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // ── Content ──
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top row — status badge + icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          isAttempted
                                              ? Colors.green.shade600
                                              : isCompleted
                                              ? Colors.grey.shade600
                                              : Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isAttempted ? Icons.check_circle_rounded : Icons.assignment_outlined,
                                          color: Colors.white,
                                          size: 9,
                                        ),
                                        const SizedBox(width: 4),
                                        TranslatedText(
                                          isAttempted ? 'DONE' : 'MOCK TEST',
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

                                  // Quiz info icon
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.description_outlined, color: Colors.white, size: 13),
                                  ),
                                ],
                              ),

                              // Bottom — info + button
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  TranslatedText(
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
                                  const SizedBox(height: 5),

                                  // Questions + time info row
                                  Row(
                                    children: [
                                      const Icon(Icons.help_outline_rounded, size: 10, color: Colors.white70),
                                      const SizedBox(width: 3),
                                      TranslatedText(
                                        quiz.difficultyLevel.isNotEmpty ? quiz.difficultyLevel : 'Standard',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (quiz.timeLimit.isNotEmpty) ...[
                                        const Icon(Icons.timer_outlined, size: 10, color: Colors.white60),
                                        const SizedBox(width: 3),
                                        TranslatedText(
                                          '${quiz.timeLimit} min',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white60,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // CTA Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MockTestDetailPage(quizId: quiz.quizId),
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
                                      child: TranslatedText(
                                        isAttempted ? '📊 View Result' : '✏️ Start Test',
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

// Subtle dot pattern — mock test / exam paper feel
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..strokeWidth = 1;

    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
