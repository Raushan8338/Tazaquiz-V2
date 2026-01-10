import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/course_item_modal.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/utils/richText.dart';

class Home_courses extends StatelessWidget {
  final List<CourseItem> popularCourses;
  final HomeSection homeSections;

  Home_courses({required this.popularCourses, required this.homeSections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, 20, 10, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        '${homeSections.title}🔥',
                        15,
                        AppColors.darkNavy,
                        FontWeight.w800,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                      SizedBox(height: 2),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        homeSections.subtitle ?? '',
                        11,
                        AppColors.greyS600,
                        FontWeight.w500,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.tealGreen.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'View All',
                        11,
                        AppColors.tealGreen,
                        FontWeight.w700,
                        1,
                        TextAlign.right,
                        0.0,
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.tealGreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 245,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 5),
            itemCount: popularCourses.length,
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BuyCoursePage(
                            contentId: course.id,
                          ),
                    ),
                  );
                },
                child: Container(
                  width: 220,
                  margin: EdgeInsets.only(right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkNavy.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                    border: Border.all(color: AppColors.black.withOpacity(0.06), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image/Icon Header with Badge
                      Stack(
                        children: [
                          Container(
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.tealGreen, AppColors.darkNavy],
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.school_rounded, size: 40, color: AppColors.lightGold),
                              ),
                            ),
                          ),
                          // Best Seller Badge
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightGold,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: AppRichText.setTextPoppinsStyle(
                                context,
                                'BESTSELLER',
                                8,
                                AppColors.darkNavy,
                                FontWeight.w900,
                                1,
                                TextAlign.center,
                                0.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Content
                      Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppRichText.setTextPoppinsStyle(
                              context,
                              course.courseName,
                              14,
                              AppColors.darkNavy,
                              FontWeight.w800,
                              2,
                              TextAlign.left,
                              1.2,
                            ),
                            SizedBox(height: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              course.description,
                              11,
                              AppColors.greyS600,
                              FontWeight.w500,
                              1,
                              TextAlign.left,
                              1.1,
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  '₹${course.price}',
                                  16,
                                  AppColors.tealGreen,
                                  FontWeight.w900,
                                  1,
                                  TextAlign.left,
                                  0.0,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkNavy.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 11, color: AppColors.darkNavy),
                                      SizedBox(width: 3),
                                      AppRichText.setTextPoppinsStyle(
                                        context,
                                        course.duration,
                                        9,
                                        AppColors.darkNavy,
                                        FontWeight.w600,
                                        1,
                                        TextAlign.left,
                                        0.0,
                                      ),
                                    ],
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
              );
            },
          ),
        ),
      ],
    );
  }
}
