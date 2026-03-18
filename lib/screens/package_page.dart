import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/selected_courses_item.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class _PlanFeature {
  final String text;
  final bool isIncluded;
  const _PlanFeature({required this.text, required this.isIncluded});

  factory _PlanFeature.fromJson(Map<String, dynamic> json) {
    return _PlanFeature(text: json['text'] ?? '', isIncluded: json['is_included'] ?? false);
  }
}

class _Package {
  final int id;
  final String name;
  final String slug;
  final double price;
  final String billingType;
  final int validityDays;
  final List<_PlanFeature> features;

  const _Package({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.billingType,
    required this.validityDays,
    required this.features,
  });

  factory _Package.fromJson(Map<String, dynamic> json) {
    return _Package(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      billingType: json['billing_type'] ?? '',
      validityDays: int.tryParse(json['validity_days'].toString()) ?? 0,
      features:
          (json['features'] as List<dynamic>? ?? [])
              .map((f) => _PlanFeature.fromJson(f as Map<String, dynamic>))
              .toList(),
    );
  }

  bool get isFree => slug == 'free';
  bool get isBasic => slug == 'basic';
  bool get isPremium => slug == 'premium';

  String get priceDisplay => price == 0 ? '₹0' : '₹${price.toInt()}';

  String get billingLabel {
    switch (billingType) {
      case 'free':
        return 'Free forever';
      case 'quarterly':
        return 'One-time · $validityDays days';
      case 'monthly':
        return 'Per month · $validityDays days';
      default:
        return '$validityDays days validity';
    }
  }
}

// ─── Pricing Page ─────────────────────────────────────────────────────────────

class PricingPage extends StatefulWidget {
  final String? activePackageSlug;

  const PricingPage({super.key, this.activePackageSlug});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  UserModel? _user;

  List<_Package> _packages = [];
  bool _isLoading = true;
  String? _error;

  String? _activePlanSlug;
  String? _activatedCourse;

  List<SelectedCourseItem> _userSelectedCourses = [];

  @override
  void initState() {
    super.initState();
    _activePlanSlug = widget.activePackageSlug;

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);

    _init();
  }

  Future<void> _init() async {
    _user = await SessionManager.getUser();
    await Future.wait([_fetchPackages(), _fetchUserSelectedCourses()]);
  }

  Future<void> _fetchUserSelectedCourses() async {
    if (_user == null) return;
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': _user!.id.toString()};
      final response = await authRepository.getUserSelected_non_Courses(data);

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        final all = list.map((e) => SelectedCourseItem.fromJson(e)).toList();
        if (mounted) {
          setState(() {
            _userSelectedCourses = all.where((c) => c.isSelected).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Selected courses fetch error: $e');
    }
  }

  Future<void> _fetchPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'action': 'fetch_packages', if (_user != null) 'user_id': _user!.id.toString()};

      final response = await authRepository.fetchPackages(data);

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final bool status = body['status'] ?? false;
        final List<dynamic>? raw = body['packages'] as List<dynamic>?;

        if (status && raw != null) {
          setState(() {
            _packages = raw.map((p) => _Package.fromJson(p as Map<String, dynamic>)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Packages could not be loaded. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error (${response.statusCode}). Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection and try again.';
        _isLoading = false;
      });
      debugPrint('fetchPackages error: $e');
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  _Package? _getPackage(String slug) {
    try {
      return _packages.firstWhere((p) => p.slug == slug);
    } catch (_) {
      return null;
    }
  }

  bool _isActivePlan(String slug) => _activePlanSlug == slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child:
            _isLoading
                ? _buildLoader()
                : _error != null
                ? _buildErrorState()
                : Padding(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
                  child: Column(
                    children: [
                      if (_getPackage('free') != null) _buildFreeCard(_getPackage('free')!),
                      const SizedBox(height: 12),
                      if (_getPackage('basic') != null) _buildBasicCard(_getPackage('basic')!),
                      const SizedBox(height: 12),
                      if (_getPackage('premium') != null) _buildPremiumCard(_getPackage('premium')!),
                      const SizedBox(height: 20),
                      _buildInfoNote(),
                      const SizedBox(height: 16),
                      _buildTrustBar(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      ),
    );
  }

  // ─── Loader ─────────────────────────────────────────────────────────────────

  Widget _buildLoader() {
    return const SizedBox(height: 400, child: Center(child: CircularProgressIndicator(color: AppColors.tealGreen)));
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              style: TextStyle(color: AppColors.greyS600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPackages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Try Again', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C3756), AppColors.darkNavy],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Plans & Pricing',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.white),
                      ),
                      Text(
                        'Choose the best plan for your budget',
                        style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.65)),
                      ),
                    ],
                  ),
                ),
                _statChip('4.8 ★', 'Rating'),
              ],
            ),
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
          Text(num, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  // ─── FREE CARD ──────────────────────────────────────────────────────────────

  Widget _buildFreeCard(_Package pkg) {
    final isActive = _isActivePlan(pkg.slug);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.tealGreen.withOpacity(0.5) : AppColors.greyS200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
                  child: const Text('🎁', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                    ),
                    Text(pkg.billingLabel, style: TextStyle(fontSize: 11, color: AppColors.greyS500)),
                  ],
                ),
                const Spacer(),
                if (isActive)
                  _activeBadge()
                else
                  Text(
                    pkg.priceDisplay,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _divider(),
            const SizedBox(height: 14),
            ...pkg.features.map((f) => _featureRow(f.text, included: f.isIncluded)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child:
                  isActive
                      ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.tealGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.tealGreen.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.tealGreen, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '✓ Current Plan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tealGreen,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.tealGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.tealGreen.withOpacity(0.4)),
                              ),
                              child: Text(
                                'Active ✓',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.tealGreen),
                              ),
                            ),
                          ],
                        ),
                      )
                      : OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.greyS300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Use Now',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.greyS600),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BASIC CARD ─────────────────────────────────────────────────────────────

  Widget _buildBasicCard(_Package pkg) {
    final isActive = _isActivePlan(pkg.slug);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.tealGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: AppColors.lightGold.withOpacity(0.6), width: 2) : null,
        boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.06), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.04), shape: BoxShape.circle),
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
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🚀', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white),
                          ),
                          Text(
                            pkg.billingLabel,
                            style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      _activeBadgeDark()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(20)),
                        child: const Text(
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
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: [
                              AppColors.white,
                              AppColors.white.withOpacity(0.5 + _shimmerAnim.value * 0.5),
                              AppColors.white,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                      child: child,
                    );
                  },
                  child: Text(
                    pkg.priceDisplay,
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

                ...pkg.features.map((f) => _featureRowDark(f.text, included: f.isIncluded)),

                const SizedBox(height: 18),

                if (isActive && _activatedCourse != null) ...[
                  _buildActivatedCourseBadge(),
                ] else if (isActive) ...[
                  _buildActiveFullButton(),
                ] else ...[
                  GestureDetector(
                    onTap: () => _showCourseBottomSheet(pkg),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                          const Text('🛒', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(
                            'Buy Now — ${pkg.priceDisplay}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
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

  Widget _buildPremiumCard(_Package pkg) {
    final isActive = _isActivePlan(pkg.slug);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.lightGold.withOpacity(0.8) : AppColors.lightGold.withOpacity(0.4),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(color: AppColors.lightGold.withOpacity(0.06), shape: BoxShape.circle),
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
                        border: Border.all(color: AppColors.lightGold.withOpacity(0.25)),
                      ),
                      child: const Text('👑', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white),
                          ),
                          Text(
                            pkg.billingLabel,
                            style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.55)),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      _activeBadgeGold()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.lightGold.withOpacity(0.6)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
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

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pkg.priceDisplay,
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
                        pkg.billingType == 'monthly' ? '/ month' : '/ ${pkg.validityDays} days',
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

                ...pkg.features
                    .where(
                      (f) => !f.text.toLowerCase().contains('offline') && !f.text.toLowerCase().contains('certificate'),
                    )
                    .map((f) => _featureRowDark(f.text, included: f.isIncluded, accent: AppColors.lightGold)),

                const SizedBox(height: 18),

                if (isActive) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium, color: AppColors.lightGold, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '✓ Current Plan — Active',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightGold),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () => _showPremiumBottomSheet(pkg),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
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
                          const Text('👑', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Get Premium — ${pkg.priceDisplay}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
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

  // ─── Active state helpers ────────────────────────────────────────────────────

  Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tealGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.4)),
      ),
      child: const Text(
        '✓ Current Plan',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.tealGreen, letterSpacing: 0.3),
      ),
    );
  }

  Widget _activeBadgeDark() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.3)),
      ),
      child: const Text(
        '✓ Active',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 0.3),
      ),
    );
  }

  Widget _activeBadgeGold() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightGold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGold.withOpacity(0.7)),
      ),
      child: const Text(
        '✓ Active',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.lightGold, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildActiveFullButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.lightGold, size: 16),
              SizedBox(width: 6),
              Text(
                '✓ Current Plan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lightGold.withOpacity(0.5)),
            ),
            child: Text(
              'Active ✓',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.lightGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivatedCourseBadge() {
    final course =
        _userSelectedCourses.isNotEmpty
            ? _userSelectedCourses.firstWhere(
              (c) => c.categoryId.toString() == _activatedCourse,
              orElse: () => _userSelectedCourses.first,
            )
            : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.lightGold, size: 16),
              SizedBox(width: 6),
              Text(
                course != null ? '✓ ${course.categoryName}' : '✓ Current Plan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lightGold.withOpacity(0.5)),
            ),
            child: Text(
              'Active ✓',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.lightGold),
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
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.2)),
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
                const Text(
                  'How does the Basic Plan work?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay ₹29 → Select one course (SSC/Banking/etc.) → That course unlocks forever! Get all mock tests, live quizzes and study material for that course.',
                  style: TextStyle(fontSize: 11, color: AppColors.greyS600, height: 1.6),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(child: _trustItem('🔐', 'Secure', 'Payment')),
          _vDivider(),
          Expanded(child: _trustItem('↩️', 'Easy', 'Refund')),
          _vDivider(),
          Expanded(child: _trustItem('⚡', 'Instant', 'Access')),
        ],
      ),
    );
  }

  Widget _trustItem(String icon, String title, String sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.darkNavy)),
        Text(sub, style: TextStyle(fontSize: 10, color: AppColors.greyS500)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 40, color: AppColors.greyS200);

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
              color: included ? AppColors.tealGreen.withOpacity(0.1) : AppColors.greyS200,
            ),
            child: Center(
              child: Text(
                included ? '✓' : '✕',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: included ? AppColors.tealGreen : AppColors.greyS400,
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
              decoration: included ? TextDecoration.none : TextDecoration.lineThrough,
              fontWeight: included ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRowDark(String label, {required bool included, Color? accent}) {
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
              color: included ? tickColor.withOpacity(0.18) : AppColors.white.withOpacity(0.07),
            ),
            child: Center(
              child: Text(
                included ? '✓' : '✕',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: included ? tickColor : AppColors.white.withOpacity(0.25),
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
                color: included ? AppColors.white.withOpacity(0.9) : AppColors.white.withOpacity(0.28),
                decoration: included ? TextDecoration.none : TextDecoration.lineThrough,
                fontWeight: included ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: AppColors.greyS200);

  // ─── BASIC BOTTOM SHEET ─────────────────────────────────────────────────────

  void _showCourseBottomSheet(_Package pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => _CourseSelectionSheet(
            pkg: pkg,
            userCourses: _userSelectedCourses,
            isPremium: false,
            onActivate: (courseId, courseName) {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CheckoutPage(contentType: 'Subscription', contentId: courseId, package_id: pkg.id.toString()),
                ),
              );
            },
          ),
    );
  }

  // ─── PREMIUM BOTTOM SHEET ───────────────────────────────────────────────────

  void _showPremiumBottomSheet(_Package pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => _CourseSelectionSheet(
            pkg: pkg,
            userCourses: _userSelectedCourses,
            isPremium: true,
            onActivate: (courseId, courseName) {
              setState(() => _activePlanSlug = pkg.slug);
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CheckoutPage(contentType: 'Subscription', contentId: courseId, package_id: pkg.id.toString()),
                ),
              );
            },
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.white)),
        backgroundColor: AppColors.tealGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── COURSE SELECTION BOTTOM SHEET (shared for Basic & Premium) ──────────────

class _CourseSelectionSheet extends StatefulWidget {
  final _Package pkg;
  final List<SelectedCourseItem> userCourses;
  final void Function(String courseId, String courseName) onActivate;
  final bool isPremium;

  const _CourseSelectionSheet({
    required this.pkg,
    required this.userCourses,
    required this.onActivate,
    this.isPremium = false,
  });

  @override
  State<_CourseSelectionSheet> createState() => _CourseSelectionSheetState();
}

class _CourseSelectionSheetState extends State<_CourseSelectionSheet> {
  SelectedCourseItem? _selected;

  @override
  Widget build(BuildContext context) {
    final courses = widget.userCourses;

    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(2)),
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
                          widget.isPremium ? 'Select Your Course 👑' : 'Select Your Course 📋',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                        ),
                        Text(
                          widget.isPremium
                              ? 'All courses unlock · ${widget.pkg.validityDays} days validity'
                              : '1 course · ${widget.pkg.validityDays} days validity',
                          style: TextStyle(fontSize: 11, color: AppColors.greyS500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(20)),
                      child: Icon(Icons.close, size: 18, color: AppColors.greyS600),
                    ),
                  ),
                ],
              ),
            ),

            // Premium info banner
            if (widget.isPremium) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.lightGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGold.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 11, color: AppColors.greyS700, height: 1.4),
                          children: [
                            TextSpan(
                              text: 'More than Basic! ',
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                            ),
                            const TextSpan(text: 'Get '),
                            TextSpan(
                              text: 'Selected Courses + Leaderboard + Study Material',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.tealGreen),
                            ),
                            const TextSpan(
                              text: '. Basic only gives Mock Test and Quizes with no Leaderboard or Study Material.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 6),
            Divider(color: AppColors.greyS200),

            // Empty state
            if (courses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    const Text('😕', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    const Text(
                      'No courses selected',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please go to "My Courses" first and select your courses, then come back to activate.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.greyS500, height: 1.5),
                    ),
                  ],
                ),
              )
            else ...[
              // Course Grid
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.7,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final isSelected = _selected?.categoryId == course.categoryId;
                    return _SelectedCourseCard(
                      course: course,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = course),
                    );
                  },
                ),
              ),

              // Activate button
              Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, MediaQuery.of(context).padding.bottom + 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap:
                          _selected != null
                              ? () => widget.onActivate(_selected!.categoryId.toString(), _selected!.categoryName)
                              : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient:
                              _selected != null
                                  ? LinearGradient(
                                    colors:
                                        widget.isPremium
                                            ? [AppColors.lightGold, AppColors.lightGoldS2]
                                            : [AppColors.darkNavy, AppColors.tealGreen],
                                  )
                                  : null,
                          color: _selected != null ? null : AppColors.greyS200,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              _selected != null
                                  ? [
                                    BoxShadow(
                                      color: (widget.isPremium ? AppColors.lightGold : AppColors.tealGreen).withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.isPremium ? '👑' : '✅', style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              _selected != null
                                  ? '${_selected!.categoryName} · Pay ${widget.pkg.priceDisplay}'
                                  : 'Select a Course First',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color:
                                    _selected != null
                                        ? (widget.isPremium ? AppColors.darkNavy : AppColors.white)
                                        : AppColors.greyS500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isPremium
                          ? '⚠️  All courses will unlock · Select your primary course'
                          : '⚠️  Cannot be changed once selected',
                      style: TextStyle(fontSize: 11, color: AppColors.greyS400),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Maybe Later', style: TextStyle(fontSize: 13, color: AppColors.greyS500)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Selected Course Card ─────────────────────────────────────────────────────

class _SelectedCourseCard extends StatelessWidget {
  final SelectedCourseItem course;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectedCourseCard({required this.course, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [AppColors.darkNavy, AppColors.tealGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isSelected ? null : AppColors.greyS1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.tealGreen : AppColors.greyS200, width: isSelected ? 2 : 1.5),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(color: AppColors.tealGreen.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                  ]
                  : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white.withOpacity(0.18) : AppColors.tealGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.book_outlined, size: 20, color: isSelected ? AppColors.white : AppColors.tealGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.categoryName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? AppColors.white : AppColors.darkNavy,
                        height: 1.2,
                      ),
                    ),
                    if (course.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        course.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? AppColors.white.withOpacity(0.7) : AppColors.greyS500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: AppColors.lightGold, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
