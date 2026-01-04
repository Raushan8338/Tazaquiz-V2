import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';

class CoachingProfileWidget extends StatelessWidget {
  const CoachingProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 15, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,

                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    '🔥 Coaching Profiles',
                    14,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 4),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Most loved by students',
                    12,
                    AppColors.greyS600,
                    FontWeight.w500,
                    1,
                    TextAlign.left,
                    0.0,
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
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: MediaQuery.of(context).size.width / 1.3,
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.darkNavy.withOpacity(0.1), blurRadius: 24, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image with gradient
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Banner
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.darkNavy, AppColors.tealGreen],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                right: -50,
                                top: -50,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -30,
                                bottom: -30,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.lightGold.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Rating Badge
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.lightGold,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lightGold.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 16, color: AppColors.darkNavy),
                                SizedBox(width: 4),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  '4.8',
                                  12,
                                  AppColors.darkNavy,
                                  FontWeight.w700,
                                  1,
                                  TextAlign.center,
                                  0.0,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Profile Icon (overlapping)
                        Positioned(
                          bottom: -35,
                          left: 24,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.white,
                              border: Border.all(color: AppColors.lightGold, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkNavy.withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.tealGreen.withOpacity(0.3), AppColors.darkNavy.withOpacity(0.2)],
                                ),
                              ),
                              child: Center(
                                child: AppRichText.setTextPoppinsStyle(
                                  context,
                                  'IG',
                                  20,
                                  AppColors.darkNavy,
                                  FontWeight.w900,
                                  1,
                                  TextAlign.center,
                                  0.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Content Section
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 45, 24, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coaching Name
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'IG Coding Classes',
                            16,
                            AppColors.darkNavy,
                            FontWeight.w900,
                            2,
                            TextAlign.left,
                            1.3,
                          ),
                          SizedBox(height: 2),

                          // Tagline
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'Best coding classes in the city',
                            12,
                            AppColors.darkNavy.withOpacity(0.6),
                            FontWeight.w500,
                            2,
                            TextAlign.left,
                            1.4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Usage: CoachingProfileWidget()
