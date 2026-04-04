import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazaquiznew/API/Language_converter/language_selectionPage.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/attempedQuizHistory.dart';
import 'package:tazaquiznew/screens/course_selection.dart';
import 'package:tazaquiznew/screens/help&SupportPage.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/screens/paymentHistory.dart';
import 'package:tazaquiznew/screens/refer_earn_page.dart';
import 'package:tazaquiznew/screens/splash.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';
import 'package:tazaquiznew/testpage.dart' hide ContactUsPage;
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class StudentProfilePage extends StatefulWidget {
  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  UserModel? _user;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // Profile image related
  File? _profileImage;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  final double _headerHeight = 150.0;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > _headerHeight - 10;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _getUserData() async {
    _user = await SessionManager.getUser();
    // Agar server se saved profile image URL fetch karni ho:
    // final savedImagePath = await SessionManager.getProfileImagePath();
    // if (savedImagePath != null) setState(() => _profileImage = File(savedImagePath));
    setState(() {});
  }

  // ─── Profile Image Pick & Upload ─────────────────────────────
  Future<void> _pickProfileImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? picked = await _imagePicker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _profileImage = File(picked.path);
      _isUploadingImage = true;
    });

    await _uploadProfileImage(File(picked.path));
  }

  /// Aap yahan apni API call integrate karo.
  /// File ko multipart ya base64 mein bhejo — jo aapka backend accept kare.
  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      // ── APNI API CALL YAHAN LAGAO ──────────────────────────
      String user_ids = _user?.id.toString() ?? '';

      final request = http.MultipartRequest('POST', Uri.parse('https://tazaquiz.com/profile_pic_update.php'));
      request.fields['user_id'] = user_ids;
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      print('Sending file path: ${imageFile.path}');
      print('User ID: $user_ids');
      print('Upload response status: ${response.statusCode}');
      print('Upload response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);

        // existing user lo
        final user = await SessionManager.getUser();

        if (user != null) {
          final Map<String, dynamic> userData = user.toJson();

          // update image
          userData['profile_image'] = json['imageUrl'];

          // dobara save karo
          await SessionManager.saveUser(UserModel.fromJson(userData));
        }

        if (mounted) {
          setState(() {});

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile photo updated!'), backgroundColor: Color(0xFF00695C)));
        }
      }
      // ────────────────────────────────────────────────────────

      // Simulate kiya hai — API lagane ke baad ye line hata do:
      // await Future.delayed(const Duration(seconds: 1));
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Profile photo updated! (API yahan connect karo)'),
      //       backgroundColor: Color(0xFF00695C),
      //     ),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
        setState(() => _profileImage = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Update Profile Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00695C)),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003161).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF003161)),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                if (_profileImage != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Colors.red),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _profileImage = null);
                    },
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  // ─── Logout ──────────────────────────────────────────────────
  Future<void> handleLogout(BuildContext context) async {
    final googleSignIn = GoogleSignIn();
    await SessionManager.logout();
    await googleSignIn.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => SplashScreen()), (route) => false);
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String formatMemberSince(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(date);
      return '${_monthName(dt.month)} ${dt.year}';
    } catch (_) {
      return date;
    }
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  // ─── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: _isCollapsed ? 4 : 0,
        toolbarHeight: _isCollapsed ? kToolbarHeight : 0,
        backgroundColor: const Color(0xFF003161),
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child:
              _isCollapsed
                  ? Row(
                    key: const ValueKey('collapsed'),
                    children: [
                      _buildAvatarWidget(size: 36, fontSize: 14, borderWidth: 2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _user?.username ?? 'Student',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Joined • ${formatMemberSince(_user?.createdAt)}',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                  : const SizedBox.shrink(key: ValueKey('expanded')),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildContactCard(),
            _buildQuickActions(),
            _buildQuickperformance(),
            _buildSettings(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Avatar widget (reusable) ─────────────────────────────────
  Widget _buildAvatarWidget({
    required double size,
    required double fontSize,
    double borderWidth = 3,
    bool showEditOverlay = false,
  }) {
    return GestureDetector(
      onTap: showEditOverlay ? _pickProfileImage : null,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  (_profileImage == null && (_user?.profileImage == null || _user!.profileImage!.isEmpty))
                      ? const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFF6B35)])
                      : null,
              color:
                  (_profileImage != null || (_user?.profileImage != null && _user!.profileImage!.isNotEmpty))
                      ? Colors.grey.shade200
                      : null,
              border: Border.all(color: Colors.white, width: borderWidth),
              boxShadow:
                  showEditOverlay
                      ? [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
            ),
            child: ClipOval(
              child:
                  _isUploadingImage
                      /// 🔄 LOADING
                      ? Center(
                        child: SizedBox(
                          width: size * 0.4,
                          height: size * 0.4,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      )
                      /// 📷 LOCAL IMAGE (just picked)
                      : _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover, width: size, height: size)
                      /// 🌐 NETWORK IMAGE (session / DB)
                      : (_user?.profileImage != null && _user!.profileImage!.isNotEmpty)
                      ? Image.network(
                        "https://tazaquiz.com/uploads/profile/${_user!.profileImage}?t=${DateTime.now().millisecondsSinceEpoch}",
                        fit: BoxFit.cover,
                        width: size,
                        height: size,

                        /// ❌ ERROR fallback
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _getInitials(_user?.username),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: fontSize),
                            ),
                          );
                        },
                      )
                      /// 👤 DEFAULT INITIALS
                      : Center(
                        child: Text(
                          _getInitials(_user?.username),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: fontSize),
                        ),
                      ),
            ),
          ),

          /// 📸 CAMERA ICON
          if (showEditOverlay && !_isUploadingImage)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.33,
                height: size * 0.33,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(Icons.camera_alt_rounded, size: size * 0.18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Profile Header ───────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003161), Color(0xFF00695C)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with edit overlay
          _buildAvatarWidget(size: 72, fontSize: 26, borderWidth: 3, showEditOverlay: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _user?.username ?? 'Student',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 11, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Joined • ${formatMemberSince(_user?.createdAt)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LanguageSelectionPage(showSkip: false, onDone: () => Navigator.pop(context)),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate_rounded, size: 12, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 6),
                        TranslatedText(
                          'Language',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          TranslationService.supportedLanguages[TranslationService
                                  .instance
                                  .currentLanguage]?['native'] ??
                              'English',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 14, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Contact Card ─────────────────────────────────────────────
  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildContactItem(
              Icons.email_outlined,
              'Email',
              _user?.email ?? 'Not provided',
              const Color(0xFF2196F3),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _buildContactItem(
              Icons.phone_outlined,
              'Phone',
              _user?.phone ?? 'Not provided',
              const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: const TextStyle(fontSize: 12, color: Color(0xFF003161), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Quick Actions (horizontal scroll) ───────────────────────
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 10), child: _buildSectionTitle('Quick Actions')),
          _buildActionListItem(
            icon: Icons.menu_book_rounded,
            title: 'My Courses',
            subtitle: 'Course & study material',
            color: const Color(0xFFFF9800),
            onTap:
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudyMaterialPurchaseHistoryScreen())),
          ),

          _buildActionListItem(
            icon: Icons.workspace_premium_rounded,
            title: 'Buy Courses / Upgrade Plan',
            subtitle: 'View & upgrade your plan',
            color: const Color(0xFFFF9800),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PricingPage())),
            isFirst: true,
          ),
          _buildActionListItem(
            icon: Icons.school_rounded,
            title: 'Selected Courses',
            subtitle: 'Manage your enrolled courses',
            color: const Color(0xFF00695C),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyCoursesSelection(pageId: 0))),
          ),
          _buildActionListItem(
            icon: Icons.receipt_long_rounded,
            title: 'All Payments',
            subtitle: 'View payment history',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentHistoryPage())),
          ),
          _buildActionListItem(
            icon: Icons.translate_rounded,
            title: 'Select Language',
            subtitle: 'Change the app language',
            color: const Color(0xFF00695C),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LanguageSelectionPage(showSkip: false, onDone: () => Navigator.pop(context)),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickperformance() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: _buildSectionTitle('My Results / Performance'),
          ),

          _buildActionListItem(
            icon: Icons.history_rounded,
            title: 'Test Performance',
            subtitle: 'Attempts & leaderboard',
            color: const Color(0xFF00695C),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizHistoryPage(pageType: 0, Pagetitle: 'Test Performance')),
                ),
            isFirst: true,
          ),

          _buildActionListItem(
            icon: Icons.quiz_rounded,
            title: 'Mock Test Performance',
            subtitle: 'Attempts & leaderboard',
            color: const Color(0xFF7B1FA2),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizHistoryPage(pageType: 4, Pagetitle: 'Mock Test Performance')),
                ),
          ),
          _buildActionListItem(
            icon: Icons.assignment_turned_in_rounded,
            title: 'PYPs Performance',
            subtitle: 'Previous Year Papers attempts',
            color: const Color(0xFF00838F),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizHistoryPage(pageType: 6, Pagetitle: 'PYPs Performance')),
                ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        if (isFirst) Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100, indent: 0, endIndent: 0),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.only(
            bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                // Arrow
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: action.color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: action.color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              action.title,
              style: TextStyle(fontSize: 11, color: action.color, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              action.subtitle,
              style: TextStyle(fontSize: 9, color: action.color.withOpacity(0.8), fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Settings ─────────────────────────────────────────────────
  Widget _buildSettings() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Settings'),
          const SizedBox(height: 12),

          _buildSettingItem(
            Icons.support_agent_rounded,
            'Need Help',
            'Get help with any issues',
            const Color(0xFF00695C),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactUsPage())),
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.card_giftcard_rounded,
            'Refer and Earn',
            'Invite friends & get rewards',
            const Color(0xFF2196F3),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReferEarnPage())),
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.policy_rounded,
            'Privacy Policy',
            'Read our privacy policy',
            const Color(0xFF607D8B),
            () =>
                launchUrl(Uri.parse('https://tazaquiz.com/privacy_policy.html'), mode: LaunchMode.externalApplication),
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.assignment_return_rounded,
            'Refund Policy',
            'Read our refund policy',
            const Color(0xFF607D8B),
            () => launchUrl(Uri.parse('https://tazaquiz.com/refund_policy.html'), mode: LaunchMode.externalApplication),
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.logout_rounded,
            'Logout',
            'Sign out of your account',
            const Color(0xFFE53935),
            () => _showLogoutDialog(context),
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: const Color(0xFF00695C), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, color: Color(0xFF003161), fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildDivider() =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Divider(height: 1, color: Colors.grey.shade100));

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLogout ? const Color(0xFFE53935) : const Color(0xFF003161),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ─── Logout Dialog ────────────────────────────────────────────
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.logout_rounded, size: 40, color: Color(0xFFE53935)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Logout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF003161)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to logout from your account?',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirmed == true) handleLogout(context);
  }
}

// ─── Helper model for Quick Actions ──────────────────────────────
class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
