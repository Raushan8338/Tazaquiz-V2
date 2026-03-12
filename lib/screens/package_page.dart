import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class _PlanFeature {
  final String label;
  final bool included;
  const _PlanFeature(this.label, {required this.included});
}

class _Course {
  final String id;
  final String emoji;
  final String name;
  final String sub;
  const _Course(this.id, this.emoji, this.name, this.sub);
}

// ─── Constants ────────────────────────────────────────────────────────────────

const _courses = [
  _Course('ssc', '📋', 'SSC', 'CGL · CHSL · MTS'),
  _Course('banking', '🏦', 'Banking', 'IBPS · SBI · RBI'),
  _Course('upsc', '🏛️', 'UPSC', 'IAS · IPS · IFS'),
  _Course('railway', '🚆', 'Railway', 'RRB · NTPC · GroupD'),
  _Course('police', '👮', 'Police', 'SI · Constable · ASI'),
  _Course('teaching', '📚', 'Teaching', 'CTET · TET · DSSSB'),
];

// ─── Pricing Page ─────────────────────────────────────────────────────────────

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage>
    with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  String? _activatedCourse;
  bool _premiumActivated = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmerAnim =
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
              child: Column(
                children: [
                  _buildFreeCard(),
                  const SizedBox(height: 12),
                  _buildBasicCard(),
                  const SizedBox(height: 12),
                  _buildPremiumCard(),
                  const SizedBox(height: 20),
                  _buildInfoNote(),
                  const SizedBox(height: 16),
                  _buildTrustBar(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0C3756), AppColors.darkNavy],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: AppColors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plans & Pricing',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                'Apne budget mein best plan chuniye',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.white.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Stats row
                      Row(
                        children: [
                          _statChip('50K+', 'Students'),
                          const SizedBox(width: 10),
                          _statChip('6', 'Courses'),
                          const SizedBox(width: 10),
                          _statChip('4.8 ★', 'Rating'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String num, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            num,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FREE CARD ──────────────────────────────────────────────────────────────

  Widget _buildFreeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyS200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.greyS1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('🎁', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      'Hamesha ke liye free',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.greyS500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '₹0',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _divider(),
            const SizedBox(height: 14),
            _featureRow('2 Mock Tests / month', included: true),
            _featureRow('Daily Quiz (unlimited)', included: true),
            _featureRow('2 Live Quiz / month', included: true),
            _featureRow('Basic Score Card', included: true),
            _featureRow('All Courses Access', included: false),
            _featureRow('Leaderboard & Certificates', included: false),
            const SizedBox(height: 16),
            // CTA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.greyS300),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Abhi Use Karo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greyS600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BASIC CARD ─────────────────────────────────────────────────────────────

  Widget _buildBasicCard() {
    final isActivated = _activatedCourse != null;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.tealGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealGreen.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge + Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('🚀', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'One-time · Lifetime access',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Most Popular badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⭐ Most Popular',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price with shimmer
                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppColors.white,
                          AppColors.white
                              .withOpacity(0.5 + _shimmerAnim.value * 0.5),
                          AppColors.white,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: child,
                    );
                  },
                  child: Text(
                    '₹29',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: AppColors.white.withOpacity(0.15)),
                const SizedBox(height: 12),

                _featureRowDark('1 Course Activate (lifetime)', included: true),
                _featureRowDark('Unlimited Mock Tests', included: true),
                _featureRowDark('Unlimited Live Quiz', included: true),
                _featureRowDark('Complete Study Material', included: true),
                _featureRowDark('Detailed Analytics', included: true),
                _featureRowDark('Leaderboard & Certificates', included: false),

                const SizedBox(height: 18),

                // CTA
                if (isActivated) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.lightGold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_courses.firstWhere((c) => c.id == _activatedCourse).emoji} ${_courses.firstWhere((c) => c.id == _activatedCourse).name} Activated!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () => _showCourseBottomSheet(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🛒', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Abhi Kharido — ₹29',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PREMIUM CARD ───────────────────────────────────────────────────────────

  Widget _buildPremiumCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightGold.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.lightGold.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.lightGold.withOpacity(0.25)),
                      ),
                      child:
                          const Text('👑', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'Sab kuch unlock karo',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.white.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Best Value badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.lightGold.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '👑 Best Value',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightGold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹99',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: AppColors.lightGold,
                        letterSpacing: -1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 6),
                      child: Text(
                        '/ month',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: AppColors.white.withOpacity(0.1)),
                const SizedBox(height: 12),

                _featureRowDark('Sab Courses (SSC, Banking, UPSC...)', included: true, accent: AppColors.lightGold),
                _featureRowDark('Unlimited Mock Tests + Live Quiz', included: true, accent: AppColors.lightGold),
                _featureRowDark('Complete Study Material', included: true, accent: AppColors.lightGold),
                _featureRowDark('Leaderboard + AIR Rank', included: true, accent: AppColors.lightGold),
                _featureRowDark('Certificates Download', included: true, accent: AppColors.lightGold),
                _featureRowDark('Offline Mode', included: true, accent: AppColors.lightGold),
                _featureRowDark('Priority Support', included: true, accent: AppColors.lightGold),

                const SizedBox(height: 18),

                // CTA
                if (_premiumActivated) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.lightGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.lightGold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium,
                            color: AppColors.lightGold, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Premium Active! 🎉',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () => _showPremiumBottomSheet(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.lightGold,
                            AppColors.lightGoldS2,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightGold.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👑', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Premium Shuru Karo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO NOTE ──────────────────────────────────────────────────────────────

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tealGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.tealGreen.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Plan kaise kaam karta hai?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹29 pay karo → Ek course select karo (SSC/Banking/etc.) → Woh course lifetime ke liye unlock! Us course ke sab mock tests, live quizzes aur study material milega.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.greyS600,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TRUST BAR ──────────────────────────────────────────────────────────────

  Widget _buildTrustBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _trustItem('🔐', 'Secure', 'Payment'),
          _vDivider(),
          _trustItem('↩️', 'Easy', 'Refund'),
          _vDivider(),
          _trustItem('⚡', 'Instant', 'Access'),
        ],
      ),
    );
  }

  Widget _trustItem(String icon, String title, String sub) {
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: 22)),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        Text(
          sub,
          style: TextStyle(fontSize: 10, color: AppColors.greyS500),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.greyS200,
    );
  }

  // ─── SHARED FEATURE ROWS ────────────────────────────────────────────────────

  Widget _featureRow(String label, {required bool included}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: included
                  ? AppColors.tealGreen.withOpacity(0.1)
                  : AppColors.greyS200,
            ),
            child: Center(
              child: Text(
                included ? '✓' : '✕',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color:
                      included ? AppColors.tealGreen : AppColors.greyS400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: included ? AppColors.greyS700 : AppColors.greyS400,
              decoration:
                  included ? TextDecoration.none : TextDecoration.lineThrough,
              fontWeight: included ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRowDark(String label,
      {required bool included, Color? accent}) {
    final tickColor = accent ?? AppColors.tealGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: included
                  ? tickColor.withOpacity(0.18)
                  : AppColors.white.withOpacity(0.07),
            ),
            child: Center(
              child: Text(
                included ? '✓' : '✕',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: included
                      ? tickColor
                      : AppColors.white.withOpacity(0.25),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: included
                    ? AppColors.white.withOpacity(0.9)
                    : AppColors.white.withOpacity(0.28),
                decoration: included
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
                fontWeight:
                    included ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: AppColors.greyS200);
  }

  // ─── BASIC BOTTOM SHEET ─────────────────────────────────────────────────────

  void _showCourseBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourseSelectionSheet(
        onActivate: (courseId) {
          setState(() => _activatedCourse = courseId);
          Navigator.pop(context);
          _showSuccessSnackBar(
            '${_courses.firstWhere((c) => c.id == courseId).emoji} ${_courses.firstWhere((c) => c.id == courseId).name} successfully activate ho gaya! 🎉',
          );
        },
      ),
    );
  }

  // ─── PREMIUM BOTTOM SHEET ───────────────────────────────────────────────────

  void _showPremiumBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumSheet(
        onActivate: () {
          setState(() => _premiumActivated = true);
          Navigator.pop(context);
          _showSuccessSnackBar(
              '👑 Premium active! Sab courses unlock ho gaye 🎉');
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.white),
        ),
        backgroundColor: AppColors.tealGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── COURSE SELECTION BOTTOM SHEET ───────────────────────────────────────────

class _CourseSelectionSheet extends StatefulWidget {
  final void Function(String courseId) onActivate;
  const _CourseSelectionSheet({required this.onActivate});

  @override
  State<_CourseSelectionSheet> createState() =>
      _CourseSelectionSheetState();
}

class _CourseSelectionSheetState extends State<_CourseSelectionSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyS300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Chuniye 📋',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      Text(
                        '1 course lifetime ke liye activate hoga',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.greyS500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.greyS1,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.close,
                        size: 18, color: AppColors.greyS600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: AppColors.greyS200),
          // Course Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: _courses
                  .map((c) => _CourseCard(
                        course: c,
                        isSelected: _selected == c.id,
                        onTap: () => setState(() => _selected = c.id),
                      ))
                  .toList(),
            ),
          ),
          // Activate button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _selected != null
                      ? () => widget.onActivate(_selected!)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _selected != null
                          ? const LinearGradient(
                              colors: [
                                AppColors.darkNavy,
                                AppColors.tealGreen
                              ],
                            )
                          : null,
                      color: _selected != null ? null : AppColors.greyS200,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selected != null
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.tealGreen.withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _selected != null
                            ? '✅ ${_courses.firstWhere((c) => c.id == _selected).name} Activate Karo'
                            : 'Pehle Course Chuniye',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _selected != null
                              ? AppColors.white
                              : AppColors.greyS500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '⚠️  Ek baar select karne ke baad change nahi hoga',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.greyS400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Course Card ─────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final _Course course;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.darkNavy, AppColors.tealGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.greyS1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.tealGreen
                : AppColors.greyS200,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.tealGreen.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(course.emoji,
                  style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      course.sub,
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected
                            ? AppColors.white.withOpacity(0.7)
                            : AppColors.greyS500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.lightGold, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PREMIUM BOTTOM SHEET ─────────────────────────────────────────────────────

class _PremiumSheet extends StatelessWidget {
  final VoidCallback onActivate;
  const _PremiumSheet({required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyS300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Gold header strip
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.lightGold.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('👑', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  'Premium Plan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '₹99',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.lightGold,
                        ),
                      ),
                      TextSpan(
                        text: ' / month',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Features list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                '✅  Sab 6 Courses — SSC, Banking, UPSC, Railway, Police, Teaching',
                '✅  Unlimited Mock Tests + Live Quizzes',
                '✅  Leaderboard mein rank karo',
                '✅  Certificates download karo',
                '✅  Offline mode — bina internet ke padho',
                '✅  Priority customer support',
              ]
                  .map(
                    (f) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.greyS1,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyS200),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.greyS700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onActivate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.lightGold,
                          AppColors.lightGoldS2
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightGold.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('👑', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text(
                          'Premium Activate Karo — ₹99/mo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Baad mein sochenge',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.greyS500,
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
}