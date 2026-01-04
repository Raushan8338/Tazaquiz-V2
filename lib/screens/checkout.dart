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
   //hyggtt
  int _selectedPaymentMethod = 0;
  bool _saveCard = false;
  bool _isProcessing = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Product/Course Data
  final Map<String, dynamic> _orderData = {
    'itemName': 'Complete Mathematics Course',
    'itemType': 'Premium Course',
    'originalPrice': 4999,
    'discount': 50,
    'discountedPrice': 2499,
    'tax': 449,
    'totalAmount': 2948,
    'features': [
      '45 Video Lessons',
      'Lifetime Access',
      'Certificate',
      'Expert Support',
    ],
  };

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'description': 'Pay securely with card',
    },
    {
      'name': 'UPI',
      'icon': Icons.account_balance_wallet,
      'description': 'Pay via UPI apps',
    },
    {
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'description': 'All major banks supported',
    },
    {
      'name': 'Wallet',
      'icon': Icons.wallet,
      'description': 'Paytm, PhonePe, etc.',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      
      Future.delayed(Duration(seconds: 3), () {
        setState(() => _isProcessing = false);
        _showSuccessDialog();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealGreen, AppColors.darkNavy],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: AppColors.lightGold, size: 48),
              ),
              SizedBox(height: 24),
              AppRichText.setTextPoppinsStyle(context, 'Payment Successful!', 24, AppColors.darkNavy, FontWeight.w900, 1, TextAlign.left, 0.0),
           
              SizedBox(height: 12),
              AppRichText.setTextPoppinsStyle(context, 'Your order has been confirmed', 14, AppColors.greyS600, FontWeight.normal, 1, TextAlign.center, 0.0),

           
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lightGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightGold),
                ),
                child:  AppRichText.setTextPoppinsStyle(context, 'Order ID: #OD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', 12, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0.0),

             
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.transparent,
                    shadowColor: AppColors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.tealGreen, AppColors.darkNavy],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: AppRichText.setTextPoppinsStyle(context, 'View Order Details', 16, AppColors.white, FontWeight.w700, 1, TextAlign.left, 0.0),

                     
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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildOrderSummary(),
              
                _buildPaymentMethods(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                 Positioned(
                right: -50,
                top: 20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
             
                Padding(
                  padding: EdgeInsets.only(left: 60, right: 60, top: 40),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.shopping_bag, color: AppColors.darkNavy, size: 20),
                      ),
                      SizedBox(width: 16),
                      AppRichText.setTextPoppinsStyle(context, 'Checkout', 18, AppColors.white, FontWeight.w900, 1, TextAlign.left, 0.0),
                
                    
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealGreen, AppColors.darkNavy],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long, color: AppColors.lightGold, size: 18),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(context, 'Order Summary', 16, AppColors.darkNavy, FontWeight.w800, 1, TextAlign.left, 0.0),

         
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.tealGreen.withOpacity(0.1),
                  AppColors.darkNavy.withOpacity(0.05),
                ],
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
                    gradient: LinearGradient(
                      colors: [AppColors.tealGreen, AppColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: AppColors.white, size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(context, _orderData['itemName'], 14, AppColors.darkNavy, FontWeight.w700, 5, TextAlign.left, 0.0),

                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGold.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppRichText.setTextPoppinsStyle(context, _orderData['itemType'], 11, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0.0),

                    
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
            children: _orderData['features'].map<Widget>((feature) {
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
                    AppRichText.setTextPoppinsStyle(context, feature, 12, AppColors.darkNavy, FontWeight.w600, 1, TextAlign.left, 0.0),
                
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greyS1,
              borderRadius: BorderRadius.circular(12),
            ),
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
                SizedBox(height: 12),
                _buildPriceRow('Tax & Fees', '₹${_orderData['tax']}', false),
                SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.greyS300,
                ),
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
        AppRichText.setTextPoppinsStyle(context, label, isBold ? 16 : 14,  color ?? (isBold ? AppColors.darkNavy : AppColors.greyS700), isBold ? FontWeight.w800 : FontWeight.w600, 1, TextAlign.left, 0.0),

        AppRichText.setTextPoppinsStyle(context, value, isBold ? 20 : 15, color ?? (isBold ? AppColors.darkNavy : AppColors.greyS800), isBold ? FontWeight.w900 : FontWeight.w700, 1, TextAlign.left, 0.0),

   
      ],
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.darkNavy,
      ),
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.greyS600,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.tealGreen, size: 20),
        filled: true,
        fillColor: AppColors.greyS1,
        counterText: '',
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.red),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightGold, AppColors.lightGoldS2],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payment, color: AppColors.darkNavy, size: 20),
              ),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(context, 'Payment Method', 16, AppColors.darkNavy, FontWeight.w800, 1, TextAlign.left, 0.0),

             
            ],
          ),
          SizedBox(height: 20),
          Column(
            children: List.generate(_paymentMethods.length, (index) {
              final method = _paymentMethods[index];
              final isSelected = _selectedPaymentMethod == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = index;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.tealGreen.withOpacity(0.1),
                              AppColors.darkNavy.withOpacity(0.05),
                            ],
                          )
                        : null,
                    color: isSelected ? null : AppColors.greyS1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.tealGreen : AppColors.greyS300!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.tealGreen.withOpacity(0.2)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          method['icon'],
                          color: isSelected ? AppColors.tealGreen : AppColors.greyS600,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppRichText.setTextPoppinsStyle(context, method['name'], 13, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0.0),

                         
                            SizedBox(height: 2),
                            AppRichText.setTextPoppinsStyle(context, method['description'], 12, AppColors.greyS600, FontWeight.normal, 1, TextAlign.left, 0.0),

                      
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.tealGreen : AppColors.greyS400,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.tealGreen,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGold),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: AppColors.tealGreen, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child:  AppRichText.setTextPoppinsStyle(context, 'All transactions are secure and encrypted', 12, AppColors.darkNavy, FontWeight.w600, 1, TextAlign.left, 0.0),

          
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
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
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
                    AppRichText.setTextPoppinsStyle(context, 'Total Amount', 13, AppColors.greyS600, FontWeight.normal, 1, TextAlign.left, 0.0),
               
                    SizedBox(height: 4),
                    AppRichText.setTextPoppinsStyle(context, '₹${_orderData['totalAmount']}', 25, AppColors.darkNavy, FontWeight.w900, 1, TextAlign.left, 0.0),

                
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
                      AppRichText.setTextPoppinsStyle(context, 'Saved ₹${_orderData['originalPrice'] - _orderData['discountedPrice']}', 12, AppColors.tealGreen, FontWeight.w700, 1, TextAlign.left, 0.0),

                     
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transparent,
                  shadowColor: AppColors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.tealGreen, AppColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isProcessing
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(AppColors.white),
                            ),
                          )
                        : InkWell(
                          onTap: () {
                             _showPaymentSuccessDialog();
                          },
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, color: AppColors.white, size: 20),
                                SizedBox(width: 12),
                                AppRichText.setTextPoppinsStyle(context, 'Proceed to Pay', 16, AppColors.white, FontWeight.w700, 1, TextAlign.left, 0.0),
                          
                          
                              ],
                            ),
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

   void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                          TextAlign.left,
                          0.0), 
            
              SizedBox(height: 12),
              AppRichText.setTextPoppinsStyle(
                          context,
                         'You now have access to the course',
                          14,
                          AppColors.greyS600,
                          FontWeight.w800,
                          2,
                          TextAlign.center,
                          0.0), 
              
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigator.pop(context);
                  // Navigator.pop(context);
                
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
                    child:  AppRichText.setTextPoppinsStyle(
                          context,
                          'Start Learning',
                          16,
                          AppColors.white,
                          FontWeight.w700,
                          2,
                          TextAlign.center,
                          0.0),
                   
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


