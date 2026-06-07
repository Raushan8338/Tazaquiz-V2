import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupi.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupipayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/checkout_model.dart';
import 'package:tazaquiznew/models/coupon_apply_model.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/payment_response.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class CheckoutPage extends StatefulWidget {
  final String contentType;
  final String contentId;
  final String package_id;

  const CheckoutPage({Key? key, required this.contentType, required this.contentId, required this.package_id})
    : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with WidgetsBindingObserver {
  bool _isProcessing = false;
  bool _showCouponField = false;
  bool _isLoadingCheckout = true;
  bool _isApplyingCoupon = false;
  bool _isWebCheckoutOpen = false;

  CheckoutModel? checkoutData;
  CheckoutModel? originalCheckoutData;
  CFEnvironment environment = CFEnvironment.PRODUCTION;

  String? appliedCouponCode;
  double? couponDiscount;

  final TextEditingController _couponController = TextEditingController();

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _getUserData();
    await fetchCheckoutDetails();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
  }

  Future<void> fetchCheckoutDetails() async {
    try {
      setState(() => _isLoadingCheckout = true);
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'user_id': _user?.id,
        'content_type': widget.contentType,
        'content_id': widget.contentId,
        'package_id': widget.package_id,
      };
      final response = await authRepository.fetchCheckoutDetails(data);
      if (response.statusCode == 200) {
        final jsonResponse = response.data is String ? jsonDecode(response.data) : response.data;
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          checkoutData = CheckoutModel.fromJson(jsonResponse['data']);
          originalCheckoutData = checkoutData;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load checkout details');
    } finally {
      setState(() => _isLoadingCheckout = false);
    }
  }

  Future<void> _applyCoupon() async {
    if (_couponController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter a coupon code');
      return;
    }
    try {
      setState(() => _isApplyingCoupon = true);
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {
        'user_id': _user?.id,
        'coupon_code': _couponController.text.trim().toUpperCase(),
        'order_id': widget.contentId,
        'final_price': originalCheckoutData?.finalPrice.toString(),
      };
      final response = await authRepository.applyCoupon(data);
      if (response.statusCode == 200) {
        final jsonResponse = response.data is String ? jsonDecode(response.data) : response.data;
        if (jsonResponse['success'] == true) {
          appliedCouponCode = jsonResponse['coupon_code']?.toString() ?? '';
          final discountValue = jsonResponse['discount'];
          if (discountValue != null) {
            couponDiscount = double.parse(discountValue.toString());
          }
          _showSuccessSnackbar('Coupon applied successfully!');
          setState(() {});
        } else {
          throw Exception('Coupon not valid');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Invalid coupon code');
    } finally {
      setState(() => _isApplyingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      appliedCouponCode = null;
      couponDiscount = null;
      _couponController.clear();
      _showCouponField = false;
    });
    _showSuccessSnackbar('Coupon removed');
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: TranslatedText(message)),
        ]),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: TranslatedText(message)),
        ]),
        backgroundColor: AppColors.tealGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── EXACT SAME LOGIC AS ORIGINAL ─────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWebCheckoutOpen) {
      _isWebCheckoutOpen = false;
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _processPayment() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    setState(() => _isProcessing = true);
    final data = {
      'user_id': _user?.id,
      'product_id': widget.contentId,
      'product_type': widget.contentType,
      'package_id': widget.package_id,
      'amount': _getFinalPrice().toStringAsFixed(2),
      'name': _user?.username,
      'email': _user?.email,
      'phone': _user?.phone,
    };

    final responseCreate = await authRepository.createPaymentOrder(data);

    if (responseCreate.statusCode == 200) {
      final jsonResponse = responseCreate.data is String ? jsonDecode(responseCreate.data) : responseCreate.data;

      if (jsonResponse['success'] == true) {
        String orderId = jsonResponse['order_id'];
        String paymentLink = jsonResponse['payment_link'];
        String cfToken = jsonResponse['payment_session_id'];
        String payMode = jsonResponse['PAYmode'] ?? '0';
        _startCashfreePayment(orderId, paymentLink, cfToken, payMode);
      } else {
        setState(() => _isProcessing = false);
        _showErrorSnackbar('Failed to create payment order');
      }
    }
  }

  void _startCashfreePayment(String orderId, String paymentlink, String cfToken, String payMode) {
    try {
      final service = CFPaymentGatewayService();
      service.setCallback(_verifyPayment, onError);
      var session = createSession(orderId, cfToken);

      if (session == null) {
        return;
      }

      if (payMode == "0") {
        var upi = CFUPIBuilder().setChannel(CFUPIChannel.INTENT_WITH_UI).build();
        var upiPayment = CFUPIPaymentBuilder().setSession(session).setUPI(upi).build();
        service.doPayment(upiPayment);
      } else {
        _isWebCheckoutOpen = true;
        var cfWebCheckout = CFWebCheckoutPaymentBuilder().setSession(session).build();
        service.doPayment(cfWebCheckout);
      }
    } catch (e) {
      _showErrorSnackbar('Payment failed to start');
    }
  }

  CFSession? createSession(String orderId, String cfToken) {
    try {
      String oid = orderId;
      var session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(oid)
          .setPaymentSessionId(cfToken)
          .build();
      return session;
    } catch (e) {}
    return null;
  }

  void onError(CFErrorResponse errorResponse, String orderId) async {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
    final String combinedError =
        "Message: ${errorResponse.getMessage()}, "
        "Status: ${errorResponse.getStatus()}, "
        "Type: ${errorResponse.getType()}";
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'error_message': combinedError, 'order_id': orderId, 'user_id': _user?.id};
    final responseCreate = await authRepository.save_CF_error_response(data);
  }

  void _verifyPayment(String orderId) async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'order_id': orderId};
    try {
      final responseCreate = await authRepository.savePaymentStatus(data);
      final Map<String, dynamic> resp = Map<String, dynamic>.from(responseCreate.data);
      if (resp['success'] == true && resp['order_status'] == 'PAID') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              amount: resp['cf_response']?['order_amount']?.toString() ?? '',
              status: PaymentStatus.success,
              orderId: resp['payment_id']?.toString() ?? '',
              paymentMethod: resp['payment_method']?.toString() ?? '',
            ),
          ),
        );
      } 
      else if (resp['order_status'] == 'PENDING') {
        // ✅ Pending dikhao — webhook handle karega
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              amount: resp['cf_response']?['order_amount']?.toString() ?? '',
              status: PaymentStatus.pending,
              orderId: resp['payment_id']?.toString() ?? '',
              paymentMethod: resp['payment_method']?.toString() ?? '',
            ),
          ),
        );
      }
      else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              amount: resp['cf_response']?['order_amount']?.toString() ?? '',
              status: PaymentStatus.failed,
              orderId: resp['payment_id']?.toString() ?? '',
              paymentMethod: resp['payment_method']?.toString() ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              orderId: orderId,
              amount: '',
              paymentMethod: '',
              status: PaymentStatus.failed,
            ),
          ),
        );
      }
    }
  }

  double _getPriceAfterDiscount() {
    if (originalCheckoutData == null) return 0;
    if (couponDiscount == null) return originalCheckoutData!.basePrice;
    return originalCheckoutData!.basePrice - couponDiscount!;
  }

  double _getGstAmount() {
    if (originalCheckoutData == null) return 0;
    final priceAfterDiscount = _getPriceAfterDiscount();
    return (priceAfterDiscount * originalCheckoutData!.gstRate) / 100;
  }

  double _getFinalPrice() {
    final priceAfterDiscount = _getPriceAfterDiscount();
    final gstAmount = _getGstAmount();
    return priceAfterDiscount + gstAmount;
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD — sirf UI changes hain yahan se
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body: _isLoadingCheckout
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Loading checkout...',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.greyS600,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
              ]),
            )
          : checkoutData == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.red.shade300),
                      ),
                      const SizedBox(height: 20),
                      const Text('Failed to Load',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 8),
                      Text('Could not load checkout details.',
                          style: TextStyle(fontSize: 13, color: AppColors.greyS600)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: fetchCheckoutDetails,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Retry',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFamily: 'Poppins')),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(children: [
                    const SizedBox(height: 16),
                    _buildOrderSummary(),
                    const SizedBox(height: 16),
                    _buildCouponSection(),
                    const SizedBox(height: 100),
                  ]),
                ),
      bottomNavigationBar: checkoutData != null ? _buildBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)],
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Checkout',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins')),
          Text('Secure Payment',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10,
                  fontFamily: 'Poppins')),
        ]),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text('SSL',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ]),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    if (checkoutData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(children: [
        Container(
          height: 5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Order Summary',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                      fontFamily: 'Poppins')),
            ]),

            const SizedBox(height: 16),

            // Product card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.tealGreen.withOpacity(0.15), width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(checkoutData!.title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                            fontFamily: 'Poppins',
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.tealGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(checkoutData!.description,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tealGreen,
                              fontFamily: 'Poppins'),
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Price breakdown
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                _buildPriceRow(
                    'Base Price',
                    '₹${originalCheckoutData!.basePrice.toStringAsFixed(2)}',
                    false),

                if (appliedCouponCode != null && couponDiscount != null) ...[
                  const SizedBox(height: 12),
                  _buildPriceRow(
                    'Discount ($appliedCouponCode)',
                    '- ₹${couponDiscount!.toStringAsFixed(2)}',
                    false,
                    color: AppColors.tealGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow(
                    'Price after Discount',
                    '₹${_getPriceAfterDiscount().toStringAsFixed(2)}',
                    false,
                    color: AppColors.darkNavy,
                  ),
                ],

                const SizedBox(height: 12),
                _buildPriceRow(
                  'GST (${originalCheckoutData!.gstRate}%)',
                  '₹${_getGstAmount().toStringAsFixed(2)}',
                  false,
                ),

                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 14),

                // Total highlighted
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Poppins')),
                        Text('₹${_getFinalPrice().toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Poppins')),
                      ]),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isBold, {Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? (isBold ? AppColors.darkNavy : AppColors.greyS700),
              fontFamily: 'Poppins')),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color != null
              ? color.withOpacity(0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(value,
            style: TextStyle(
                fontSize: isBold ? 20 : 13,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: color ?? (isBold ? AppColors.darkNavy : AppColors.greyS800),
                fontFamily: 'Poppins')),
      ),
    ]);
  }

  Widget _buildCouponSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_offer_rounded,
                  color: Color(0xFFD97706), size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Have a Coupon Code?',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                    fontFamily: 'Poppins')),
          ]),

          const SizedBox(height: 14),

          if (appliedCouponCode != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tealGreen.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.tealGreen.withOpacity(0.3), width: 1.5),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Coupon Applied: $appliedCouponCode',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 3),
                    Text('You saved ₹${couponDiscount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tealGreen,
                            fontFamily: 'Poppins')),
                  ]),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.red.shade400, size: 16),
                  ),
                ),
              ]),
            ),
          ] else if (_showCouponField) ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: TextStyle(
                        color: AppColors.greyS400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0),
                    prefixIcon: const Icon(Icons.discount_outlined,
                        color: AppColors.tealGreen, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.tealGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isApplyingCoupon ? null : _applyCoupon,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF0D4B3B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Apply',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Poppins')),
                ),
              ),
            ]),
          ] else ...[
            GestureDetector(
              onTap: () => setState(() => _showCouponField = true),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.tealGreen.withOpacity(0.2), width: 1.5),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Click here to apply coupon code',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy,
                            fontFamily: 'Poppins')),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.greyS500),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (checkoutData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Payable',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.greyS500,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 2),
              Text('₹${_getFinalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkNavy,
                      fontFamily: 'Poppins')),
            ]),
            if (appliedCouponCode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.savings_outlined,
                      size: 14, color: AppColors.tealGreen),
                  const SizedBox(width: 5),
                  Text('Saved ₹${couponDiscount!.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealGreen,
                          fontFamily: 'Poppins')),
                ]),
              ),
          ]),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: _isProcessing ? null : _processPayment,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: _isProcessing
                    ? LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500])
                    : const LinearGradient(
                        colors: [Color(0xFF0A1628), Color(0xFF0D4B3B)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isProcessing
                    ? []
                    : [
                        BoxShadow(
                            color: const Color(0xFF0D4B3B).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5)),
                      ],
              ),
              child: Center(
                child: _isProcessing
                    ? const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white)),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Poppins')),
                      ])
                    : const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('Proceed to Pay',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Poppins')),
                      ]),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.flash_on_rounded, size: 11, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text('Powered by Cashfree Payments',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontFamily: 'Poppins')),
          ]),
        ]),
      ),
    );
  }
}