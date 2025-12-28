import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';

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
  final PageController _bannerController = PageController();
  @override
  void initState() {
    super.initState();
    _startBannerAutoPlay();
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(Duration(seconds: 4), (timer) {
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
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            itemCount: widget.imgLists.length,
            onPageChanged: (index) {
              setState(() {
                activeIndex = index;
              });
            },
            itemBuilder: (context, index) {
              print('Banner Images: ${Api_Client.baseUrl + widget.imgLists[index]['banner']}');
              return Container(
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
                    imageUrl: Api_Client.baseUrl + widget.imgLists[index]['banner'] ?? '',
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
