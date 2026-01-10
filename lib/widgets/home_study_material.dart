import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/home_page_modal.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/utils/richText.dart';

class HomeStudyMaterials extends StatefulWidget {
  final List<StudyMaterialItem> studyMaterials;
  final HomeSection homeSections;

  HomeStudyMaterials({super.key, required this.studyMaterials, required this.homeSections});

  @override
  State<HomeStudyMaterials> createState() => _HomeStudyMaterialsState();
}

class _HomeStudyMaterialsState extends State<HomeStudyMaterials> {
  bool isLoading = true;
  bool hasData = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 15, 10, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    '📚 ${widget.homeSections.title}',
                    14,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      widget.homeSections.subtitle ?? '',
                      12,
                      AppColors.greyS600,
                      FontWeight.w500,
                      2,
                      TextAlign.left,
                      0.0,
                    ),
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
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: widget.studyMaterials.length,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemBuilder: (context, index) {
              StudyMaterialItem material = widget.studyMaterials[index];
              return _buildMaterialCard(material);
            },
          ),
        ),
      ],
    );
  }

  List<Color> _getCardColors(int index) {
    final gradients = [
      [AppColors.darkNavy, AppColors.tealGreen],
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFEC4899), const Color(0xFFF59E0B)],
      [const Color(0xFF10B981), const Color(0xFF06B6D4)],
      [const Color(0xFFEF4444), const Color(0xFFF97316)],
    ];
    return gradients[index % gradients.length];
  }

  IconData _getIconForIndex(int index) {
    final icons = [
      Icons.menu_book_rounded,
      Icons.science_rounded,
      Icons.calculate_rounded,
      Icons.language_rounded,
      Icons.history_edu_rounded,
    ];
    return icons[index % icons.length];
  }

  Widget _buildMaterialCard(material) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectContentPage(material.id)));
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(left: 6, right: 6, top: 16, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              material.boardIcon != null && material.boardIcon!.isNotEmpty
                  ? null // Image hai to gradient nahi
                  : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getCardColors(int.parse(material.id)),
                  ),
          image:
              material.boardIcon != null && material.boardIcon!.isNotEmpty
                  ? DecorationImage(
                    image: NetworkImage(material.boardIcon!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3), // Dark overlay for text readability
                      BlendMode.darken,
                    ),
                  )
                  : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  material.boardIcon != null && material.boardIcon!.isNotEmpty
                      ? Colors.black.withOpacity(0.3)
                      : _getCardColors(int.parse(material.id))[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForIndex(int.parse(material.id)),
                          size: 24,
                          color:
                              material.boardIcon != null && material.boardIcon!.isNotEmpty
                                  ? AppColors.darkNavy
                                  : _getCardColors(int.parse(material.id))[0],
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        material.title,
                        12,
                        AppColors.white,
                        FontWeight.w900,
                        2,
                        TextAlign.left,
                        1.2,
                      ),
                      const SizedBox(height: 4),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        material.description,
                        11,
                        AppColors.white.withOpacity(0.85),
                        FontWeight.w600,
                        2,
                        TextAlign.left,
                        1.0,
                      ),
                    ],
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectContentPage(material.id)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_rounded, size: 16, color: AppColors.darkNavy),
                        const SizedBox(width: 6),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'View Material',
                          12,
                          AppColors.darkNavy,
                          FontWeight.w800,
                          1,
                          TextAlign.center,
                          0.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.menu_book_rounded, size: 25, color: AppColors.lightGold),
            ),
          ],
        ),
      ),
    );
  }
}
