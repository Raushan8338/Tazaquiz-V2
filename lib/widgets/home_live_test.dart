import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/screens/quizListDetailsPage.dart';
import 'package:tazaquiznew/screens/testSeries.dart';
import 'package:tazaquiznew/utils/richText.dart';

class Home_live_test extends StatelessWidget {
  final List<QuizItem> liveTests;
  final HomeSection homeSections;

  Home_live_test({super.key, required this.liveTests, required this.homeSections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(10, 15, 10, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    homeSections.title == 'Live Tests' ? '🔴 ${homeSections.title}' : homeSections.title,
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
                    homeSections.subtitle ?? '',
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
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QuizListScreen('1')));
                },
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
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: liveTests.length,
            padding: EdgeInsets.symmetric(horizontal: 0),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizDetailPage(quizId: liveTests[index].quizId),
                      // LiveTestScreen(
                      //   testTitle: liveTests[index].title,
                      //   subject: liveTests[index].difficultyLevel,
                      //   Quiz_id: liveTests[index].quizId,
                      // ),
                    ),
                  );
                },
                child: Container(
                  width: 280,
                  margin: EdgeInsets.only(left: index == 0 ? 6 : 6, right: index == 4 ? 6 : 6, top: 16, bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.darkNavy, AppColors.tealGreen],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: liveTests[index].quizStatus == 'live' ? AppColors.red : AppColors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 🔴 DOT ONLY FOR LIVE
                                      if (liveTests[index].quizStatus == 'live') ...[
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 6),
                                      ],

                                      // TEXT
                                      AppRichText.setTextPoppinsStyle(
                                        context,
                                        liveTests[index].quizStatus == 'live' ? 'LIVE' : 'UPCOMING',
                                        10,
                                        AppColors.white,
                                        liveTests[index].quizStatus == 'live' ? FontWeight.w700 : FontWeight.w600,
                                        1,
                                        TextAlign.left,
                                        0.2,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 8),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  liveTests[index].title,
                                  14,
                                  AppColors.white,
                                  FontWeight.w900,
                                  1,
                                  TextAlign.left,
                                  1.2,
                                ),
                                SizedBox(height: 4),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  liveTests[index].difficultyLevel,
                                  11,
                                  AppColors.lightGold,
                                  FontWeight.w600,
                                  1,
                                  TextAlign.left,
                                  0.0,
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lightGold,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size(0, 36), // Fixed button height
                              ),
                              child: AppRichText.setTextPoppinsStyle(
                                context,
                                'Join Now',
                                13,
                                AppColors.darkNavy,
                                FontWeight.w800,
                                1,
                                TextAlign.center,
                                0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.bolt, size: 30, color: AppColors.lightGold),
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
