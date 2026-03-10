import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ── Section Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${homeSections.title} 🔥',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkNavy,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '📚 Exam crack karo, aaj hi shuru karo!',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.tealGreen,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) => StudyMaterialScreen('1')));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.tealGreen.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.tealGreen,
                            fontWeight: FontWeight.w700,
                          )),
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

        /// ── Cards ──
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 2),
            itemCount: popularCourses.length,
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              final gradientColors = _gradients[index % _gradients.length];
              final hasImage = course.courseImage != null && course.courseImage!.isNotEmpty;
              final isFree = int.tryParse('${course.price}') != null &&
                  int.parse('${course.price}') < 1;

              return GestureDetector(
                onTap: () {
                  Navigator.push(context,
                    MaterialPageRoute(
                      builder: (context) => BuyCoursePage(
                          contentId: course.id, page_API_call: 'STUDY'),
                    ));
                },
                child: Container(
                  width: 195,
                  margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// ── Image / Gradient Header ──
                        SizedBox(
                          height: 110,
                          child: Stack(
                            children: [
                              /// Background
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

                              /// Dark overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.05),
                                        Colors.black.withOpacity(0.35),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              /// Center icon (no image)
                              if (!hasImage)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.school_rounded,
                                        size: 32, color: Colors.white),
                                  ),
                                ),

                              /// BESTSELLER badge — top right
                              Positioned(
                                top: 9, right: 9,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGold,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('BESTSELLER',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.darkNavy,
                                    )),
                                ),
                              ),

                              /// FREE / PAID badge — top left
                              Positioned(
                                top: 9, left: 9,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isFree
                                        ? Colors.green.shade500
                                        : Colors.orange.shade600,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isFree ? '🎁 FREE' : 'PAID',
                                    style: const TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// ── Card Body — sirf info, no button ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Course name
                              Text(
                                course.courseName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              /// Description
                              Text(
                                course.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.greyS600,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),

                              /// Duration + arrow
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time_rounded,
                                          size: 11, color: AppColors.greyS600),
                                      const SizedBox(width: 4),
                                      Text(
                                        course.duration,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.greyS600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: gradientColors[0],
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.arrow_forward_ios_rounded,
                                          size: 10, color: gradientColors[0]),
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