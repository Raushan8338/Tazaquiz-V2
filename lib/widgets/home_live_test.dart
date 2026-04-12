import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/quizListDetailsPage.dart';
import 'package:tazaquiznew/utils/richText.dart';

class Home_live_test extends StatefulWidget {
  final List<QuizItem> liveTests;
  final HomeSection homeSections;

  Home_live_test(
      {super.key, required this.liveTests, required this.homeSections});

  @override
  State<Home_live_test> createState() => _Home_live_testState();
}

class _Home_live_testState extends State<Home_live_test>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const List<Color> _badgeColors = [
    Color(0xFF0D6E6E),
    Color(0xFF1A2340),
    Color(0xFF6B21A8),
    Color(0xFF991B1B),
    Color(0xFF065F46),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── startDateTime se day, month, time extract karo ───────────────────────

  Map<String, String> _parseDateMeta(String? startDateTime) {
    if (startDateTime == null || startDateTime.isEmpty) {
      return {'day': '--', 'month': '---', 'time': '--:--'};
    }
    try {
      final dt = DateTime.parse(startDateTime);
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      final hour   = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;

      return {
        'day':   dt.day.toString(),
        'month': months[dt.month - 1],
        'time':  '$hour12:$minute $period',
      };
    } catch (_) {
      return {'day': '--', 'month': '---', 'time': '--:--'};
    }
  }

  // ─── difficulty_level se category tag banao ───────────────────────────────

  String _getDifficultyTag(String? level) {
    switch ((level ?? '').toLowerCase()) {
      case 'easy':     return 'Easy';
      case 'medium':   return 'Medium';
      case 'advanced': return 'Advanced';
      case 'hard':     return 'Hard';
      default:         return level?.isNotEmpty == true ? level! : 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// ── Section Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  /// Pulsing red dot
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              Colors.red.withOpacity(_pulseAnim.value * 0.18),
                        ),
                        child: Center(
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red
                                  .withOpacity(0.6 + _pulseAnim.value * 0.4),
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
                         '${widget.homeSections.title}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkNavy,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TranslatedText(
                        '${widget.homeSections.subtitle}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.tealGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /// View All button
              GestureDetector(
                onTap: () {
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => QuizListScreen('1', '7')),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.tealGreen.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TranslatedText(
                        'View All',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.tealGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 13, color: AppColors.tealGreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// ── Horizontal Scrollable Cards ──
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.liveTests.length,
            padding: const EdgeInsets.only(left: 2, right: 2),
            itemBuilder: (context, index) {
              final quiz       = widget.liveTests[index];
              final isLive     = quiz.quizStatus == 'live';
              final badgeColor = _badgeColors[index % _badgeColors.length];

              // ✅ API se dynamic data
              final meta = _parseDateMeta(quiz.startDateTime);
              final tag  = _getDifficultyTag(quiz.difficultyLevel);

              return _buildCard(
                context,
                quiz:       quiz,
                isLive:     isLive,
                badgeColor: badgeColor,
                day:        meta['day']!,
                month:      meta['month']!,
                time:       meta['time']!,
                tag:        tag,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required QuizItem quiz,
    required bool isLive,
    required Color badgeColor,
    required String day,
    required String month,
    required String time,
    required String tag,
  }) {
    return GestureDetector(
      onTap: () {
        if (!quiz.isAccessible) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => BuyCoursePage(
                  contentId: quiz.subscription_id.toString(),
                  page_API_call: 'SUBSCRIPTION',
                ),));
          return;
        }
        else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizDetailPage(pageType_data: '7', quizId: quiz.quizId, is_subscribed: false),
          ),
        );
        }
      },
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// ── Top: Date badge + Category tag ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Date badge — API startDateTime se
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          month,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Category tag — API difficulty_level se
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              /// ── Title — API se ──
              TranslatedText(
                quiz.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              /// ── Time limit + Scheduled time — API se ──
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(
                    '${quiz.timeLimit ?? '--'} mins',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time_rounded,
                      size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(
                    time,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              /// ── Bottom: Status tag + Join/View button ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Status — API quiz_status se
                  if (isLive) ...[
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, _) => Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(
                                  0.6 + _pulseAnim.value * 0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'LIVE NOW',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFFFCDD2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.how_to_reg_rounded,
                              size: 10, color: Color(0xFFE53935)),
                          SizedBox(width: 3),
                          Text(
                            'Registering open',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  /// Join / View button
                  GestureDetector(
                    onTap: () {
                      if (!quiz.isAccessible) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => BuyCoursePage(
                  contentId: quiz.subscription_id.toString(),
                  page_API_call: 'SUBSCRIPTION',
                ),));
          return;
        }
        else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizDetailPage(pageType_data: '7', quizId: quiz.quizId, is_subscribed: false),
          ),
        );
        }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.red : AppColors.tealGreen,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isLive ? Colors.red : AppColors.tealGreen)
                                    .withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isLive ? 'Join' : 'View',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
      ),
    );
  }
}