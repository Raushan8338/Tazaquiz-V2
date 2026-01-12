import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/htmlText.dart';
import 'package:tazaquiznew/utils/richText.dart';

// ========== SIMPLE COACHING PROFILE CARD WIDGET ==========
class CoachingProfileCard extends StatefulWidget {
  final String name;
  final String? bannerImg;
  final String coachingId;
  final String? profileIcon;
  final int studentCount;
  final int courseCount;
  final double rating;
  final String bioInfo;

  const CoachingProfileCard({
    Key? key,
    required this.name,
    this.bannerImg,
    required this.coachingId,
    this.profileIcon,
    this.studentCount = 10,
    this.courseCount = 10,
    this.rating = 4.8,
    required this.bioInfo,
  }) : super(key: key);

  @override
  State<CoachingProfileCard> createState() => _CoachingProfileCardState();
}

class _CoachingProfileCardState extends State<CoachingProfileCard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(widget.name),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.1), blurRadius: 24, offset: Offset(0, 8))],
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
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                        gradient:
                            widget.bannerImg != null && widget.bannerImg!.isNotEmpty
                                ? null // Banner hai to gradient nahi chahiye
                                : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.darkNavy, AppColors.tealGreen],
                                ),
                        image:
                            widget.bannerImg != null && widget.bannerImg!.isNotEmpty
                                ? DecorationImage(
                                  image: NetworkImage(Api_Client.baseUrl + widget.bannerImg!),
                                  fit: BoxFit.cover,
                                  onError: (error, stackTrace) {
                                    print('Banner image load failed: $error');
                                  },
                                )
                                : null,
                      ),
                      child:
                          widget.bannerImg != null && widget.bannerImg!.isNotEmpty
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
                            BoxShadow(color: AppColors.lightGold.withOpacity(0.4), blurRadius: 8, offset: Offset(0, 4)),
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
                            BoxShadow(color: AppColors.darkNavy.withOpacity(0.2), blurRadius: 16, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              widget.profileIcon != null && widget.profileIcon!.isNotEmpty
                                  ? Image.network(
                                    Api_Client.baseUrl + widget.profileIcon!,
                                    width: 62,
                                    height: 62,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Image load nahi hua to fallback
                                      return _buildNameInitial(widget.name, context);
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tealGreen),
                                      );
                                    },
                                  )
                                  : _buildNameInitial(widget.name, context),
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
                        widget.name,
                        14,
                        AppColors.darkNavy,
                        FontWeight.w900,
                        2,
                        TextAlign.left,
                        1.3,
                      ),
                      SizedBox(height: 2),

                      AppHtmlText(
                        html: widget.bioInfo,
                        fontSize: 12,
                        color: AppColors.darkNavy.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        lineHeight: 1.4,
                        maxLines: 2, // optional
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String Coachingname) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            Coachingname,
            14,
            AppColors.white,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
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
