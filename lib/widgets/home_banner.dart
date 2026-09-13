import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/course_search_page.dart';
import 'package:tazaquiznew/screens/featured_live_test_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key, required this.imgLists});
  final List imgLists;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int activeIndex = 0;
  int _currentBannerIndex = 0;
  int _selectedNavIndex = 0;
  Timer? _bannerTimer;
  // Windows shows 3 banners at once in the slider (viewportFraction 1/3);
  // Android/iOS get the default 1.0, i.e. unchanged single-banner paging.
  final PageController _bannerController = PageController(viewportFraction: Platform.isWindows ? 1 / 3 : 1);

  // Quiz id of the currently spotlighted "featured live test" (pageType 10),
  // if any — so a 'quiz' banner pointing at that same quiz opens the
  // dedicated FeaturedLiveTestPage (with its own access/payment logic)
  // instead of the generic QuizDetailPage. There's only ever one active
  // featured quiz at a time, so a simple id match is enough — no per-tap
  // network call needed.
  String? _featuredQuizId;

  @override
  void initState() {
    super.initState();
    _startBannerAutoPlay();
    _loadFeaturedQuizId();
  }

  Future<void> _loadFeaturedQuizId() async {
    try {
      final authRepository = Authrepository(Api_Client.dio);
      final response = await authRepository.get_featured_live_test();
      if (response.statusCode == 200 && response.data['data'] != null && mounted) {
        setState(() => _featuredQuizId = response.data['data']['quiz_id']?.toString());
      }
    } catch (_) {}
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (widget.imgLists.isEmpty || !_bannerController.hasClients) {
        return;
      }
      if (_currentBannerIndex < widget.imgLists.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      _bannerController.animateToPage(
        _currentBannerIndex,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (widget.imgLists.isEmpty) {
      return Container(
        height: screenWidth / 2.5,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.grey[200]),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF00BFB3))),
      );
    }
    // Windows runs in a wide desktop window: use the full width and show
    // 3 banners at a time (see _bannerController's viewportFraction)
    // instead of one mobile-sized banner. Android/iOS keep the original
    // fixed 150 height.
    final double bannerHeight = Platform.isWindows ? (screenWidth / 3) / 2.2 : 150;

    return Container(
      height: bannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            // With viewportFraction < 1 (Windows), PageView reserves
            // leading/trailing blank space by default so the first page
            // can be centered — padEnds:false removes that so banner 0
            // starts flush at the left edge instead of showing blank.
            padEnds: !Platform.isWindows,
            itemCount: widget.imgLists.length,
            onPageChanged: (index) {
              setState(() {
                activeIndex = index;
              });
            },
            itemBuilder: (context, index) {
          
              return GestureDetector(
                onTap: () {
                  if (widget.imgLists[index]['banner_type'] == 'quiz') {
                    final String quizId = widget.imgLists[index]['url'].toString();
                    if (_featuredQuizId != null && quizId == _featuredQuizId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FeaturedLiveTestPage(quizId: quizId)),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QuizDetailPage(
                                pageType_data: '7',
                                quizId: widget.imgLists[index]['url'], is_subscribed: false, courseId: widget.imgLists[index]['course_id'].toString(),
                        ),
                      ),);
                    }
                    // Handle URL tap, e.g., open in browser
                  } else if (widget.imgLists[index]['banner_type'] == 'course') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                BuyCoursePage(contentId: widget.imgLists[index]['url'], page_API_call: 'SUBSCRIPTION'),
                      ),
                    );
                    // Handle banner type tap, e.g., navigate to specific screen
                  } else if (widget.imgLists[index]['banner_type'] == 'all_course') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudyMaterialSearchScreen()));
                    // Handle banner type tap, e.g., navigate to specific screen
                  } else if (widget.imgLists[index]['banner_type'] == 'url') {
                    launchUrl(widget.imgLists[index]['url']);
                  } else {}
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: Api_Client.baseUrl_main + widget.imgLists[index]['banner'] ?? '',
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator(color: Color(0xFF00BFB3))),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: const Color(0xFF00BFB3).withOpacity(0.2),
                            child: Center(
                              child: Icon(Icons.quiz, size: 50, color: const Color(0xFF00BFB3).withOpacity(0.7)),
                            ),
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imgLists.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeIndex == index ? const Color(0xFF00BFB3) : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
