import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  bool _showCouponField = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _couponController = TextEditingController();

  // Product/Course Data
  final Map<String, dynamic> _orderData = {
    'itemName': 'Complete Mathematics Course',
    'itemType': 'Premium Course',
    'originalPrice': 4999,
    'discount': 50,
    'discountedPrice': 2499,
    'couponDiscount': 0,
    'tax': 449,
    'totalAmount': 2948,
    'features': ['45 Video Lessons', 'Lifetime Access', 'Certificate', 'Expert Support'],
  };

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    if (_couponController.text.isNotEmpty) {
      // Sample coupon validation
      if (_couponController.text.toUpperCase() == 'SAVE100') {
        setState(() {
          _orderData['couponDiscount'] = 100;
          _orderData['totalAmount'] = _orderData['discountedPrice'] + _orderData['tax'] - 100;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon applied successfully! ₹100 off'),
            backgroundColor: AppColors.tealGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid coupon code'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _processPayment() {
    setState(() => _isProcessing = true);

    Future.delayed(Duration(seconds: 3), () {
      setState(() => _isProcessing = false);
      _showPaymentSuccessDialog();
    });
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: AppColors.white, size: 48),
                  ),
                  SizedBox(height: 24),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Payment Successful!',
                    22,
                    AppColors.darkNavy,
                    FontWeight.w800,
                    2,
                    TextAlign.center,
                    0.0,
                  ),
                  SizedBox(height: 12),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'You now have access to the course',
                    14,
                    AppColors.greyS600,
                    FontWeight.w500,
                    2,
                    TextAlign.center,
                    0.0,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: AppRichText.setTextPoppinsStyle(
                          context,
                          'Start Learning',
                          16,
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
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
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
      bottomNavigationBar: _buildBottomBar(),
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
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.lightGold, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.shopping_bag, color: AppColors.darkNavy, size: 20),
          ),
          SizedBox(width: 12),
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
                        _orderData['itemName'],
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
                          _orderData['itemType'],
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
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _orderData['features'].map<Widget>((feature) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.greyS1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyS300!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.tealGreen),
                        SizedBox(width: 6),
                        AppRichText.setTextPoppinsStyle(
                          context,
                          feature,
                          12,
                          AppColors.darkNavy,
                          FontWeight.w600,
                          1,
                          TextAlign.left,
                          0.0,
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.greyS1, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildPriceRow('Original Price', '₹${_orderData['originalPrice']}', false),
                SizedBox(height: 12),
                _buildPriceRow(
                  'Discount (${_orderData['discount']}%)',
                  '- ₹${_orderData['originalPrice'] - _orderData['discountedPrice']}',
                  false,
                  color: AppColors.tealGreen,
                ),
                if (_orderData['couponDiscount'] > 0) ...[
                  SizedBox(height: 12),
                  _buildPriceRow(
                    'Coupon Discount',
                    '- ₹${_orderData['couponDiscount']}',
                    false,
                    color: AppColors.tealGreen,
                  ),
                ],
                SizedBox(height: 12),
                _buildPriceRow('Tax & Fees', '₹${_orderData['tax']}', false),
                SizedBox(height: 16),
                Container(height: 1, color: AppColors.greyS300),
                SizedBox(height: 16),
                _buildPriceRow('Total Amount', '₹${_orderData['totalAmount']}', true),
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
          if (_showCouponField) ...[
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
                  onPressed: _applyCoupon,
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
                      child: AppRichText.setTextPoppinsStyle(
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
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGold.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.tealGreen, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: AppRichText.setTextPoppinsStyle(
                    context,
                    'Use code SAVE100 for ₹100 off',
                    12,
                    AppColors.darkNavy,
                    FontWeight.w600,
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
    );
  }

  Widget _buildBottomBar() {
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
                      '₹${_orderData['totalAmount']}',
                      25,
                      AppColors.darkNavy,
                      FontWeight.w900,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
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
                        'Saved ₹${_orderData['originalPrice'] - _orderData['discountedPrice'] + _orderData['couponDiscount']}',
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
