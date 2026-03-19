import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tazaquiznew/API/Language_converter/language_selectionPage.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/attempedQuizHistory.dart';
import 'package:tazaquiznew/screens/course_selection.dart';
import 'package:tazaquiznew/screens/help&SupportPage.dart';
import 'package:tazaquiznew/screens/leaderboard_page.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/screens/paymentHistory.dart';
import 'package:tazaquiznew/screens/refer_earn_page.dart';
import 'package:tazaquiznew/screens/splash.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';
import 'package:tazaquiznew/testpage.dart' hide ContactUsPage;
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentProfilePage extends StatefulWidget {
  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  UserModel? _user;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // Header expand height (profile banner ka height)
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
    setState(() {});
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),

      // ── AppBar: collapsed hone par name + joined dikhao ──────
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
                  // Collapsed: name + joined
                  ? Row(
                    key: const ValueKey('collapsed'),
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFF6B35)]),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_user?.username),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
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
                  // Expanded: blank / just title text
                  : const SizedBox.shrink(key: ValueKey('expanded')),
        ),
      ),

      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // ── Profile Header Banner ────────────────────────────
            _buildProfileHeader(),

            // ── Content ──────────────────────────────────────────
            _buildContactCard(),
            _buildQuickActions(),
            _buildSettings(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Profile Header (gradient banner) ──────────────────────────
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
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFF6B35)]),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Text(
                _getInitials(_user?.username),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name + joined + badge
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
                    if (mounted) setState(() {}); // badge update hoga
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
                        Icon(Icons.translate_rounded, size: 12, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 6),
                        TranslatedText(
                          'Language',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          TranslationService.supportedLanguages[TranslationService
                                  .instance
                                  .currentLanguage]?['native'] ??
                              'English',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down_rounded, size: 14, color: Colors.white70),
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

  Widget _buildQuickActions() {
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
          _buildSectionTitle('Quick Actions'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Quiz History ',
                  Icons.history_rounded,
                  const Color(0xFF00695C),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizHistoryPage(pageType: 0))),
                  'Attempts & Leaderboard',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'My Courses',
                  Icons.menu_book_rounded,
                  const Color(0xFFFF9800),
                  () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => StudyMaterialPurchaseHistoryScreen())),
                  'Course & Leaderboard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Mock Test',
                  Icons.quiz_rounded,
                  const Color(0xFF7B1FA2),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizHistoryPage(pageType: 4))),
                  'Attempts & Leaderboard',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'All Payments',
                  Icons.receipt_long_rounded,
                  const Color(0xFF003161),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentHistoryPage())),

                  'View your payment history',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap, String subtitle) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
            Icons.school_rounded,
            'Selected Courses',
            'Manage your enrolled courses',
            const Color(0xFF00695C),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyCoursesSelection(pageId: 0))),
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.workspace_premium_rounded,
            'Plan',
            'View & upgrade your plan',
            const Color(0xFFFF9800),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => PricingPage())),
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.translate_rounded,
            'Select Language',
            'Change the app language',
            const Color(0xFF00695C),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LanguageSelectionPage(showSkip: false, onDone: () => Navigator.pop(context)),
              ),
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.support_agent_rounded,
            'Need Help',
            'Get help with any issues',
            const Color(0xFF00695C),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactUsPage())),
          ),
          _buildDivider(),
          // _buildSettingItem(
          //   Icons.school_rounded,
          //   'Quiz-wise leaderboard',
          //   'Manage your enrolled courses',
          //   const Color(0xFF00695C),
          //   () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => LeaderboardPage(quizId: quiz.quizId, quizTitle: quiz.title)),
          //   ),
          // ),
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
