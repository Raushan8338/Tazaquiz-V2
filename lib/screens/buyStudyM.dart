import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/ads/banner_ads_helper.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/screens/PDFViewerPage.dart';
import 'package:tazaquiznew/screens/Paid_quzes_list.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/screens/package_page.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/study_material_details_item.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

// ── Package Model ─────────────────────────────────────────────────────────────

class PackageFeature {
  final String text;
  final String label;
  final bool isIncluded;
  const PackageFeature({required this.text, required this.label, required this.isIncluded});

  factory PackageFeature.fromJson(Map<String, dynamic> json) {
    return PackageFeature(
      text: json['text']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      isIncluded: json['is_included'] == true || json['is_included'] == 1,
    );
  }
}

class PackageItem {
  final int packageId;
  final String name;
  final double price;
  final double oldPrice;
  final int validityDays;
  final List<PackageFeature> features;

  const PackageItem({
    required this.packageId,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.validityDays,
    required this.features,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    final featureList =
        (json['features'] as List? ?? []).map((e) => PackageFeature.fromJson(e as Map<String, dynamic>)).toList();
    return PackageItem(
      packageId: _toInt(json['package_id']),
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']),
      oldPrice: _toDouble(json['old_price']),
      validityDays: _toInt(json['validity_days']),
      features: featureList,
    );
  }

  int get discountPercent {
    if (oldPrice <= 0) return 0;
    return (((oldPrice - price) / oldPrice) * 100).round();
  }
}

// ── BuyCoursePage ─────────────────────────────────────────────────────────────

class BuyCoursePage extends StatefulWidget {
  final String contentId;
  final String page_API_call;

  BuyCoursePage({required this.contentId, required this.page_API_call});

  @override
  _BuyCoursePageState createState() => _BuyCoursePageState();
}

class _BuyCoursePageState extends State<BuyCoursePage> with SingleTickerProviderStateMixin {
  final BannerAdService bannerService = BannerAdService();
  bool isBannerLoaded = false;
  UserModel? _user;
  List<StudyMaterialDetailsItem> _studyMaterials_new = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorType = '';
  bool _isPurchased = false;
  int _product_sub_id = 0;
  int _isPremium = 0;
  bool _isAccessible = false;
  bool _isFree = false;
  StudyMaterialDetailsItem? _currentMaterial;
  bool _descExpanded = false;

  // ── Package state ──────────────────────────────────────────────────────────
  List<PackageItem> _packages = [];
  PackageItem? _selectedPackage;

  final List<bool> _faqExpanded = List.filled(6, false);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _navy = Color(0xFF0A1628);
  static const _green = Color(0xFF1D9E75);
  static const _greenMid = Color(0xFF0F6E56);
  static const _greenLight = Color(0xFFE8F8F2);
  static const _greenBorder = Color(0xFF9FE1CB);
  static const _bg = Color(0xFFF0F3F8);
  static const _cardBg = Colors.white;
  static const _textMuted = Color(0xFF6B7A99);
  Color get _gold => AppColors.lightGold;
  Color get _primary => AppColors.darkNavy;
  static const _borderCol = Color(0xFFE4E9F4);

  final List<Map<String, String>> _faqs = [
    {
      'q': 'What is included in this course?',
      'a':
          'This course includes full mock tests, chapter-wise & subject-wise tests, live test series, All India ranking, study material, and daily current affairs updates. PYPs (Previous Year Questions) and Notes are available only in the premium plan, while all other features are available in both basic and premium plans.',
    },
    {
      'q': 'How long will I have access to this course?',
      'a':
          'You will have access to all content until the validity date shown on your purchased plan. All features remain accessible as per your plan during the validity period.',
    },
    {
      'q': 'Can I attempt mock tests multiple times?',
      'a':
          'Yes! All mock tests, chapter tests, and subject tests can be attempted unlimited times. This helps you practice repeatedly and track your improvement over time.',
    },
    {
      'q': 'What is the All India Ranking feature?',
      'a':
          'After each live test or mock test, you can see your rank compared to all students who appeared for the same test across India. This helps you evaluate your performance at a national level.',
    },
    {
      'q': 'Is the study material available offline?',
      'a':
          'Study materials like PDFs and notes can be downloaded for offline access (available in premium plan). Other features require an internet connection.',
    },
    {
      'q': 'How do I contact support if I face any issues?',
      'a':
          'You can reach our support team through the Help section in the app or via email. Our support is available 24/7 to assist you with any issues or queries.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorType = '';
      });
    try {
      _user = await SessionManager.getUser();
      if (_user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _user = await SessionManager.getUser();
      }
      if (_user == null) {
        if (mounted)
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorType = 'session';
          });
        return;
      }
      await fetchStudyCategory(_user!.id);
      if (!mounted) return;
      _fadeController.forward();
      setState(() {});
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'unknown';
        });
    }
  }

  Future<List<StudyMaterialDetailsItem>> fetchStudyCategory(String userid) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'material_id': widget.contentId.toString(),
        'user_id': userid.toString(),
        'page_API_call': widget.page_API_call,
      };
      final responseFuture = await authRepository
          .get_study_wise_details(data)
          .timeout(const Duration(seconds: 15), onTimeout: () => throw TimeoutException('Request timed out'));

      if (responseFuture.statusCode == 200) {
        final List list = responseFuture.data['data'] ?? [];
        _studyMaterials_new = list.map((e) => StudyMaterialDetailsItem.fromJson(e)).toList();
        if (_studyMaterials_new.isNotEmpty) {
          _currentMaterial = _studyMaterials_new.first;
          _isPurchased = _currentMaterial!.isPurchased;
          _isAccessible = _currentMaterial!.isAccessible;
          _isFree = !_currentMaterial!.isPaid;
          _isPremium = _currentMaterial!.is_premium ?? 0;
          _product_sub_id = _currentMaterial!.subscription_id ?? 0;

          // ── Parse packages from API ──────────────────────────────────────
          final rawPackages = responseFuture.data['data'][0]['packages'] as List? ?? [];
          _packages = rawPackages.map((e) => PackageItem.fromJson(e as Map<String, dynamic>)).toList();

          // Default: select first package
          if (_packages.isNotEmpty) {
            _selectedPackage = _packages.first;
          }

          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorType = 'server';
          });
        }
        return _studyMaterials_new;
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'server';
        });
        return [];
      }
    } on TimeoutException {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = 'timeout';
        });
      return [];
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType =
              (msg.contains('socket') || msg.contains('network') || msg.contains('connection'))
                  ? 'no_internet'
                  : 'unknown';
        });
      return [];
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    bannerService.dispose();
    super.dispose();
  }

  void _handleStartLearning() {
    if (_currentMaterial == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => StudyMaterialPurchaseHistoryScreen('1')));
  }

  void _handleSubscribe() {
    if (_currentMaterial == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckoutPage(
              contentType: 'Subscription',
              contentId: _currentMaterial!.subscription_id.toString(),
              package_id: _selectedPackage?.packageId.toString() ?? '',
            ),
      ),
    );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => PricingPage(CourseIds: _currentMaterial!.subscription_id.toString())),
    // ).then((v) {
    //   if (v == true) _getUserData();
    // });
  }

  // ── Show Package Picker Bottom Sheet ────────────────────────────────────────
  void _showPackagePicker() {
    // if (_packages.isEmpty) {
    //   _handleSubscribe();
    //   return;
    // }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _PackagePickerSheet(
            packages: _packages,
            selectedPackage: _selectedPackage,
            onSelect: (pkg) {
              setState(() {
                _selectedPackage = pkg;
              });
            },
            onProceed: (pkg) {
              setState(() {
                _selectedPackage = pkg;
              });
              _handleSubscribe();
            },
          ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    if (_hasError || _currentMaterial == null) return _errorScreen();

    final bool canStart = _isPurchased || _isAccessible || _isFree;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(title: _currentMaterial!.Material_name),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _heroBanner(canStart),
                const SizedBox(height: 12),
                if (canStart) ...[
                  _purchasedBanner(),
                  const SizedBox(height: 12),
                ] else ...[
                  _examComingSoonBanner(),
                  const SizedBox(height: 12),
                ],
                _specialFeaturesSection(),
                const SizedBox(height: 12),
                _contentSectionsCard(),
                const SizedBox(height: 12),

                // ── Dynamic Features from selected package ──────────────────
                if (!canStart && _selectedPackage != null) ...[_dynamicFeaturesCard(), const SizedBox(height: 12)],

                if (_currentMaterial!.description.isNotEmpty) ...[_descriptionCard(), const SizedBox(height: 12)],
                _faqSection(),
                const SizedBox(height: 8),
                _instructorCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(canStart),
    );
  }

  // ── Dynamic Features Card ───────────────────────────────────────────────────
  Widget _dynamicFeaturesCard() {
    if (_selectedPackage == null) return const SizedBox.shrink();
    final pkg = _selectedPackage!;
    final includedFeatures = pkg.features.where((f) => f.isIncluded).toList();
    final excludedFeatures = pkg.features.where((f) => !f.isIncluded).toList();

    final Color planColor = pkg.name.toLowerCase().contains('premium') ? const Color(0xFF6B4EE6) : _green;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [planColor.withOpacity(0.08), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: planColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      pkg.name.toLowerCase().contains('premium') ? Icons.workspace_premium : Icons.verified_rounded,
                      color: planColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pkg.name} Plan Features',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy),
                        ),
                        Text(
                          '${pkg.validityDays} days validity',
                          style: const TextStyle(fontSize: 11, color: _textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: planColor, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      pkg.discountPercent > 0 ? '${pkg.discountPercent}% OFF' : pkg.name.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: _borderCol),

            // ── Included ──
            if (includedFeatures.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Included',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _green, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              _featuresGrid(includedFeatures, true, planColor),
            ],

            // ── Not included ──
            if (excludedFeatures.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Not included',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              _featuresGrid(excludedFeatures, false, planColor),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _featuresGrid(List<PackageFeature> features, bool included, Color planColor) {
    // Pair items into rows of 2
    final List<Widget> rows = [];
    for (int i = 0; i < features.length; i += 2) {
      final left = features[i];
      final right = i + 1 < features.length ? features[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(child: _featureCell(left, included)),
              const SizedBox(width: 8),
              right != null ? Expanded(child: _featureCell(right, included)) : const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _featureCell(PackageFeature feature, bool included) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: included ? _green.withOpacity(0.05) : Colors.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: included ? _green.withOpacity(0.18) : Colors.redAccent.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: included ? _green.withOpacity(0.12) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              included ? Icons.check_rounded : Icons.close_rounded,
              size: 12,
              color: included ? _green : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: included ? _navy : _textMuted,
                    decoration: included ? null : TextDecoration.lineThrough,
                    decorationColor: _textMuted,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.label,
                  style: TextStyle(fontSize: 10, color: _textMuted.withOpacity(0.75), height: 1.3),
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

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar({String title = 'Course Details'}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_navy, Color(0xFF0D4B3B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Banner ─────────────────────────────────────────────────────────────
  Widget _heroBanner(bool canStart) {
    final String? thumbUrl = _currentMaterial!.thumbnail;
    final bool hasThumb = thumbUrl != null && thumbUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            if (hasThumb)
              SizedBox(
                width: double.infinity,
                height: 155,
                child: Image.network(
                  thumbUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 155,
                        color: _navy,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 36),
                        ),
                      ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 140,
                color: _navy,
                child: Center(
                  child: Icon(
                    _currentMaterial!.contentType.toUpperCase() == 'PDF'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.play_circle_outline_rounded,
                    color: Colors.white38,
                    size: 44,
                  ),
                ),
              ),
            if (canStart)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isFree ? _green : const Color(0xFF6B4EE6),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isFree ? Icons.lock_open_rounded : Icons.verified_rounded, color: Colors.white, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        _isFree ? 'FREE' : (_isPremium == 1 ? 'PREMIUM' : 'BASIC'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _heroBadge(
                    icon:
                        _currentMaterial!.contentType.toUpperCase() == 'PDF'
                            ? Icons.picture_as_pdf_outlined
                            : Icons.play_circle_outline_rounded,
                    label: 'Complete Course',
                    bgColor: _navy.withOpacity(0.08),
                    textColor: _navy,
                    iconColor: _navy,
                  ),
                  if (canStart && _isPurchased && !_isFree) ...[
                    const SizedBox(width: 8),
                    _heroBadge(
                      icon: Icons.verified_rounded,
                      label: 'PURCHASED',
                      bgColor: _green.withOpacity(0.1),
                      textColor: _green,
                      iconColor: _green,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _currentMaterial!.Material_name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              _compactDescription(),
              const SizedBox(height: 14),
              Row(
                children: [
                  _heroStat(Icons.bolt_rounded, 'Live Test', 'Unlimited'),
                  const SizedBox(width: 6),
                  _heroStat(Icons.edit_note_rounded, 'Mock Tests', 'Unlimited'),
                  const SizedBox(width: 6),
                  _heroStat(Icons.history_edu_rounded, 'PYPs', 'Upto 10 Yrs'),
                  const SizedBox(width: 6),
                  _heroStat(Icons.menu_book_rounded, 'Study Material', 'Full Access'),
                ],
              ),
              const SizedBox(height: 14),
              _contentChipsRow(),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactDescription() {
    final text = _currentMaterial!.subscription_description;
    if (text.isEmpty) return const SizedBox.shrink();
    const maxLines = 3;
    final isLong = text.length > 120;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: (!isLong || _descExpanded) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6A7A), height: 1.55),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(text, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6A7A), height: 1.55)),
        ),
        if (isLong) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? 'Read Less ▲' : 'Read More ▼',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _green),
            ),
          ),
        ],
      ],
    );
  }

  Widget _contentChipsRow() {
    // ── Dynamic chips from selected package features (if available) ──────
    if (!(_isPurchased || _isAccessible || _isFree) &&
        _selectedPackage != null &&
        _selectedPackage!.features.isNotEmpty) {
      return _dynamicChipsRow(_selectedPackage!.features);
    }

    // ── Fallback static chips ────────────────────────────────────────────
    final chips = [
      _ChipData('Chapter Test', Icons.menu_book_outlined, const Color(0xFF1565C0)),
      _ChipData('Subject Test', Icons.assignment_outlined, const Color(0xFF6A1B9A)),
      _ChipData('Live Test', Icons.bolt_rounded, const Color(0xFFE65100)),
      _ChipData('Full Mock', Icons.quiz_rounded, _green),
      _ChipData('PYQs', Icons.history_edu_rounded, _navy),
      _ChipData('Notes', Icons.description_outlined, const Color(0xFF00897B)),
      _ChipData('Leaderboard', Icons.leaderboard_rounded, const Color(0xFFD32F2F)),
      _ChipData('Daily Quiz', Icons.today_rounded, const Color(0xFF2E7D32)),
      _ChipData('Job Alerts', Icons.campaign_rounded, const Color(0xFFEF6C00)),
      _ChipData('Daily Updates', Icons.update_rounded, const Color(0xFF00838F)),
      _ChipData('24/7 Support', Icons.support_agent_rounded, const Color(0xFF5E35B1)),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.map((c) => _buildChipWidget(c.label, c.icon, c.color, true)).toList(),
    );
  }

  Widget _dynamicChipsRow(List<PackageFeature> features) {
    final iconMap = {
      'Chapter Test': Icons.menu_book_outlined,
      'Subject Test': Icons.assignment_outlined,
      'Live Test': Icons.bolt_rounded,
      'Full Mock': Icons.quiz_rounded,
      'PYQs': Icons.history_edu_rounded,
      'Notes': Icons.description_outlined,
      'Leaderboard': Icons.leaderboard_rounded,
      'Daily Quiz': Icons.today_rounded,
      'Job Alerts': Icons.campaign_rounded,
      'Daily Updates': Icons.update_rounded,
      '24/7 Support': Icons.support_agent_rounded,
    };
    final colorMap = {
      'Chapter Test': const Color(0xFF1565C0),
      'Subject Test': const Color(0xFF6A1B9A),
      'Live Test': const Color(0xFFE65100),
      'Full Mock': _green,
      'PYQs': _navy,
      'Notes': const Color(0xFF00897B),
      'Leaderboard': const Color(0xFFD32F2F),
      'Daily Quiz': const Color(0xFF2E7D32),
      'Job Alerts': const Color(0xFFEF6C00),
      'Daily Updates': const Color(0xFF00838F),
      '24/7 Support': const Color(0xFF5E35B1),
    };

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          features.map((f) {
            final icon = iconMap[f.text] ?? Icons.check_circle_outline;
            final color = colorMap[f.text] ?? _green;
            return _buildChipWidget(f.text, icon, color, f.isIncluded);
          }).toList(),
    );
  }

  Widget _buildChipWidget(String label, IconData icon, Color color, bool included) {
    return Opacity(
      opacity: included ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            if (!included) ...[const SizedBox(width: 3), Icon(Icons.lock_rounded, size: 9, color: color)],
          ],
        ),
      ),
    );
  }

  // ── Purchased Banner ────────────────────────────────────────────────────────
  Widget _purchasedBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isFree ? [_green, _greenMid] : [const Color(0xFF0D7B5F), _navy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(
                _isFree ? Icons.lock_open_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isFree
                        ? 'This Course is FREE! 🎉'
                        : _isPurchased
                        ? 'Course Purchased! ✅'
                        : 'Included in Your Plan!',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isFree ? 'Start now — no charges at all!' : 'Your access is fully unlocked. Start learning!',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.78)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Exam Coming Soon Banner ─────────────────────────────────────────────────
  Widget _examComingSoonBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        '🔔  EXAM ALERT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Exam Coming Soon!',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Don\'t miss out — start your prep today!',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showPackagePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                  ),
                  child: const Text(
                    'Enroll\nNow',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFD32F2F), height: 1.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: bgColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE3EE), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _green, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _green, height: 1.2),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 8.5, color: Color(0xFF8A9BB0), fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Special Features ────────────────────────────────────────────────────────
  Widget _specialFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_navy, Color(0xFF0D4B3B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Special Features',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(width: 6),
                  Text('✨'),
                ],
              ),
            ),
            _featureItem(
              title: 'Full Mock Test Series',
              desc:
                  'Chapter-wise, Subject-wise & Full mock tests for complete ${_currentMaterial!.Material_name} preparation.',
              icon: Icons.quiz_rounded,
              isIconRight: true,
            ),
            _divider(),
            _featureItem(
              title: 'Previous Year Questions',
              desc: 'Last 10+ years PYQs with detailed solutions & answer keys for thorough practice.',
              icon: Icons.history_edu_rounded,
            ),
            _divider(),
            _featureItem(
              title: 'Live Test Series',
              desc: 'Compete with thousands of students in real-time live tests & check All India Ranking.',
              icon: Icons.bolt_rounded,
              isIconRight: true,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: const Text(
                '📌  PYPs and Notes are available on Premium plan only.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem({required String title, required String desc, required IconData icon, bool isIconRight = false}) {
    final iconWidget = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: Colors.white, size: 26),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            isIconRight
                ? [Expanded(child: _textContent(title, desc)), const SizedBox(width: 12), iconWidget]
                : [iconWidget, const SizedBox(width: 12), Expanded(child: _textContent(title, desc))],
      ),
    );
  }

  Widget _textContent(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 5),
        Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: Colors.white.withOpacity(0.15),
    );
  }

  // ── Content Sections ────────────────────────────────────────────────────────
  Widget _contentSectionsCard() {
    print('Creating content sections card for material: ${_currentMaterial?.materialId}');
    final sections = [
      _SectionData(
        title: 'Chapter Test',
        subtitle: 'Topic & chapter wise tests to strengthen your basics',
        emoji: '📋',
        color: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF90CAF9),
        iconBg: const Color(0xFFBBDEFB),
        textColor: const Color(0xFF0D47A1),
        onTap: () =>  Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Paid_QuizListScreen(
                widget.contentId.toString(),
                '0',
                'Chapter Test', // passing feature name as page title
              ),
            ),
          ),
      ),
      _SectionData(
        title: 'Subject Test',
        subtitle: 'Subject-wise tests to simulate the actual exam environment',
        emoji: '📘',
        color: const Color(0xFFF3F0FF),
        borderColor: const Color(0xFFB39DDB),
        iconBg: const Color(0xFFEDE7F6),
        textColor: const Color(0xFF4A148C),
        onTap: () =>  Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Paid_QuizListScreen(
                widget.contentId.toString(),
                '4',
                'Subject Mock Test', // passing feature name as page title
              ),
            ),
          ),
      ),
      _SectionData(
        title: 'Full Mock Test',
        subtitle: 'Full-length real exam simulation with All India Ranking',
        emoji: '📄',
        color: const Color(0xFFF0F4FF),
        borderColor: const Color(0xFF90CAF9),
        iconBg: const Color(0xFFE3F2FD),
        textColor: const Color(0xFF0D47A1),
        onTap: () =>  Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Paid_QuizListScreen(
                widget.contentId.toString(),
                '5',
                'Full Mock Test', // passing feature name as page title
              ),
            ),
          ),
      ),
      _SectionData(
        title: 'Live Test',
        subtitle: 'Compete in real-time with students nationwide & track your rank',
        emoji: '⚡',
        color: const Color(0xFFFFF3E0),
        borderColor: const Color(0xFFFFCC80),
        iconBg: const Color(0xFFFFF3E0),
        textColor: const Color(0xFF6D4C00),
        onTap: () =>  Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Paid_QuizListScreen(
                widget.contentId.toString(),
                '7',
                'Live Test', // passing feature name as page title
              ),
            ),
          ),
      ),
      _SectionData(
  title: 'LeaderBoard',
  subtitle: 'Compete in real-time with students nationwide & track your rank',
  emoji: '🏆',
 color: const Color(0xFFFFEBEE),
  borderColor: const Color(0xFFEF9A9A),
  iconBg: const Color(0xFFFFCDD2),
  textColor: const Color(0xFFB71C1C),
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 2),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF1B5E20),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "This feature is only for paid users. Please go to course to access.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_green, _navy]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers_rounded, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'What\'s Inside',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
                  ),
                ],
              ),
            ),
            ...sections.map((s) => _sectionRow(s)).toList(),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _sectionRow(_SectionData s) {
    return GestureDetector(
      onTap: s.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: s.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: s.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: s.iconBg, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.textColor)),
                    const SizedBox(height: 3),
                    Text(
                      s.subtitle,
                      style: const TextStyle(fontSize: 11, color: _textMuted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: s.textColor)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 13, color: s.textColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Description Card ────────────────────────────────────────────────────────
  Widget _descriptionCard() {
    final text = _currentMaterial!.description;
    final bool isLong = text.length > 200;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_green, _navy]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text(
                  'About This Course',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: (!isLong || _descExpanded) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Stack(
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    text,
                    12.5,
                    AppColors.greyS700,
                    FontWeight.w400,
                    4,
                    TextAlign.left,
                    1.6,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0), Colors.white],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              secondChild: AppRichText.setTextPoppinsStyle(
                context,
                text,
                12.5,
                AppColors.greyS700,
                FontWeight.w400,
                999,
                TextAlign.left,
                1.6,
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _descExpanded ? 'Read Less' : 'Read More',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _green),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _descExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: _green,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Instructor Card ─────────────────────────────────────────────────────────
  Widget _instructorCard() {
    final name = _currentMaterial!.coaching_name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'I';
    final profileIcon = _currentMaterial!.profile_icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient:
                    (profileIcon == null || profileIcon.isEmpty) ? const LinearGradient(colors: [_green, _navy]) : null,
                image:
                    (profileIcon != null && profileIcon.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(profileIcon), fit: BoxFit.cover)
                        : null,
              ),
              child:
                  (profileIcon == null || profileIcon.isEmpty)
                      ? Center(
                        child: Text(
                          initial,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructor',
                    style: TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 3),
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navy)),
                  if (_currentMaterial!.coaching_bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Html(data: _currentMaterial!.coaching_bio),
                  ],
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_rounded, size: 12, color: _green),
                        SizedBox(width: 5),
                        Text(
                          'Verified Instructor',
                          style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAQ Section ─────────────────────────────────────────────────────────────
  Widget _faqSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  const Text('FAQs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_faqs.length, (i) => _faqItem(i)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(int index) {
    final isOpen = _faqExpanded[index];
    return Column(
      children: [
        if (index > 0) Divider(height: 1, color: _borderCol, indent: 16, endIndent: 16),
        InkWell(
          onTap: () {
            setState(() {
              _faqExpanded[index] = !_faqExpanded[index];
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _faqs[index]['q']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOpen ? _green : _navy,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: isOpen ? _green : _textMuted, size: 22),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _greenBorder.withOpacity(0.5)),
              ),
              child: Text(_faqs[index]['a']!, style: const TextStyle(fontSize: 12, color: _navy, height: 1.6)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Bar ──────────────────────────────────────────────────────────────
  Widget _bottomBar(bool canStart) {
    if (canStart) {
      return Container(
        decoration: BoxDecoration(
          color: _cardBg,
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -6))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_green, _navy]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 7))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _handleStartLearning,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_filled, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start Learning',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Dynamic package bottom bar ──────────────────────────────────────────
    final pkg = _selectedPackage;
    final String originalPrice = _isFree ? '₹0' : (pkg != null ? '₹${pkg.oldPrice.toStringAsFixed(0)}' : '₹999');
    final String finalPrice = _isFree ? '₹0' : (pkg != null ? '₹${pkg.price.toStringAsFixed(0)}' : '₹59');
    final int discountPct = pkg?.discountPercent ?? 0;
    final String buttonLabel = _isFree ? 'Get Free Access' : (pkg != null ? 'Get ${pkg.name} Pass' : 'Get Basic Pass');

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Offer strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, _navy],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Text('% ', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800)),
                  const Text(
                    'Exclusive Offer ',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const Text('😍', style: TextStyle(fontSize: 13)),
                  if (!_isFree && discountPct > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$discountPct% OFF',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Package switcher chip
                  if (_packages.length > 1)
                    GestureDetector(
                      onTap: _showPackagePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          border: Border.all(color: Colors.white.withOpacity(0.6)),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${pkg!.name} - Change Plan',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Price + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!_isFree) ...[
                            Text(
                              originalPrice,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textMuted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: _textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            finalPrice,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      if (pkg != null)
                        Text(
                          '${pkg.validityDays} days validity',
                          style: const TextStyle(fontSize: 10, color: _textMuted),
                        ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_green, _navy]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: _green.withOpacity(0.38), blurRadius: 18, offset: const Offset(0, 7)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _handleSubscribe();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                buttonLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error Screen ─────────────────────────────────────────────────────────────
  Widget _errorScreen() {
    IconData errorIcon;
    String headline, subtext;
    Color iconColor, iconBg;
    switch (_errorType) {
      case 'no_internet':
        errorIcon = Icons.wifi_off_rounded;
        headline = 'No internet connection';
        subtext = 'Please check your connection\nand try again.';
        iconColor = const Color(0xFF1565C0);
        iconBg = const Color(0xFFE3F2FD);
        break;
      case 'timeout':
        errorIcon = Icons.timer_off_rounded;
        headline = 'Connection timed out';
        subtext = 'Server took too long to respond.\nPlease try again.';
        iconColor = const Color(0xFFE65100);
        iconBg = const Color(0xFFFFF3E0);
        break;
      case 'server':
        errorIcon = Icons.cloud_off_rounded;
        headline = 'Course could not be loaded';
        subtext = 'There was an issue fetching data.\nPlease try again.';
        iconColor = const Color(0xFF6A1B9A);
        iconBg = const Color(0xFFF3E5F5);
        break;
      case 'session':
        errorIcon = Icons.person_off_rounded;
        headline = 'Session expired';
        subtext = 'Please reopen the app\nor log in again.';
        iconColor = const Color(0xFFE53935);
        iconBg = const Color(0xFFFFEBEE);
        break;
      default:
        errorIcon = Icons.error_outline_rounded;
        headline = 'Something went wrong';
        subtext = 'We could not load the course.\nPlease try again.';
        iconColor = const Color(0xFF6B7A99);
        iconBg = const Color(0xFFF4F6FB);
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(errorIcon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 24),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _navy, height: 1.3),
              ),
              const SizedBox(height: 10),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textMuted, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _getUserData,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Try Again', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: _borderCol),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 2),
                TranslatedText(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, color: color, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _greenBorder.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _green.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: _green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: _navy.withOpacity(0.8), fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Package Picker Bottom Sheet ───────────────────────────────────────────────

class _PackagePickerSheet extends StatefulWidget {
  final List<PackageItem> packages;
  final PackageItem? selectedPackage;
  final ValueChanged<PackageItem> onSelect;
  final ValueChanged<PackageItem> onProceed;

  const _PackagePickerSheet({
    required this.packages,
    required this.selectedPackage,
    required this.onSelect,
    required this.onProceed,
  });

  @override
  State<_PackagePickerSheet> createState() => _PackagePickerSheetState();
}

class _PackagePickerSheetState extends State<_PackagePickerSheet> {
  late PackageItem _localSelected;

  static const _navy = Color(0xFF0A1628);
  static const _green = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE8F8F2);
  static const _greenBorder = Color(0xFF9FE1CB);
  static const _textMuted = Color(0xFF6B7A99);
  static const _borderCol = Color(0xFFE4E9F4);

  @override
  void initState() {
    super.initState();
    _localSelected = widget.selectedPackage ?? widget.packages.first;
  }

  Color _planColor(PackageItem pkg) => pkg.name.toLowerCase().contains('premium') ? const Color(0xFF6B4EE6) : _green;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDE3EE), borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_green, _navy]),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Plan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _navy),
                      ),
                      Text('Select a plan that fits you best', style: TextStyle(fontSize: 11, color: _textMuted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: const Color(0xFFF0F3F8), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, size: 16, color: _textMuted),
                  ),
                ),
              ],
            ),
          ),

          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(color: _borderCol)),

          // Package cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children:
                  widget.packages
                      .map(
                        (pkg) => Expanded(
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _packageCard(pkg)),
                        ),
                      )
                      .toList(),
            ),
          ),

          // Features comparison for selected
          if (_localSelected.features.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    child: Text(
                      'What\'s in ${_localSelected.name}?',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _localSelected.features.map((f) => _featureChip(f)).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Proceed button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_planColor(_localSelected), _navy]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _planColor(_localSelected).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onProceed(_localSelected);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Get ${_localSelected.name} — ₹${_localSelected.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(top: false, child: const SizedBox(height: 4)),
        ],
      ),
    );
  }

  Widget _packageCard(PackageItem pkg) {
    final isSelected = _localSelected.packageId == pkg.packageId;
    final color = _planColor(pkg);
    final isPremium = pkg.name.toLowerCase().contains('premium');

    return GestureDetector(
      onTap: () {
        setState(() => _localSelected = pkg);
        widget.onSelect(pkg);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : _borderCol, width: isSelected ? 2 : 1),
          boxShadow:
              isSelected ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    pkg.name.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.6),
                  ),
                ),
                if (isPremium) ...[const SizedBox(width: 4), Icon(Icons.workspace_premium, size: 14, color: color)],
              ],
            ),
            const SizedBox(height: 10),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${pkg.price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _navy, height: 1),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '₹${pkg.oldPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                if (pkg.discountPercent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      '${pkg.discountPercent}% off',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Validity
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 10, color: _textMuted),
                const SizedBox(width: 4),
                Text('${pkg.validityDays} days', style: const TextStyle(fontSize: 10, color: _textMuted)),
              ],
            ),
            const SizedBox(height: 10),

            // Radio indicator
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? color : _borderCol, width: 1.5),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 11) : null,
                ),
                const SizedBox(width: 6),
                Text(
                  isSelected ? 'Selected' : 'Select',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? color : _textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(PackageFeature feature) {
    final included = feature.isIncluded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: included ? _greenLight : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: included ? _greenBorder.withOpacity(0.6) : Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            included ? Icons.check_rounded : Icons.close_rounded,
            size: 12,
            color: included ? _green : Colors.redAccent,
          ),
          const SizedBox(width: 5),
          Text(
            feature.text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: included ? _green : _textMuted,
              decoration: included ? null : TextDecoration.lineThrough,
              decorationColor: _textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _ChipData {
  final String label;
  final IconData icon;
  final Color color;
  const _ChipData(this.label, this.icon, this.color);
}

class _SectionData {
  final String title, subtitle, emoji;
  final Color color, borderColor, iconBg, textColor;
  final VoidCallback onTap;
  const _SectionData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.borderColor,
    required this.iconBg,
    required this.textColor,
    required this.onTap,
  });
}
