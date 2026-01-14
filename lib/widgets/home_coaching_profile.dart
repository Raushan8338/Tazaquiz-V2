import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/coaching_item_modal.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/screens/coching_profile_page.dart';
import 'package:tazaquiznew/utils/htmlText.dart';
import 'package:tazaquiznew/utils/richText.dart';

class CoachingProfileWidget extends StatelessWidget {
  final List<CoachingItem> coachingProfiles;
  final HomeSection homeSections;

  CoachingProfileWidget({super.key, required this.coachingProfiles, required this.homeSections});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
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
                      '🔥 ${homeSections.title}',
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
                      homeSections.subtitle ?? 'Most loved by students',
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
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: coachingProfiles.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CoachingProfileCard(
                                name: coachingProfiles[index].coachingName,
                                bannerImg: coachingProfiles[index].bannerImg.toString(),
                                coachingId: coachingProfiles[index].id.toString(),
                                bioInfo: coachingProfiles[index].bioInfo.toString(),
                                profileIcon: coachingProfiles[index].profileIcon.toString(),
                              ),
                        ),
                      );
                    }
                  },
                  child: Container(
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
                                gradient:
                                    coachingProfiles[index].bannerImg != null &&
                                            coachingProfiles[index].bannerImg!.isNotEmpty
                                        ? null // Banner hai to gradient nahi chahiye
                                        : LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [AppColors.darkNavy, AppColors.tealGreen],
                                        ),
                                image:
                                    coachingProfiles[index].bannerImg != null &&
                                            coachingProfiles[index].bannerImg!.isNotEmpty
                                        ? DecorationImage(
                                          image: NetworkImage(Api_Client.baseUrl + coachingProfiles[index].bannerImg!),
                                          fit: BoxFit.cover,
                                          onError: (error, stackTrace) {
                                            print('Banner image load failed: $error');
                                          },
                                        )
                                        : null,
                              ),
                              child:
                                  coachingProfiles[index].bannerImg != null &&
                                          coachingProfiles[index].bannerImg!.isNotEmpty
                                      ? null // Banner hai to decorative circles nahi chahiye
                                      : Stack(
                                        children: [
                                          // Decorative circles (only when no banner)
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
                                child: ClipOval(
                                  child:
                                      coachingProfiles[index].profileIcon != null &&
                                              coachingProfiles[index].profileIcon!.isNotEmpty
                                          ? Image.network(
                                            Api_Client.baseUrl + coachingProfiles[index].profileIcon!,
                                            width: 62,
                                            height: 62,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              // Image load nahi hua to fallback
                                              return _buildNameInitial(coachingProfiles[index].coachingName, context);
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.tealGreen,
                                                ),
                                              );
                                            },
                                          )
                                          : _buildNameInitial(coachingProfiles[index].coachingName, context),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Content Section
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, 45, 24, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Coaching Name
                              AppRichText.setTextPoppinsStyle(
                                context,
                                coachingProfiles[index].coachingName,
                                14,
                                AppColors.darkNavy,
                                FontWeight.w900,
                                2,
                                TextAlign.left,
                                1.3,
                              ),
                              SizedBox(height: 2),

                              AppRichText.setTextPoppinsStyle(
                                context,
                                '✔ Verified by TazaQuiz',
                                10,
                                AppColors.greyS600,
                                FontWeight.w500,
                                1,
                                TextAlign.left,
                                0.0,
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
      ),
    );
  }

  Widget _buildNameInitial(String name, BuildContext context) {
    // First letter nikalo
    String initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    return Container(
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
          initial,
          20,
          AppColors.darkNavy,
          FontWeight.w900,
          1,
          TextAlign.center,
          0.0,
        ),
      ),
    );
  }
}

// Usage: CoachingProfileWidget()
