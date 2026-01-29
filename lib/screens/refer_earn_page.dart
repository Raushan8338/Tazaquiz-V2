import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiz/constants/app_colors.dart';
import 'package:tazaquiz/screens/referal_list.dart';
import 'package:tazaquiz/utils/richText.dart';
import 'package:tazaquiz/widgets/custom_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tazaquiz/utils/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferEarnPage extends StatefulWidget {
  const ReferEarnPage({super.key});

  @override
  State<ReferEarnPage> createState() => _ReferEarnPageState();
}

class _ReferEarnPageState extends State<ReferEarnPage> {
  String userId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    final user = await SessionManager.getUser();
    setState(() {
      userId = user?.id.toString() ?? "";
      isLoading = false;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: userId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.white, size: 20),
            SizedBox(width: 10),
            Text('Code copied!', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.tealGreen,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareReferral(String platform) async {
    final url = "https://www.tazaquiz.com/app_opn_url.php?referrel=$userId";
    final String message = "Join TazaQuiz! Use my code $userId and get rewards. Download: $url";

    try {
      if (platform == 'whatsapp') {
        final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
        if (await canLaunch(whatsappUrl)) {
          await launch(whatsappUrl);
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
    // TODO: Navigate to referral list page
    //  Navigator.push(context, MaterialPageRoute(builder: (context) => ReferralListPage()));
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(SnackBar(content: Text('Referral List - Coming Soon!'), duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.tealGreen, strokeWidth: 3))
                    : SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        children: [_buildCodeSection(), _buildShareSection(), _buildHowItWorks(), SizedBox(height: 30)],
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.tealGreen],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar (Fixed - Not Scrollable)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  AppButton.setBackIcon(context, () {
                    Navigator.pop(context);
                  }, AppColors.white),
                  SizedBox(width: 12),
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: AppColors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Check Referral List',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Gift Icon
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: Icon(Icons.card_giftcard, size: 60, color: AppColors.tealGreen),
            ),
            SizedBox(height: 20),
            // Title
            AppRichText.setTextPoppinsStyle(
              context,
              'Refer & Earn Up to ₹50',
              22,
              AppColors.white,
              FontWeight.w900,
              1,
              TextAlign.center,
              0.0,
            ),
            SizedBox(height: 8),
            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: AppRichText.setTextPoppinsStyle(
                context,
                'Share your code with friends and earn\nwhen they buy courses or join quizzes!',
                13,
                AppColors.white.withOpacity(0.95),
                FontWeight.w500,
                3,
                TextAlign.center,
                1.5,
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection() {
    return Transform.translate(
      offset: Offset(0, -20),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, 5))],
        ),
        child: Column(
          children: [
            AppRichText.setTextPoppinsStyle(
              context,
              'Your Referral Code',
              13,
              AppColors.greyS700,
              FontWeight.w600,
              1,
              TextAlign.center,
              0.0,
            ),
            SizedBox(height: 16),
            // Code Display - Larger Size
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.tealGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tealGreen.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  userId,
                  36,
                  AppColors.tealGreen,
                  FontWeight.w900,
                  1,
                  TextAlign.center,
                  2.5,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Copy Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _copyToClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy, color: AppColors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Copy Code',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
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

  Widget _buildShareSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Share via',
            15,
            AppColors.darkNavy,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShareCard('WhatsApp', Icons.whatshot, Color(0xFF25D366), () => _shareReferral('whatsapp')),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildShareCard('More', Icons.share, AppColors.oxfordBlue, () => _shareReferral('other')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'How It Works',
            15,
            AppColors.darkNavy,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 20),
          _buildStepItem('1', 'Share your code', 'Send your referral code to friends', AppColors.tealGreen),
          _buildStepItem('2', 'Friend signs up', 'They register using your code', AppColors.darkNavy),
          _buildStepItem(
            '3',
            'They buy courses or join quizzes',
            'Earn when friends participate',
            AppColors.oxfordBlue,
          ),
          _buildStepItem('4', 'Both get rewards', 'You earn up to ₹50, they get bonus!', AppColors.tealGreen),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyS700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
