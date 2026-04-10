import 'dart:ffi';

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
import 'package:tazaquiznew/models/study_material_details_item.dart' hide StudyMaterialDetailsItem;
import 'package:tazaquiznew/screens/PDFViewerPage.dart';
import 'package:tazaquiznew/screens/Paid_quzes_list.dart';
import 'package:tazaquiznew/screens/leaderboard_page.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/screens/quizListDetailsPage.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyMaterialPurchaseHistoryScreen extends StatefulWidget {
  StudyMaterialPurchaseHistoryScreen();

  @override
  _StudyMaterialPurchaseHistoryScreenState createState() => _StudyMaterialPurchaseHistoryScreenState();
}

class _StudyMaterialPurchaseHistoryScreenState extends State<StudyMaterialPurchaseHistoryScreen> {
  bool _isLoading = true;
  List<StudyMaterialDetailsItem> _allStudyMaterials = [];
  UserModel? _user;
  String isPackaged = '';

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
      final responseFuture = await authRepository.fetchStudyMaterialsDetails({'user_id': user_id.toString()});
      if (responseFuture.statusCode == 200) {
        final List list = responseFuture.data['data'] ?? [];
        setState(() {
          _allStudyMaterials = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();
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
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)))
              : _allStudyMaterials.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: () => fetchStudyMaterials(_user?.id ?? ''),
                color: AppColors.tealGreen,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: _allStudyMaterials.length,
                  itemBuilder: (context, index) => _buildCard(_allStudyMaterials[index]),
                ),
              ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'My Courses',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
          ),
          if (!_isLoading)
            TranslatedText(
              '${_allStudyMaterials.length} course${_allStudyMaterials.length != 1 ? 's' : ''} purchased',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
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

    // package_name from API directly
    final String pkgLabel =
        material.package_name.isNotEmpty
            ? material.package_name.toUpperCase()
            : (material.is_premium == 3
                ? 'PREMIUM'
                : material.is_premium == 2
                ? 'BASIC'
                : 'FREE');

    final Color pkgColor =
        pkgLabel == 'PREMIUM'
            ? const Color(0xFF6B4EE6)
            : pkgLabel == 'BASIC'
            ? AppColors.tealGreen
            : const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () {
        if (isSubscription) {
          _showCourseBottomSheet(context, material);
        } else {
          if (material.contentType.toUpperCase() != 'VIDEO') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PDFViewerPage(pdfUrl: material.filePath, title: material.title)),
            );
          } else {
            launchUrl(Uri.parse(material.filePath));
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 5))],
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
                      style: TextStyle(fontSize: 12, color: AppColors.greyS600, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  isSubscription ? _buildStartNowRow(material) : _buildSingleButton(material),
                  const SizedBox(height: 10),
                  TranslatedText(
                    material.access_valid_until.isNotEmpty
                        ? 'Valid Until: ${_formatDate(material.access_valid_until)}'
                        : 'No Expiry',
                    style: TextStyle(fontSize: 10, color: AppColors.greyS500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── START NOW ROW ────────────────────────────────────────────────────────

  Widget _buildStartNowRow(StudyMaterialDetailsItem material) {
    final bool isPremium = material.package_name.toLowerCase() == 'premium';

    final List<Map<String, dynamic>> previewItems = [
      {'icon': Icons.menu_book_rounded, 'label': 'Chapter Test', 'color': AppColors.tealGreen},
      {'icon': Icons.assignment_rounded, 'label': 'Subject Test', 'color': const Color(0xFF3949AB)},
      {'icon': Icons.bolt_rounded, 'label': 'Live Test', 'color': const Color(0xFF1565C0)},
      {'icon': Icons.quiz_rounded, 'label': 'Full Mock', 'color': const Color(0xFFE65100)},
      {
        'icon': Icons.history_edu_rounded,
        'label': 'PYQs',
        'color': isPremium ? AppColors.tealGreen : const Color(0xFF9E9E9E),
        'locked': !isPremium,
      },
      {
        'icon': Icons.sticky_note_2_rounded,
        'label': 'Notes',
        'color': isPremium ? AppColors.darkNavy : const Color(0xFF9E9E9E),
        'locked': !isPremium,
      },
      {'icon': Icons.leaderboard_rounded, 'label': 'Leaderboard', 'color': AppColors.tealGreen},
    ];

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                previewItems.map((item) {
                  final bool locked = item['locked'] == true;
                  return Opacity(
                    opacity: locked ? 0.45 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.09),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (item['color'] as Color).withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item['icon'] as IconData, size: 10, color: item['color'] as Color),
                          const SizedBox(width: 3),
                          Text(
                            item['label'] as String,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: item['color'] as Color),
                          ),
                          if (locked) ...[
                            const SizedBox(width: 3),
                            Icon(Icons.lock_rounded, size: 8, color: item['color'] as Color),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  // ─── BOTTOM SHEET ─────────────────────────────────────────────────────────

  void _showCourseBottomSheet(BuildContext context, StudyMaterialDetailsItem material) {
    final bool isPremium = material.package_name.toLowerCase() == 'premium';

    // ── Action items with quiz_page_id ─────────────────────────────────────
    // quiz_page_id = the type ID passed to Paid_QuizListScreen
    // 0 = Chapter Test, 1 = Live Test, 4 = Subject Test, 5 = Full Mock, 6 = PYQs
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Chapter Test',
        'subtitle': 'Topic & chapter wise tests',
        'color': AppColors.tealGreen,
        'locked': false,
        'quiz_page_id': '0', // ← print debug ID
        'onTap': () {
          Navigator.pop(context);
          debugPrint('quiz_page_id: 0 → Chapter Test | material_id: ${material.materialId}');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Paid_QuizListScreen(material.materialId.toString(), '0')),
          );
        },
      },
      {
        'icon': Icons.assignment_rounded,
        'label': 'Subject Test',
        'subtitle': 'Subject wise mock tests',
        'color': const Color(0xFF3949AB),
        'locked': false,
        'quiz_page_id': '4',
        'onTap': () {
          Navigator.pop(context);
          debugPrint('quiz_page_id: 4 → Subject Test | material_id: ${material.materialId}');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Paid_QuizListScreen(material.materialId.toString(), '4')),
          );
        },
      },
      {
        'icon': Icons.bolt_rounded,
        'label': 'Live Test',
        'subtitle': 'Weekly scheduled live tests',
        'color': const Color(0xFF1565C0),
        'locked': false,
        'quiz_page_id': '1',
        'onTap': () {
          Navigator.pop(context);
          debugPrint('quiz_page_id: 1 → Live Test | material_id: ${material.materialId}');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Paid_QuizListScreen(material.materialId.toString(), '1')),
          );
        },
      },
      {
        'icon': Icons.quiz_rounded,
        'label': 'Full Mock',
        'subtitle': 'Full-length exam simulation',
        'color': const Color(0xFFE65100),
        'locked': false,
        'quiz_page_id': '5',
        'onTap': () {
          Navigator.pop(context);
          debugPrint('quiz_page_id: 5 → Full Mock | material_id: ${material.materialId}');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Paid_QuizListScreen(material.materialId.toString(), '5')),
          );
        },
      },
      {
        'icon': Icons.leaderboard_rounded,
        'label': 'Leaderboard',
        'subtitle': 'See your rank among all students',
        'color': const Color(0xFF6B4EFF),
        'locked': false,
        'quiz_page_id': 'leaderboard',
        'onTap': () {
          Navigator.pop(context);
          debugPrint('quiz_page_id: leaderboard | material_id: ${material.materialId}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeaderboardPage(courseId: material.materialId, courseName: material.title),
            ),
          );
        },
      },
      {
        'icon': Icons.history_edu_rounded,
        'label': 'PYQs',
        'subtitle': isPremium ? 'Upgrade to Premium to access' : 'Previous year questions',
        'color': isPremium ? const Color(0xFF9E9E9E) : const Color(0xFF00897B),
        'locked': !isPremium,
        'quiz_page_id': '6',
        'onTap': () {
          Navigator.pop(context);
          debugPrint('quiz_page_id: 6 → PYQs | material_id: ${material.materialId} | locked: ${!isPremium}');
          if (!isPremium) {
            _showPremiumPopup(context, material.subscription_id.toString());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Paid_QuizListScreen(material.materialId.toString(), '6')),
            );
          }
        },
      },
      {
        'icon': Icons.sticky_note_2_rounded,
        'label': 'Notes',
        'subtitle': isPremium ? 'Upgrade to Premium to access' : 'Study notes & PDFs',
        'color': isPremium ? const Color(0xFF9E9E9E) : AppColors.darkNavy,
        'locked': !isPremium,
        'quiz_page_id': 'notes',
        'onTap': () {
          Navigator.pop(context);
          debugPrint('quiz_page_id: notes | material_id: ${material.materialId} | locked: ${!isPremium}');
          if (!isPremium) {
            _showPremiumPopup(context, material.subscription_id.toString());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SubjectContentPage(material.materialId.toString())),
            );
          }
        },
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourseBottomSheet(material: material, actions: actions, formatDate: _formatDate),
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
            child:
                hasImage
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
                colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.45)],
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
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
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
          // Package badge (top-left)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: pkgColor, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pkgLabel == 'PREMIUM' ? Icons.workspace_premium : Icons.verified_rounded,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 11, color: AppColors.tealGreen),
                    const SizedBox(width: 4),
                    TranslatedText(
                      'PURCHASED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.tealGreen),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── SINGLE BUTTON ────────────────────────────────────────────────────────

  Widget _buildSingleButton(StudyMaterialDetailsItem material) {
    return GestureDetector(
      onTap: () {
        if (material.contentType.toUpperCase() != 'VIDEO') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PDFViewerPage(pdfUrl: material.filePath, title: material.title)),
          );
        } else {
          launchUrl(Uri.parse(material.filePath));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              material.contentType.toUpperCase() == 'VIDEO' ? Icons.play_circle_rounded : Icons.import_contacts_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            TranslatedText(
              material.contentType.toUpperCase() == 'VIDEO' ? 'Watch Now' : 'Read Now',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PREMIUM POPUP ────────────────────────────────────────────────────────

  void _showPremiumPopup(BuildContext context, String SubscriptionId) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const TranslatedText(
                          'Premium Feature',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
                            _featureChip(Icons.leaderboard_rounded, 'PYPs'),
                            _featureChip(Icons.lock_open_rounded, 'Previous Year Papers'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const TranslatedText(
                          'This feature is only available on the Premium Package. Upgrade now to access all features.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tealGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PricingPage(CourseIds: SubscriptionId)),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded, size: 18),
                                SizedBox(width: 6),
                                TranslatedText('Buy Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: TranslatedText(
                            'Maybe Later',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
            style: TextStyle(fontSize: 12, color: AppColors.tealGreen, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── GRADIENT BG ──────────────────────────────────────────────────────────

  Widget _gradientBg(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _getColors(title)),
      ),
    );
  }

  List<Color> _getColors(String title) {
    final t = title.toLowerCase();
    if (t.contains('math')) return [AppColors.darkNavy, AppColors.tealGreen];
    if (t.contains('science')) return [AppColors.tealGreen, const Color(0xFF0D6B55)];
    if (t.contains('physics')) return [const Color(0xFF1a237e), AppColors.darkNavy];
    if (t.contains('english')) return [AppColors.darkNavy, const Color(0xFF1B5E20)];
    if (t.contains('bihar') || t.contains('board')) return [const Color(0xFF1a237e), AppColors.darkNavy];
    if (t.contains('railway')) return [const Color(0xFF0D47A1), AppColors.darkNavy];
    return [AppColors.darkNavy, AppColors.tealGreen];
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.school_outlined, size: 64, color: AppColors.greyS400),
          ),
          const SizedBox(height: 16),
          const TranslatedText(
            'No Courses Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 6),
          TranslatedText(
            'Subscribe to a course to get started',
            style: TextStyle(fontSize: 12, color: AppColors.greyS600),
          ),
        ],
      ),
    );
  }
}

// ─── BOTTOM SHEET WIDGET ──────────────────────────────────────────────────────

class _CourseBottomSheet extends StatelessWidget {
  final StudyMaterialDetailsItem material;
  final List<Map<String, dynamic>> actions;
  final String Function(String) formatDate;

  static const _navy = Color(0xFF0A1628);
  static const _green = Color(0xFF1D9E75);
  static const _borderCol = Color(0xFFE4E9F4);

  const _CourseBottomSheet({required this.material, required this.actions, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final bool isPremium = material.package_name.toLowerCase() == 'premium';
    final Color planColor = isPremium ? const Color(0xFF6B4EE6) : _green;
    final List<PackageFeatureItem> features = material.package_features;

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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
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
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
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
                            Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            TranslatedText(
                              material.access_valid_until.isNotEmpty
                                  ? 'Valid till ${formatDate(material.access_valid_until)}'
                                  : 'No Expiry',
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (material.isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          TranslatedText(
                            'Active',
                            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Plan badge + features section ────────────────────────────
            if (features.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: planColor.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan header row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: planColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isPremium ? Icons.workspace_premium : Icons.verified_rounded,
                                color: planColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${material.package_name} Plan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _navy),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: planColor, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                material.package_name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── 2-column features grid ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        child: _buildFeaturesGrid(features, planColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Section title ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  TranslatedText(
                    'What do you want to do?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // ── Action List ───────────────────────────────────────────────
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: actions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100, indent: 56),
              itemBuilder: (context, index) {
                final action = actions[index];
                final Color color = action['color'] as Color;
                final bool locked = action['locked'] as bool;

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
                                  color: locked ? Colors.grey.shade400 : _navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TranslatedText(
                                action['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: locked ? Colors.grey.shade400 : Colors.grey.shade500,
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
                              child: Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade400),
                            )
                            : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
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

  // ── 2-column features grid ────────────────────────────────────────────────
  Widget _buildFeaturesGrid(List<PackageFeatureItem> features, Color planColor) {
    final List<Widget> rows = [];
    for (int i = 0; i < features.length; i += 2) {
      final left = features[i];
      final right = i + 1 < features.length ? features[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: _featureCell(left, planColor)),
              const SizedBox(width: 8),
              right != null ? Expanded(child: _featureCell(right, planColor)) : const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _featureCell(PackageFeatureItem feature, Color planColor) {
    final bool included = feature.isIncluded;
    final Color cellColor = included ? planColor : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: included ? planColor.withOpacity(0.06) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: included ? planColor.withOpacity(0.2) : Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check/cross icon
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: included ? planColor.withOpacity(0.12) : Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              included ? Icons.check_rounded : Icons.close_rounded,
              size: 11,
              color: included ? planColor : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 7),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.text, // e.g. "Chapter Test"
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: included ? _navy : Colors.grey.shade400,
                    decoration: included ? null : TextDecoration.lineThrough,
                    decorationColor: Colors.grey.shade400,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.label, // e.g. "Topic-wise practice tests"
                  style: TextStyle(
                    fontSize: 10,
                    color: included ? Colors.grey.shade500 : Colors.grey.shade400,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
