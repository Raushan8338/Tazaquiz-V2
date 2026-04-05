import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/referal_list.dart' show ReferralListPage;
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferEarnPage extends StatefulWidget {
  const ReferEarnPage({super.key});

  @override
  State<ReferEarnPage> createState() => _ReferEarnPageState();
}

class _ReferEarnPageState extends State<ReferEarnPage> with SingleTickerProviderStateMixin {
  String userId = "";
  bool isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    getData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  getData() async {
    final user = await SessionManager.getUser();
    setState(() {
      userId = user?.id.toString() ?? "";
      isLoading = false;
    });
    _animController.forward();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: userId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            const TranslatedText(
              'Code copied!',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.tealGreen,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareReferral(String platform) async {
    final url = "https://www.tazaquiz.com/app_opn_url.php?referrel=$userId";
    final String message = "Join TazaQuiz! Use my code $userId and get rewards. Download: $url";

    try {
      if (platform == 'whatsapp') {
        final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(Uri.parse(whatsappUrl));
        } else {
          await Share.share(message);
        }
      } else if (platform == 'telegram') {
        final telegramUrl = "tg://msg?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(telegramUrl))) {
          await launchUrl(Uri.parse(telegramUrl));
        } else {
          await Share.share(message);
        }
      } else if (platform == 'instagram') {
        // Instagram doesn't support direct text share, open app
        const instagramUrl = "instagram://app";
        if (await canLaunchUrl(Uri.parse(instagramUrl))) {
          await launchUrl(Uri.parse(instagramUrl));
        } else {
          await Share.share(message);
        }
      } else if (platform == 'facebook') {
        final fbUrl = "https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}";
        if (await canLaunchUrl(Uri.parse(fbUrl))) {
          await launchUrl(Uri.parse(fbUrl), mode: LaunchMode.externalApplication);
        } else {
          await Share.share(message);
        }
      } else {
        await Share.share(message);
      }
    } catch (e) {
      await Share.share(message);
    }
  }

  void _navigateToReferralList() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ReferralListPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.tealGreen, strokeWidth: 3))
                    : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildCodeSection(),
                              const SizedBox(height: 4),
                              _buildShareSection(),
                              const SizedBox(height: 20),
                              _buildHowItWorks(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.tealGreen],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  AppButton.setBackIcon(context, () {
                    Navigator.pop(context);
                  }, AppColors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      'Refer & Earn',
                      16,
                      AppColors.white,
                      FontWeight.w900,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ),
                  TextButton(
                    onPressed: _navigateToReferralList,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: AppColors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const TranslatedText(
                      'Check Referral List',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gift icon — smaller, elegant
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.card_giftcard_rounded, size: 44, color: AppColors.white),
            ),
            const SizedBox(height: 14),

            AppRichText.setTextPoppinsStyle(
              context,
              'Refer & Earn Up to ₹50',
              20,
              AppColors.white,
              FontWeight.w900,
              1,
              TextAlign.center,
              0.0,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AppRichText.setTextPoppinsStyle(
                context,
                'Share your code & earn when friends\nbuy courses or join quizzes!',
                12,
                AppColors.white.withOpacity(0.9),
                FontWeight.w500,
                3,
                TextAlign.center,
                1.4,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection() {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            // Label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tag_rounded, size: 14, color: AppColors.greyS700),
                const SizedBox(width: 4),
                TranslatedText(
                  'Your Referral Code',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyS700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ✅ Stylish Code Pill — not a big box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.tealGreen.withOpacity(0.12), AppColors.darkNavy.withOpacity(0.06)],
                ),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.tealGreen.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decorative dots
                  _dotSep(),
                  const SizedBox(width: 12),
                  TranslatedText(
                    userId,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.tealGreen,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _dotSep(),
                ],
              ),
            ),

            const SizedBox(height: 6),
            TranslatedText(
              'Tap to copy and share with friends',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.greyS700.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),

            // Copy Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _copyToClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.copy_rounded, color: AppColors.white, size: 18),
                    SizedBox(width: 8),
                    TranslatedText(
                      'Copy Code',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small decorative element inside pill
  Widget _dotSep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.4), shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'Share via',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildShareCard(
                label: 'WhatsApp',
                icon: Icons.whatshot_rounded,
                color: const Color(0xFF25D366),
                onTap: () => _shareReferral('whatsapp'),
              ),
              const SizedBox(width: 10),
              _buildShareCard(
                label: 'Telegram',
                icon: Icons.send_rounded,
                color: const Color(0xFF229ED9),
                onTap: () => _shareReferral('telegram'),
              ),
              const SizedBox(width: 10),
              _buildShareCard(
                label: 'Instagram',
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFFE1306C),
                onTap: () => _shareReferral('instagram'),
              ),
              const SizedBox(width: 10),
              _buildShareCard(
                label: 'More',
                icon: Icons.share_rounded,
                color: AppColors.oxfordBlue,
                onTap: () => _shareReferral('other'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.22), width: 1.2),
            ),
            child: Column(
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(height: 6),
                TranslatedText(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.tealGreen),
                SizedBox(width: 8),
                TranslatedText(
                  'How It Works',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildStepItem('1', 'Share your code', 'Send your referral code to friends', AppColors.tealGreen),
            _buildStepItem('2', 'Friend signs up', 'They register using your code', AppColors.darkNavy),
            _buildStepItem(
              '3',
              'They buy courses or join quizzes',
              'Earn when friends participate',
              const Color(0xFF5B6EAD),
            ),
            _buildStepItem(
              '4',
              'Both get rewards',
              'You earn up to ₹50, they get bonus!',
              AppColors.tealGreen,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle, Color color, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: TranslatedText(
                  number,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.25), borderRadius: BorderRadius.circular(4)),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                TranslatedText(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyS700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
