import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/course_item_modal.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/studyMaterial.dart';
import 'package:tazaquiznew/utils/richText.dart';

class Home_courses extends StatelessWidget {
  final List<CourseItem> popularCourses;
  final HomeSection homeSections;

  Home_courses({required this.popularCourses, required this.homeSections});

  static const List<List<Color>> _gradients = [
    [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
    [Color(0xFF1A2340), Color(0xFF2D5F8A)],
    [Color(0xFF6B21A8), Color(0xFF9333EA)],
    [Color(0xFF991B1B), Color(0xFFDC2626)],
    [Color(0xFF065F46), Color(0xFF059669)],
  ];

  // Duration empty ho toh fallback
  String _durationLabel(String? duration) {
    if (duration == null || duration.trim().isEmpty) return 'Enroll Now';
    return duration.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 16,
                      color: AppColors.tealGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${homeSections.title}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                          height: 1.2,
                        ),
                      ),
                      TranslatedText(
                        'Exam crack karo, aaj hi shuru karo!',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tealGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudyMaterialScreen('1')),
                ),
                child: Row(
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealGreen,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.tealGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// ── Cards ──
        SizedBox(
          height: 215,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 2, right: 4, bottom: 6, top: 2),
            itemCount: popularCourses.length,
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              final gradientColors = _gradients[index % _gradients.length];
              final hasImage = course.courseImage != null &&
                  course.courseImage!.isNotEmpty;
              final durationText = _durationLabel(course.duration);

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyCoursePage(
                      contentId: course.id,
                      page_API_call: 'SUBSCRIPTION',
                    ),
                  ),
                ),
                child: Container(
                  width: 172,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.07),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// ── Image / Gradient ──
                        SizedBox(
                          height: 100,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: hasImage
                                    ? Image.network(
                                        course.courseImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _gradientBox(gradientColors),
                                      )
                                    : _gradientBox(gradientColors),
                              ),

                              /// Bottom fade
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.38),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              /// Center icon
                              if (!hasImage)
                                Center(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                              /// BESTSELLER badge — top right only
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '⭐ BEST',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// ── Body ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TranslatedText(
                                course.courseName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              TranslatedText(
                                course.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.greyS600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              /// Duration pill + Details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gradientColors[0].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 9,
                                          color: gradientColors[0],
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          durationText,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: gradientColors[0],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: gradientColors[0],
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 9,
                                        color: gradientColors[0],
                                      ),
                                    ],
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

  Widget _gradientBox(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}