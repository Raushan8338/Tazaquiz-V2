import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/study_material_details_item.dart';
import 'package:tazaquiznew/screens/PDFViewerPage.dart';
import 'package:tazaquiznew/screens/Paid_quzes_list.dart';
import 'package:tazaquiznew/screens/leaderboard_page.dart';
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

  @override
  void initState() {
    super.initState();
    _getUserData();
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
          const Text(
            'My Courses',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
          ),
          if (!_isLoading)
            Text(
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──────────────────────────────────────
          _buildBanner(material, hasImage, isSubscription),

          // ── Content ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
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
                const SizedBox(height: 8),

                // Description
                if (material.description.isNotEmpty)
                  Text(
                    material.description,
                    style: TextStyle(fontSize: 12, color: AppColors.greyS600, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // ── Action buttons ──
                isSubscription ? _buildSubscriptionButtons(material) : _buildSingleButton(material),

                const SizedBox(height: 10),

                // Date
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 11, color: AppColors.greyS500),
                    const SizedBox(width: 4),
                    Text(
                      'Added: ${material.createdAt}',
                      style: TextStyle(fontSize: 10, color: AppColors.greyS500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BANNER ───────────────────────────────────────────────────────────────

  Widget _buildBanner(StudyMaterialDetailsItem material, bool hasImage, bool isSubscription) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Stack(
        children: [
          // Background
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

          // Overlay
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

          // Center icon
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

          // Top left — content type badge
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSubscription ? AppColors.tealGreen : AppColors.darkNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSubscription ? Icons.workspace_premium : Icons.badge_outlined, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    isSubscription ? 'SUBSCRIPTION' : material.contentType.toUpperCase(),
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

          // Top right — Purchased badge
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
                    Text(
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

  // ─── SUBSCRIPTION BUTTONS ─────────────────────────────────────────────────

  Widget _buildSubscriptionButtons(StudyMaterialDetailsItem material) {
    return Column(
      children: [
        // Row 1 — Quiz + Mock Test
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon: Icons.bolt_rounded,
                label: 'Live Quiz',
                color: AppColors.tealGreen,
                //Paid_QuizListScreen(material.materialId.toString())
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => Paid_QuizListScreen(
                              material.materialId.toString(),
                              '0', // pageType 0 = quiz
                            ),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(
                icon: Icons.assignment_rounded,
                label: 'Mock Test',
                color: const Color(0xFF3949AB),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => Paid_QuizListScreen(
                              material.materialId.toString(),
                              '4', // pageType 0 = quiz
                            ),
                      ),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2 — Study Material + Leaderboard
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon: Icons.menu_book_rounded,
                label: 'Study Material',
                color: AppColors.darkNavy,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SubjectContentPage(material.materialId.toString())),
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(
                icon: Icons.leaderboard_rounded,
                label: 'Leaderboard',
                color: const Color(0xFF6B4EFF),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeaderboardPage(courseId: material.materialId, courseName: material.title),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── SINGLE BUTTON (PDF/Video) ────────────────────────────────────────────

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
            Text(
              material.contentType.toUpperCase() == 'VIDEO' ? 'Watch Now' : 'Read Now',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTION BUTTON ────────────────────────────────────────────────────────

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── GRADIENT BG ──────────────────────────────────────────────────────────

  Widget _gradientBg(String title) {
    final colors = _getColors(title);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
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
          const Text(
            'No Courses Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 6),
          Text('Subscribe to a course to get started', style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
        ],
      ),
    );
  }
}
