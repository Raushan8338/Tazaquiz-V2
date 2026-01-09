import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupi.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupipayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
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

  const CheckoutPage({Key? key, required this.contentType, required this.contentId}) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  bool _showCouponField = false;
  bool _isLoadingCheckout = true;
  bool _isApplyingCoupon = false;

  CheckoutModel? checkoutData;
  CheckoutModel? originalCheckoutData;
  CFEnvironment environment = CFEnvironment.PRODUCTION;

  // Store coupon details separately
  String? appliedCouponCode;
  double? couponDiscount;

  final TextEditingController _couponController = TextEditingController();

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    await _getUserData();
    await fetchCheckoutDetails();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
  }

  Future<void> fetchCheckoutDetails() async {
    try {
      setState(() => _isLoadingCheckout = true);

      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': _user?.id, 'content_type': widget.contentType, 'content_id': widget.contentId};

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
          // Extract coupon code
          appliedCouponCode = jsonResponse['coupon_code']?.toString() ?? '';

          // Parse discount safely
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.tealGreen, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {
      'user_id': _user?.id,
      'product_id': widget.contentId,
      'product_type': widget.contentType,
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

        // Proceed with Cashfree payment using orderId
        _startCashfreePayment(orderId, paymentLink, cfToken);
      } else {
        _showErrorSnackbar('Failed to create payment order');
      }

      setState(() => _isProcessing = true);

      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentFailedPage()));
    }
  }

  void _startCashfreePayment(String orderId, String paymentlink, String cfToken) {
    // Implement Cashfree payment integration here
    // On successful payment, call _showPaymentSuccessDialog()
    try {
      final service = CFPaymentGatewayService();
      service.setCallback(_verifyPayment, onError);
      var session = createSession(orderId, cfToken);

      if (session == null) {
        return;
      }
      // final cfPaymentService = CFPaymentGatewayService();

      // final payment = CFDropCheckoutPaymentBuilder().setSession(session).build();

      // cfPaymentService.doPayment(payment);

      var upi = CFUPIBuilder().setChannel(CFUPIChannel.INTENT_WITH_UI).build();
      var upiPayment = CFUPIPaymentBuilder().setSession(session).setUPI(upi).build();

      service.doPayment(upiPayment);
    } catch (e) {}
  }

  CFSession? createSession(String orderId, String cfToken) {
    try {
      String oid = orderId;
      var session = CFSessionBuilder().setEnvironment(environment).setOrderId(oid).setPaymentSessionId(cfToken).build();
      return session;
    } catch (e) {}
    return null;
  }

  void onError(CFErrorResponse errorResponse, String orderId) {}

  void _verifyPayment(String orderId) async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'order_id': orderId};

    final responseCreate = await authRepository.savePaymentStatus(data);

    if (responseCreate.statusCode == 200) {
      // ✅ Parse response
      final resp = responseCreate.data;

      if (resp['success'] == true && resp['order_status'] == 'PAID') {
        // Payment Success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => PaymentStatusScreen(
                  amount: resp['cf_response']?['order_amount'].toString() ?? '',
                  status: PaymentStatus.success,
                  orderId: resp['payment_id'].toString() ?? '',
                  paymentMethod: resp['payment_method'].toString() ?? '',
                ),
          ),
        );
      } else {
        // Payment Failed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => PaymentStatusScreen(
                  amount: resp['cf_response']?['order_amount'].toString() ?? '',
                  status: PaymentStatus.failed,
                  orderId: resp['payment_id'].toString() ?? '',
                  paymentMethod: resp['payment_method'].toString() ?? '',
                ),
          ),
        );
      }
    } else {
      //  Optional: show failed page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => PaymentStatusScreen(
                orderId: 'null',
                amount: 'null',
                paymentMethod: 'null',
                status: PaymentStatus.failed,
              ),
        ),
      );
    }
  }

  // Calculate price after discount (base price - discount)
  double _getPriceAfterDiscount() {
    if (originalCheckoutData == null) return 0;
    if (couponDiscount == null) return originalCheckoutData!.basePrice;
    return originalCheckoutData!.basePrice - couponDiscount!;
  }

  // Calculate GST on discounted price
  double _getGstAmount() {
    if (originalCheckoutData == null) return 0;
    final priceAfterDiscount = _getPriceAfterDiscount();
    return (priceAfterDiscount * originalCheckoutData!.gstRate) / 100;
  }

  // Calculate final total
  double _getFinalPrice() {
    final priceAfterDiscount = _getPriceAfterDiscount();
    final gstAmount = _getGstAmount();
    return priceAfterDiscount + gstAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body:
          _isLoadingCheckout
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.tealGreen)))
              : checkoutData == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.greyS500),
                    SizedBox(height: 16),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Failed to load checkout details',
                      16,
                      AppColors.greyS600,
                      FontWeight.w600,
                      1,
                      TextAlign.center,
                      0.0,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(onPressed: fetchCheckoutDetails, child: Text('Retry')),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    _buildOrderSummary(),
                    SizedBox(height: 16),
                    _buildCouponSection(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
      bottomNavigationBar: checkoutData != null ? _buildBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
        ),
      ),
      title: Row(
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Checkout',
            18,
            AppColors.white,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    if (checkoutData == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long, color: AppColors.lightGold, size: 18),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Order Summary',
                16,
                AppColors.darkNavy,
                FontWeight.w800,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealGreen.withOpacity(0.1), AppColors.darkNavy.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.tealGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: AppColors.white, size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        checkoutData!.title,
                        14,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        2,
                        TextAlign.left,
                        0.0,
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGold.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppRichText.setTextPoppinsStyle(
                          context,
                          checkoutData!.contentType,
                          11,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildPriceRow('Base Price', '₹${originalCheckoutData!.basePrice.toStringAsFixed(2)}', false),

                // Show discount right after base price
                if (appliedCouponCode != null && couponDiscount != null) ...[
                  SizedBox(height: 12),
                  _buildPriceRow(
                    'Discount ($appliedCouponCode)',
                    '- ₹${couponDiscount!.toStringAsFixed(2)}',
                    false,
                    color: AppColors.tealGreen,
                  ),
                  SizedBox(height: 12),
                  _buildPriceRow(
                    'Price after Discount',
                    '₹${_getPriceAfterDiscount().toStringAsFixed(2)}',
                    false,
                    color: AppColors.darkNavy,
                  ),
                ],

                SizedBox(height: 12),
                _buildPriceRow(
                  'GST (${originalCheckoutData!.gstRate}%)',
                  '₹${_getGstAmount().toStringAsFixed(2)}',
                  false,
                ),
                SizedBox(height: 16),
                Container(height: 1, color: AppColors.greyS300),
                SizedBox(height: 16),
                _buildPriceRow('Total Amount', '₹${_getFinalPrice().toStringAsFixed(2)}', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isBold, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          isBold ? 16 : 14,
          color ?? (isBold ? AppColors.darkNavy : AppColors.greyS700),
          isBold ? FontWeight.w800 : FontWeight.w600,
          1,
          TextAlign.left,
          0.0,
        ),
        AppRichText.setTextPoppinsStyle(
          context,
          value,
          isBold ? 20 : 15,
          color ?? (isBold ? AppColors.darkNavy : AppColors.greyS800),
          isBold ? FontWeight.w900 : FontWeight.w700,
          1,
          TextAlign.left,
          0.0,
        ),
      ],
    );
  }

  Widget _buildCouponSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_offer, color: AppColors.darkNavy, size: 18),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Have a Coupon Code?',
                16,
                AppColors.darkNavy,
                FontWeight.w800,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
          SizedBox(height: 16),
          if (appliedCouponCode != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.tealGreen.withOpacity(0.15), AppColors.darkNavy.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tealGreen, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.tealGreen, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.check_circle, color: AppColors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Coupon Applied: $appliedCouponCode',
                          14,
                          AppColors.darkNavy,
                          FontWeight.w700,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                        SizedBox(height: 4),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'You saved ₹${couponDiscount!.toStringAsFixed(2)}',
                          12,
                          AppColors.tealGreen,
                          FontWeight.w600,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close, color: Colors.red), onPressed: _removeCoupon),
                ],
              ),
            ),
          ] else if (_showCouponField) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: TextStyle(color: AppColors.greyS500, fontSize: 14),
                      prefixIcon: Icon(Icons.discount, color: AppColors.tealGreen, size: 20),
                      filled: true,
                      fillColor: AppColors.greyS1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.greyS300!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.greyS300!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.tealGreen, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isApplyingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.transparent,
                    shadowColor: AppColors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child:
                          _isApplyingCoupon
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                                ),
                              )
                              : AppRichText.setTextPoppinsStyle(
                                context,
                                'Apply',
                                14,
                                AppColors.white,
                                FontWeight.w700,
                                1,
                                TextAlign.center,
                                0.0,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            InkWell(
              onTap: () {
                setState(() {
                  _showCouponField = true;
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealGreen.withOpacity(0.1), AppColors.darkNavy.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.tealGreen.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.tealGreen, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Click here to apply coupon code',
                        14,
                        AppColors.darkNavy,
                        FontWeight.w600,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyS600),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (checkoutData == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Total Amount',
                      13,
                      AppColors.greyS600,
                      FontWeight.normal,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 4),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '₹${_getFinalPrice().toStringAsFixed(2)}',
                      25,
                      AppColors.darkNavy,
                      FontWeight.w900,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
                if (appliedCouponCode != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer, size: 16, color: AppColors.tealGreen),
                        SizedBox(width: 6),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          'Saved ₹${couponDiscount!.toStringAsFixed(2)}',
                          12,
                          AppColors.tealGreen,
                          FontWeight.w700,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transparent,
                  shadowColor: AppColors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child:
                        _isProcessing
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(AppColors.white),
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, color: AppColors.white, size: 20),
                                SizedBox(width: 12),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  'Proceed to Pay',
                                  16,
                                  AppColors.white,
                                  FontWeight.w700,
                                  1,
                                  TextAlign.left,
                                  0.0,
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
    );
  }
}
