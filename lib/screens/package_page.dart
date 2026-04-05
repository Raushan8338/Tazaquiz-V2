import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/selected_courses_item.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/screens/course_selection.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class _PlanFeature {
  final String text;
  final bool isIncluded;
  const _PlanFeature({required this.text, required this.isIncluded});
  factory _PlanFeature.fromJson(Map<String, dynamic> json) =>
      _PlanFeature(text: json['text'] ?? '', isIncluded: json['is_included'] ?? false);
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

  factory _Package.fromJson(Map<String, dynamic> json) => _Package(
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

const _freeFeatures = ['📝  Mock Test', '📋  Daily Live Quizes', '🎯 Test', '📚 Daily News Update'];
const _commonFeatures = [
  '📝  Mock Test',
  '📋  Full Mock Test',
  '♾️  Unlimited Tests',
  '🎯  Topic Wise Test',
  '📚  Subject Wise Test',
  '🔴  Daily Live Quizzes',
  '📰  Daily Updated News',
  '🏆  Result & Vacancy Update',
  '🎧  Premium Support',
];
const _premiumExtra = ['📒  Study Material (Notes)', '📜  Previous Year Papers (PYPs)'];

class PricingPage extends StatefulWidget {
  final String? activePackageSlug;
  final String CourseIds;
  PricingPage({super.key, this.activePackageSlug, required this.CourseIds});

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

  static const _navy = Color(0xFF0D1B2A);
  static const _teal = Color(0xFF1D9E75);
  static const _tealLight = Color(0xFF25C48F);
  static const _gold = Color(0xFFFFC107);
  static const _white = Color(0xFFFFFFFF);
  static const _pageBg = Color(0xFFF0F4F8);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _grey100 = Color(0xFFF1F5F9);
  static const _grey200 = Color(0xFFE2E8F0);
  static const _grey300 = Color(0xFFCBD5E1);
  static const _grey400 = Color(0xFF94A3B8);
  static const _grey500 = Color(0xFF64748B);
  static const _grey600 = Color(0xFF475569);

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
      final response = await Authrepository(
        Api_Client.dio,
      ).getUserSelected_non_Courses({'user_id': _user!.id.toString()});
      if (response.statusCode == 200) {
        final all = (response.data['data'] as List? ?? []).map((e) => SelectedCourseItem.fromJson(e)).toList();
        if (mounted) setState(() => _userSelectedCourses = all);
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
      final data = {'action': 'fetch_packages', if (_user != null) 'user_id': _user!.id.toString()};
      final response = await Authrepository(Api_Client.dio).fetchPackages(data);
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final raw = body['packages'] as List<dynamic>?;
        if ((body['status'] ?? false) && raw != null) {
          setState(() {
            _packages = raw.map((p) => _Package.fromJson(p)).toList();
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
      backgroundColor: _pageBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child:
                _isLoading
                    ? _buildLoader()
                    : _error != null
                    ? _buildErrorState()
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _navy,
      expandedHeight: 0,
      toolbarHeight: 56,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back, color: _white, size: 20),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Plans & Pricing',
            style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _teal.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: _tealLight, size: 10),
                const SizedBox(width: 3),
                Text(
                  'UNLOCK YOUR POTENTIAL',
                  style: TextStyle(fontSize: 8, color: _tealLight, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
      child: Column(
        children: [
          if (_getPackage('basic') != null) ...[_buildBasicCard(_getPackage('basic')!), const SizedBox(height: 12)],
          if (_getPackage('premium') != null) ...[
            _buildPremiumCard(_getPackage('premium')!),
            const SizedBox(height: 12),
          ],
          if (_getPackage('free') != null) ...[_buildFreeCard(_getPackage('free')!), const SizedBox(height: 16)],
          _buildInfoNote(),
          const SizedBox(height: 14),
          _buildTrustBar(),
        ],
      ),
    );
  }

  // ─── BASIC CARD ──────────────────────────────────────────────────────────────

  Widget _buildBasicCard(_Package pkg) {
    final isActive = _isActivePlan(pkg.slug);
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? _teal.withOpacity(0.6) : const Color(0xFF9FE1CB), width: isActive ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF9FE1CB)),
                ),
                child: Text('⭐ Popular', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _teal)),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🚀', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
                      Text(pkg.billingLabel, style: TextStyle(fontSize: 10, color: _grey500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pkg.priceDisplay,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _teal, letterSpacing: -0.5),
                    ),
                    Text(pkg.billingLabel, style: TextStyle(fontSize: 9, color: _grey400)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: _grey200, height: 1),
            const SizedBox(height: 10),
            _sectionLabel('Included features'),
            const SizedBox(height: 8),
            // ✅ LayoutBuilder row-pair chips — no extra vertical space
            _buildChipsLayout(_commonFeatures, _teal),
            const SizedBox(height: 4),
            _buildChipsMutedLayout(_premiumExtra),
            const SizedBox(height: 14),
            if (isActive && _activatedCourse != null)
              _buildActivatedCourseBadge()
            else if (isActive)
              _buildActiveFullButton()
            else
              GestureDetector(
                onTap: () {
                  if (widget.CourseIds != '0') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CheckoutPage(
                              contentType: 'Subscription',
                              contentId: widget.CourseIds,
                              package_id: pkg.id.toString(),
                            ),
                      ),
                    );
                  } else {
                    _showCourseBottomSheet(pkg);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        'Get Basic — ${pkg.priceDisplay}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _white),
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

  // ─── PREMIUM CARD ─────────────────────────────────────────────────────────────

  Widget _buildPremiumCard(_Package pkg) {
    final isActive = _isActivePlan(pkg.slug);
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? _gold.withOpacity(0.8) : const Color(0xFFE2C97E), width: isActive ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: _gold.withOpacity(0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👑', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 6),
                Text(
                  'BEST VALUE — MOST FEATURES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF854F0B),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('👑', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
                          ),
                          Text(pkg.billingLabel, style: TextStyle(fontSize: 10, color: _grey500)),
                        ],
                      ),
                    ),
                    if (isActive)
                      _goldBadge('✓ Active')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            pkg.priceDisplay,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB07D10),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            pkg.billingType == 'monthly' ? '/ month' : '/ ${pkg.validityDays} days',
                            style: TextStyle(fontSize: 9, color: _grey400),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: _grey200, height: 1),
                const SizedBox(height: 10),
                _sectionLabel('Premium extras ✨'),
                const SizedBox(height: 8),
                _buildChipsPremiumLayout(_premiumExtra),
                const SizedBox(height: 10),
                _sectionLabel('+ All Basic features'),
                const SizedBox(height: 8),
                _buildChipsLayout(_commonFeatures, _gold),
                const SizedBox(height: 14),
                if (isActive) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium, color: _gold, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          '✓ Current Plan — Active',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _gold),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () {
                      if (widget.CourseIds != '0') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CheckoutPage(
                                  contentType: 'Subscription',
                                  contentId: widget.CourseIds,
                                  package_id: pkg.id.toString(),
                                ),
                          ),
                        );
                      } else {
                        _showPremiumBottomSheet(pkg);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(
                            'Get Premium — ${pkg.priceDisplay}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy),
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

  // ─── FREE CARD ────────────────────────────────────────────────────────────────

  Widget _buildFreeCard(_Package pkg) {
    final isActive = _isActivePlan(pkg.slug);
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? _teal.withOpacity(0.5) : _grey300, width: isActive ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: _grey100, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🎁', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
                      Text(pkg.billingLabel, style: TextStyle(fontSize: 10, color: _grey500)),
                    ],
                  ),
                ),
                if (isActive)
                  _greenActiveBadge()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('₹0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _navy)),
                      Text('Forever', style: TextStyle(fontSize: 9, color: _grey400)),
                    ],
                  ),
              ],
            ),
            Divider(color: _grey200, height: 20),
            _sectionLabel("What's included (Limited access)"),
            const SizedBox(height: 8),
            _buildChipsLightLayout(_freeFeatures),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child:
                  isActive
                      ? _activeRowButton(color: _teal)
                      : OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _grey300),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Use Free Plan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _grey600),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ✅ Chip Builders — LayoutBuilder + Row pairs (tight spacing) ─────────────

  Widget _buildChipsLayout(List<String> features, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 6) / 2;
        final List<Widget> rows = [];
        for (int i = 0; i < features.length; i += 2) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
          rows.add(
            Row(
              children: [
                _singleChip(features[i], color, w),
                const SizedBox(width: 6),
                if (i + 1 < features.length) _singleChip(features[i + 1], color, w) else SizedBox(width: w),
              ],
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }

  Widget _singleChip(String text, Color color, double width) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(7)),
      child: Row(
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text.trim(),
              style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildChipsMutedLayout(List<String> features) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 6) / 2;
        final List<Widget> rows = [];
        for (int i = 0; i < features.length; i += 2) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
          rows.add(
            Row(
              children: [
                _singleChipMuted(features[i], w),
                const SizedBox(width: 6),
                if (i + 1 < features.length) _singleChipMuted(features[i + 1], w) else SizedBox(width: w),
              ],
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }

  Widget _singleChipMuted(String text, double width) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: _grey100, borderRadius: BorderRadius.circular(7)),
      child: Text(
        text.trim(),
        style: TextStyle(fontSize: 10.5, color: _grey300, fontWeight: FontWeight.w400),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );

  Widget _buildChipsPremiumLayout(List<String> features) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 6) / 2;
        final List<Widget> rows = [];
        for (int i = 0; i < features.length; i += 2) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
          rows.add(
            Row(
              children: [
                _singleChipPremium(features[i], w),
                const SizedBox(width: 6),
                if (i + 1 < features.length) _singleChipPremium(features[i + 1], w) else SizedBox(width: w),
              ],
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }

  Widget _singleChipPremium(String text, double width) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(width: 5, height: 5, decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text.trim(),
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFB07D10), fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: _gold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
            child: const Text(
              'NEW',
              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _gold, letterSpacing: 0.4),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildChipsLightLayout(List<String> features) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 6) / 2;
        final List<Widget> rows = [];
        for (int i = 0; i < features.length; i += 2) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
          rows.add(
            Row(
              children: [
                _singleChipLight(features[i], w),
                const SizedBox(width: 6),
                if (i + 1 < features.length) _singleChipLight(features[i + 1], w) else SizedBox(width: w),
              ],
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }

  Widget _singleChipLight(String text, double width) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: _teal.withOpacity(0.07), borderRadius: BorderRadius.circular(7)),
      child: Row(
        children: [
          Container(width: 5, height: 5, decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text.trim(),
              style: const TextStyle(fontSize: 10.5, color: _teal, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  // ─── Section label ────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) =>
      Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _grey500, letterSpacing: 0.5));

  // ─── Badges ───────────────────────────────────────────────────────────────────

  Widget _greenActiveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _teal.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _teal.withOpacity(0.4)),
    ),
    child: const Text(
      '✓ Active',
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _teal, letterSpacing: 0.3),
    ),
  );

  Widget _goldBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _gold.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _gold.withOpacity(0.5)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 0.3),
    ),
  );

  Widget _activeRowButton({required Color color}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: color, size: 16),
            const SizedBox(width: 6),
            Text('✓ Current Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text('Active ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    ),
  );

  Widget _buildActiveFullButton() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    decoration: BoxDecoration(
      color: _teal.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _teal.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _teal, size: 16),
            const SizedBox(width: 6),
            const Text('✓ Current Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withOpacity(0.5)),
          ),
          child: const Text('Active ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _gold)),
        ),
      ],
    ),
  );

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
        color: _teal.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _gold, size: 16),
              const SizedBox(width: 6),
              Text(
                course != null ? '✓ ${course.categoryName}' : '✓ Current Plan',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.5)),
            ),
            child: const Text('Active ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _gold)),
          ),
        ],
      ),
    );
  }

  // ─── Info Note & Trust Bar ────────────────────────────────────────────────────

  Widget _buildInfoNote() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _teal.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _teal.withOpacity(0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💡', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How does the Basic Plan work?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy),
              ),
              const SizedBox(height: 4),
              Text(
                'Pay ₹29 → Select one course (SSC/Banking/etc.) → That course unlocks forever!',
                style: TextStyle(fontSize: 11, color: _grey600, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTrustBar() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Expanded(child: _trustItem('🔐', 'Secure', 'Payment')),
        Container(width: 1, height: 36, color: _grey300),
        Expanded(child: _trustItem('↩️', 'Easy', 'Refund')),
        Container(width: 1, height: 36, color: _grey300),
        Expanded(child: _trustItem('⚡', 'Instant', 'Access')),
      ],
    ),
  );

  Widget _trustItem(String icon, String title, String sub) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 3),
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _navy)),
      Text(sub, style: TextStyle(fontSize: 10, color: _grey500)),
    ],
  );

  Widget _buildLoader() => const SizedBox(height: 400, child: Center(child: CircularProgressIndicator(color: _teal)));

  Widget _buildErrorState() => SizedBox(
    height: 400,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(color: _grey500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchPackages,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Try Again', style: TextStyle(color: _white)),
          ),
        ],
      ),
    ),
  );

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
}

// ─── COURSE SELECTION BOTTOM SHEET ───────────────────────────────────────────

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
  final TextEditingController _searchCtrl = TextEditingController();
  List<SelectedCourseItem> _filtered = [];

  static const _navy = Color(0xFF0D1B2A);
  static const _teal = Color(0xFF1D9E75);
  static const _gold = Color(0xFFFFC107);
  static const _white = Color(0xFFFFFFFF);
  static const _grey100 = Color(0xFFF1F5F9);
  static const _grey200 = Color(0xFFE2E8F0);
  static const _grey300 = Color(0xFFCBD5E1);
  static const _grey400 = Color(0xFF94A3B8);
  static const _grey500 = Color(0xFF64748B);
  static const _grey600 = Color(0xFF475569);
  static const _grey700 = Color(0xFF334155);

  @override
  void initState() {
    super.initState();
    _filtered = widget.userCourses;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered =
          q.isEmpty
              ? widget.userCourses
              : widget.userCourses.where((c) => c.categoryName.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: _grey300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPremium ? 'Select Your Course 👑' : 'Select Your Course 📋',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isPremium
                            ? 'All courses unlock · ${widget.pkg.validityDays} days validity'
                            : '1 course · ${widget.pkg.validityDays} days validity',
                        style: TextStyle(fontSize: 11, color: _grey500),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _grey100, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.close, size: 18, color: _grey600),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isPremium) ...[
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 11, color: _grey700, height: 1.4),
                        children: [
                          const TextSpan(
                            text: 'Premium Bonus! ',
                            style: TextStyle(fontWeight: FontWeight.w800, color: _navy),
                          ),
                          const TextSpan(text: 'Get '),
                          TextSpan(
                            text: 'Study Notes + PYPs + Leaderboard',
                            style: TextStyle(fontWeight: FontWeight.w700, color: _teal),
                          ),
                          const TextSpan(text: ' on top of everything Basic offers.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: _grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _grey200),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search course...',
                  hintStyle: TextStyle(fontSize: 13, color: _grey400),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: _grey400),
                  suffixIcon:
                      _searchCtrl.text.isNotEmpty
                          ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              FocusScope.of(context).unfocus();
                            },
                            child: Icon(Icons.close_rounded, size: 18, color: _grey400),
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                  isDense: true,
                ),
              ),
            ),
          ),
          Divider(color: _grey200, height: 20),
          Flexible(
            child:
                widget.userCourses.isEmpty
                    ? _buildEmptyState()
                    : _filtered.isEmpty
                    ? _buildNoResultsState()
                    : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.7,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final course = _filtered[index];
                          final isSelected = _selected?.categoryId == course.categoryId;
                          return _SelectedCourseCard(
                            course: course,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selected = course),
                          );
                        },
                      ),
                    ),
          ),
          if (widget.userCourses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyCoursesSelection(pageId: 0))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 18, color: _teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: _grey600, height: 1.4),
                            children: [
                              TextSpan(
                                text: 'Want a different course? ',
                                style: TextStyle(fontWeight: FontWeight.w700, color: _navy),
                              ),
                              const TextSpan(text: 'Go to "Selected Courses" and select it first.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _teal),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
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
                                colors: widget.isPremium ? [_gold, const Color(0xFFFFD54F)] : [_navy, _teal],
                              )
                              : null,
                      color: _selected != null ? null : _grey200,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow:
                          _selected != null
                              ? [
                                BoxShadow(
                                  color: (widget.isPremium ? _gold : _teal).withOpacity(0.3),
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
                            color: _selected != null ? (widget.isPremium ? _navy : _white) : _grey500,
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
                  style: TextStyle(fontSize: 11, color: _grey400),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Maybe Later', style: TextStyle(fontSize: 13, color: _grey500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    child: Column(
      children: [
        const Text('😕', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        const Text('No courses selected', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
        const SizedBox(height: 6),
        Text(
          'Please go to "My Courses" first and select your courses, then come back to activate.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _grey500, height: 1.5),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyCoursesSelection(pageId: 0))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 16, color: _white),
                SizedBox(width: 6),
                Text('Go to My Courses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _white)),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildNoResultsState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        const Text('🔍', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 10),
        Text(
          'No course found for "${_searchCtrl.text}"',
          style: TextStyle(fontSize: 13, color: _grey500),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ─── Selected Course Card ─────────────────────────────────────────────────────

class _SelectedCourseCard extends StatelessWidget {
  final SelectedCourseItem course;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectedCourseCard({required this.course, required this.isSelected, required this.onTap});

  static const _navy = Color(0xFF0D1B2A);
  static const _teal = Color(0xFF1D9E75);
  static const _gold = Color(0xFFFFC107);
  static const _white = Color(0xFFFFFFFF);
  static const _grey100 = Color(0xFFF1F5F9);
  static const _grey200 = Color(0xFFE2E8F0);
  static const _grey500 = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(
                    colors: [Color(0xFF0D2137), Color(0xFF0D3D2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isSelected ? null : _grey100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? _teal : _grey200, width: isSelected ? 2 : 1.5),
          boxShadow:
              isSelected ? [BoxShadow(color: _teal.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? _white.withOpacity(0.15) : _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.book_outlined, size: 20, color: isSelected ? _white : _teal),
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
                        color: isSelected ? _white : _navy,
                        height: 1.2,
                      ),
                    ),
                    if (course.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        course.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: isSelected ? _white.withOpacity(0.65) : _grey500),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: _gold, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
