import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/PackageFeatureItem.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/study_material_details_item.dart'
    hide StudyMaterialDetailsItem;
import 'package:tazaquiznew/screens/PDFViewerPage.dart';
import 'package:tazaquiznew/screens/Paid_quzes_list.dart';
import 'package:tazaquiznew/screens/buyStudyM.dart';
import 'package:tazaquiznew/screens/leaderboard_page.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/screens/quizListDetailsPage.dart';
import 'package:tazaquiznew/screens/studyMaterial.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyMaterialPurchaseHistoryScreen extends StatefulWidget {
  final String PageId;

  StudyMaterialPurchaseHistoryScreen(this.PageId);

  @override
  _StudyMaterialPurchaseHistoryScreenState createState() =>
      _StudyMaterialPurchaseHistoryScreenState();
}

class _StudyMaterialPurchaseHistoryScreenState
    extends State<StudyMaterialPurchaseHistoryScreen> {
  bool _isLoading = true;
  List<StudyMaterialDetailsItem> _allStudyMaterials = [];
  UserModel? _user;
  bool isExpired = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    await fetchStudyMaterials(_user!.id);
  }

  Future<void> fetchStudyMaterials(String user_id) async {
    setState(() => _isLoading = true);
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final responseFuture = await authRepository
          .fetchStudyMaterialsDetails({'user_id': user_id.toString()});
      if (responseFuture.statusCode == 200) {
        final List list = responseFuture.data['data'] ?? [];
        setState(() {
          _allStudyMaterials =
              list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(widget.PageId),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.tealGreen)))
          : _allStudyMaterials.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => fetchStudyMaterials(_user?.id ?? ''),
                  color: AppColors.tealGreen,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    itemCount: _allStudyMaterials.length,
                    itemBuilder: (context, index) =>
                        _buildCard(_allStudyMaterials[index]),
                  ),
                ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String pageId) {
    return AppBar(
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
leading: pageId == '1'
    ? IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_back, // ✅ back icon
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      )
    : (pageId == '0'
        ? IconButton(
            icon: const Icon(
              Icons.menu_book, // ✅ "My Courses" type icon
              color: Colors.white,
            ),
            onPressed: () {
              // navigate to My Courses page
            },
          )
        : const SizedBox()),
         
      
      
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'My Courses',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins'),
          ),
          if (!_isLoading)
            TranslatedText(
              '${_allStudyMaterials.length} course${_allStudyMaterials.length != 1 ? 's' : ''} purchased',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
          ),
        ),
      ),
    );
  }

  // ─── CARD ─────────────────────────────────────────────────────────────────

  Widget _buildCard(StudyMaterialDetailsItem material) {
    final bool isSubscription = material.contentType == 'SUBSCRIPTION';
    final bool hasImage = material.thumbnail.isNotEmpty;
    final DateTime? expiryDate =
    material.access_valid_until.isNotEmpty
        ? DateTime.tryParse(material.access_valid_until)
        : null;

  isExpired = expiryDate != null ? DateTime.now().isAfter(expiryDate) : false;

    final String pkgLabel = material.package_name.isNotEmpty
        ? material.package_name.toUpperCase()
        : (material.is_premium == 3
            ? 'PREMIUM'
            : material.is_premium == 2
                ? 'BASIC'
                : 'FREE');

    final Color pkgColor = pkgLabel == 'PREMIUM'
        ? const Color(0xFF6B4EE6)
        : pkgLabel == 'BASIC'
            ? AppColors.tealGreen
            : const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () {
        if (isExpired) {

         Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyCoursePage(
                      contentId: material.materialId.toString(),
                      page_API_call: 'SUBSCRIPTION',
                    ),
                  ),
                );

          return;
        }
        else {
        if (isSubscription) {
          _showCourseBottomSheet(context, material);
        } else {
          if (material.contentType.toUpperCase() != 'VIDEO') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PDFViewerPage(
                      pdfUrl: material.filePath, title: material.title)),
            );
          } else {
            launchUrl(Uri.parse(material.filePath));
          }
        }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(material, hasImage, isSubscription, pkgLabel, pkgColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    material.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (material.description.isNotEmpty)
                    TranslatedText(
                      material.description,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greyS600,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  isSubscription
                      ? _buildStartNowButton(material)
                      : _buildSingleButton(material),
                  const SizedBox(height: 10),
                  TranslatedText(
                    material.access_valid_until.isNotEmpty
                        ? 'Valid Until: ${_formatDate(material.access_valid_until)}'
                        : 'No Expiry',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.greyS500,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── START NOW BUTTON (clean — no pills) ──────────────────────────────────

  Widget _buildStartNowButton(StudyMaterialDetailsItem material) {
  final Map<String, Map<String, dynamic>> featureMeta = {
    'chapter test': {'icon': Icons.menu_book_rounded,            'color': AppColors.tealGreen},
    'subject test': {'icon': Icons.assignment_rounded,           'color': const Color(0xFF3949AB)},
    'live test':    {'icon': Icons.bolt_rounded,                 'color': const Color(0xFF1565C0)},
    'full mock':    {'icon': Icons.quiz_rounded,                 'color': const Color(0xFFE65100)},
    'leaderboard':  {'icon': Icons.leaderboard_rounded,          'color': const Color(0xFF6B4EFF)},
    'pyqs':         {'icon': Icons.history_edu_rounded,          'color': const Color(0xFF00897B)},
    'notes':        {'icon': Icons.sticky_note_2_rounded,        'color': AppColors.darkNavy},
    'daily quiz':   {'icon': Icons.today_rounded,                'color': const Color(0xFF6B4EE6)},
    'job alerts':   {'icon': Icons.notifications_active_rounded, 'color': const Color(0xFFE65100)},
  };

  final List<Widget> pills = material.package_features.map((feature) {
    final String key    = feature.text.toLowerCase().trim();
    final meta          = featureMeta[key];
    final Color base    = meta?['color'] ?? AppColors.tealGreen;
    final Color color   = feature.isIncluded ? base : const Color(0xFF9E9E9E);
    final IconData icon = meta?['icon'] ?? Icons.check_circle_rounded;

    return Opacity(
      opacity: feature.isIncluded ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              feature.text,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
            if (!feature.isIncluded) ...[
              const SizedBox(width: 3),
              Icon(Icons.lock_rounded, size: 8, color: color),
            ],
          ],
        ),
      ),
    );
  }).toList();

  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Wrap(spacing: 6, runSpacing: 6, children: pills),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
         gradient: LinearGradient(
      colors: isExpired
          ? [Colors.red.shade700, Colors.red.shade400]
          : [AppColors.darkNavy, AppColors.tealGreen],
    ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
        color: (isExpired ? Colors.red : AppColors.tealGreen)
            .withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TranslatedText( isExpired ? 'Expired' : 'Start',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
          ],
        ),
      ),
    ],
  );
}

  // ─── BOTTOM SHEET ─────────────────────────────────────────────────────────

  void _showCourseBottomSheet(
      BuildContext context, StudyMaterialDetailsItem material) {

    final Map<String, Map<String, dynamic>> featureMeta = {
      'chapter test': {'icon': Icons.menu_book_rounded,             'color': AppColors.tealGreen},
      'subject test': {'icon': Icons.assignment_rounded,            'color': const Color(0xFF3949AB)},
      'live test':    {'icon': Icons.bolt_rounded,                  'color': const Color(0xFF1565C0)},
      'full mock':    {'icon': Icons.quiz_rounded,                  'color': const Color(0xFFE65100)},
      'leaderboard':  {'icon': Icons.leaderboard_rounded,           'color': const Color(0xFF6B4EFF)},
      'pyqs':         {'icon': Icons.history_edu_rounded,           'color': const Color(0xFF00897B)},
      'notes':        {'icon': Icons.sticky_note_2_rounded,         'color': AppColors.darkNavy},
      'daily quiz':   {'icon': Icons.today_rounded,                 'color': const Color(0xFF6B4EE6)},
      'job alerts':   {'icon': Icons.notifications_active_rounded,  'color': const Color(0xFFE65100)},
    };

    final List<Map<String, dynamic>> actions =
        material.package_features.map((feature) {
      final String key    = feature.text.toLowerCase().trim();
      final meta          = featureMeta[key];
      final Color base    = meta?['color'] ?? AppColors.tealGreen;
      final IconData icon = meta?['icon']  ?? Icons.check_circle_rounded;
      final Color color   = feature.isIncluded ? base : const Color(0xFF9E9E9E);

      VoidCallback onTap;

      if (!feature.isIncluded) {
        // Locked → premium popup
        onTap = () {
          Navigator.pop(context);
          _showPremiumPopup(context, material.subscription_id.toString());
        };
      } else if (key == 'leaderboard') {
        onTap = () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeaderboardPage(
                courseId: material.materialId,
                courseName: material.title,
              ),
            ),
          );
        };
      } else if (key == 'notes') {
        onTap = () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectContentPage(material.materialId.toString()),
            ),
          );
        };
      } else {
        // General: quizes_pageId from API — fully dynamic
        final String pageId = feature.quizes_pageId.toString();
        onTap = () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Paid_QuizListScreen(
                material.materialId.toString(),
                pageId,
                feature.text, // passing feature name as page title
              ),
            ),
          );
        };
      }

      return {
        'icon':     icon,
        'label':    feature.text,    // API se
        'subtitle': feature.isIncluded
            ? feature.label          // API se
            : 'Upgrade to Premium to access',
        'color':    color,
        'locked':   !feature.isIncluded,
        'onTap':    onTap,
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourseBottomSheet(
          material: material,
          actions: actions,
          formatDate: _formatDate),
    );
  }

  // ─── BANNER ───────────────────────────────────────────────────────────────

  Widget _buildBanner(
    StudyMaterialDetailsItem material,
    bool hasImage,
    bool isSubscription,
    String pkgLabel,
    Color pkgColor,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Stack(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: hasImage
                ? Image.network(
                    material.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientBg(material.title),
                  )
                : _gradientBg(material.title),
          ),
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: Icon(
                  isSubscription
                      ? Icons.school_rounded
                      : material.contentType.toUpperCase() == 'PDF'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.play_circle_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: pkgColor, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pkgLabel == 'PREMIUM'
                        ? Icons.workspace_premium
                        : Icons.verified_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pkgLabel,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (material.isPurchased)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 11, color: AppColors.tealGreen),
                    const SizedBox(width: 4),
                    TranslatedText(
                      'PURCHASED',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tealGreen),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── SINGLE BUTTON (PDF / Video) ──────────────────────────────────────────

  Widget _buildSingleButton(StudyMaterialDetailsItem material) {
    return GestureDetector(
      onTap: () {
        if (material.contentType.toUpperCase() != 'VIDEO') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PDFViewerPage(
                    pdfUrl: material.filePath, title: material.title)),
          );
        } else {
          launchUrl(Uri.parse(material.filePath));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.darkNavy, AppColors.tealGreen]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: AppColors.darkNavy.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              material.contentType.toUpperCase() == 'VIDEO'
                  ? Icons.play_circle_rounded
                  : Icons.import_contacts_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            TranslatedText(
              material.contentType.toUpperCase() == 'VIDEO'
                  ? 'Watch Now'
                  : 'Read Now',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PREMIUM POPUP ────────────────────────────────────────────────────────

  void _showPremiumPopup(BuildContext context, String subscriptionId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium_rounded,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const TranslatedText(
                      'Premium Feature',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const TranslatedText(
                      'Unlock the full experience',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _featureChip(Icons.menu_book_rounded, 'Study Material'),
                        _featureChip(Icons.leaderboard_rounded, 'PYQs'),
                        _featureChip(
                            Icons.lock_open_rounded, 'Previous Year Papers'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TranslatedText(
                      'This feature is only available on the Premium Package. Upgrade now to access all features.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PricingPage(CourseIds: subscriptionId)),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded, size: 18),
                            SizedBox(width: 6),
                            TranslatedText('Buy Now',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: TranslatedText(
                        'Maybe Later',
                        style:
                            TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tealGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.tealGreen),
          const SizedBox(width: 5),
          TranslatedText(
            label,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.tealGreen,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── GRADIENT BG ──────────────────────────────────────────────────────────

  Widget _gradientBg(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getColors(title)),
      ),
    );
  }

  List<Color> _getColors(String title) {
    final t = title.toLowerCase();
    if (t.contains('math'))
      return [AppColors.darkNavy, AppColors.tealGreen];
    if (t.contains('science'))
      return [AppColors.tealGreen, const Color(0xFF0D6B55)];
    if (t.contains('physics'))
      return [const Color(0xFF1a237e), AppColors.darkNavy];
    if (t.contains('english'))
      return [AppColors.darkNavy, const Color(0xFF1B5E20)];
    if (t.contains('bihar') || t.contains('board'))
      return [const Color(0xFF1a237e), AppColors.darkNavy];
    if (t.contains('railway'))
      return [const Color(0xFF0D47A1), AppColors.darkNavy];
    return [AppColors.darkNavy, AppColors.tealGreen];
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
 return Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Illustration ──────────────────────────────────
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.tealGreen.withOpacity(0.12),
                AppColors.darkNavy.withOpacity(0.08),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 18, right: 18,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 16, left: 16,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tealGreen.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text('🎓', style: TextStyle(fontSize: 40)),
              ),
            ],
          ),
        ),
 
        const SizedBox(height: 24),
 
        // ── Title ─────────────────────────────────────────
        const TranslatedText(
          'No Courses Yet!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
            fontFamily: 'Poppins',
            height: 1.3,
          ),
        ),
 
        const SizedBox(height: 10),
 
        // ── Subtitle ──────────────────────────────────────
        TranslatedText(
          'Choose the right course, work hard\nand achieve your dream! 🚀',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.greyS600,
            height: 1.6,
          ),
        ),
 
        const SizedBox(height: 20),
 
        // ── Feature chips — Row 1 ─────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _emptyStateChip('📝', 'Mock Tests', const Color(0xFF3949AB)),
            const SizedBox(width: 8),
            _emptyStateChip('📖', 'Study Notes', AppColors.tealGreen),
            const SizedBox(width: 8),
            _emptyStateChip('⚡', 'Live Tests', const Color(0xFFE65100)),
          ],
        ),
 
        const SizedBox(height: 8),
 
        // ── Feature chips — Row 2 ─────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _emptyStateChip('📊', 'Chapter Tests', const Color(0xFF6B4EFF)),
            const SizedBox(width: 8),
            _emptyStateChip('🏆', 'Leaderboard', const Color(0xFFDD8E00)),
            const SizedBox(width: 8),
            _emptyStateChip('📜', 'PYQ Papers', const Color(0xFF00897B)),
          ],
        ),
 
        const SizedBox(height: 28),
 
        // ── CTA Button ────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudyMaterialScreen('1'),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D4B3B).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                TranslatedText(
                 'Browse Courses & Enroll',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
 
        const SizedBox(height: 12),
 
        // ── Social proof ──────────────────────────────────
        TranslatedText(
        'Join now and start learning 🎯',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.greyS500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
);
  }
}

Widget _emptyStateChip(String emoji, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        TranslatedText(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
// ─── BOTTOM SHEET WIDGET ──────────────────────────────────────────────────────

class _CourseBottomSheet extends StatelessWidget {
  final StudyMaterialDetailsItem material;
  final List<Map<String, dynamic>> actions;
  final String Function(String) formatDate;

  static const _navy  = Color(0xFF0A1628);
  static const _green = Color(0xFF1D9E75);

  const _CourseBottomSheet({
    required this.material,
    required this.actions,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 4),

            // ── Gradient Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 10,
                                color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            TranslatedText(
                              material.access_valid_until.isNotEmpty
                                  ? 'Valid till ${formatDate(material.access_valid_until)}'
                                  : 'No Expiry',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (material.isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          TranslatedText(
                            'Active',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Section title ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TranslatedText(
                  'What do you want to do?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            // ── Action List ───────────────────────────────────────────────
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: actions.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1, color: Colors.grey.shade100, indent: 56),
              itemBuilder: (context, index) {
                final action = actions[index];
                final Color color  = action['color'] as Color;
                final bool locked  = action['locked'] as bool;

                return InkWell(
                  onTap: action['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(locked ? 0.05 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            color: locked ? Colors.grey.shade400 : color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: locked
                                      ? Colors.grey.shade400
                                      : _navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TranslatedText(
                                action['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: locked
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        locked
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.lock_rounded,
                                    size: 14, color: Colors.grey.shade400),
                              )
                            : Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: color),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}