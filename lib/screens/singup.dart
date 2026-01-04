import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/login.dart';
import 'package:tazaquiznew/screens/otpVerificationPage.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
   //hyggtt
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isLoading = false;
  bool _hasReferralCode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Authrepository authRepository = Authrepository(Api_Client.dio);

      setState(() => _isLoading = true);
      final data = {
        'mobile': _phoneController.text.trim(),
        'OTP': '',
        'name': '',
        'email': '',
        'device_id': '',
        'referalCode': '',
        'androidInfo': '',
      };
      //
      final responseFuture = await authRepository.signupVerifyOTP(data);
      print('Signup Response: ${responseFuture.data}');
      if (responseFuture.statusCode == 200) {
        setState(() => _isLoading = false);
        final Map<String, dynamic> dataRes = responseFuture.data;

        if (dataRes['status'] == 'OTP sent successfully!') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OTPBasedVerificationPage(
                    phoneNumber: _phoneController.text.trim(),
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    referalCode: _referralController.text.trim(),
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppRichText.setTextPoppinsStyle(
                context,
                'User Already Exists Or Invalid OTP',
                12,
                AppColors.white,
                FontWeight.normal,
                1,
                TextAlign.left,
                0.0,
              ),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppRichText.setTextPoppinsStyle(
              context,
              'Error Occured. Please try again.',
              12,
              AppColors.white,
              FontWeight.normal,
              1,
              TextAlign.left,
              0.0,
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(children: [_buildTopIllustration(), Expanded(child: _buildRegistrationForm())]),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildPhoneField(),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _hasReferralCode,
                    onChanged: (value) {
                      setState(() {
                        _hasReferralCode = value ?? false;
                        if (!_hasReferralCode) {
                          _referralController.clear();
                        }
                      });
                    },
                    activeColor: AppColors.tealGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'I have a referral code',
                    14,
                    AppColors.darkNavy,
                    FontWeight.w500,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
              if (_hasReferralCode) ...[
                SizedBox(height: 12),
                _buildTextField(
                  controller: _referralController,
                  label: 'Referral Code (Optional)',
                  hint: 'Enter referral code',
                  icon: Icons.card_giftcard_outlined,
                  validator: null,
                ),
              ],
              SizedBox(height: 28),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGold.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.tealGreen, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Your data is secure and encrypted',
                        12,
                        AppColors.darkNavy,
                        FontWeight.w600,
                        2,
                        TextAlign.left,
                        1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),
              AppButton.setButtonStyle(context, "Create Account", _isLoading ? null : _handleRegister, _isLoading),

              SizedBox(height: 24),
              _buildTermsAndConditions(),
              SizedBox(height: 20),
              _buildLoginPrompt(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          14,
          AppColors.darkNavy,
          FontWeight.w700,
          1,
          TextAlign.left,
          0.0,
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: AppColors.darkNavy,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.tealGreen, size: 22),
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.greyS400,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),

            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: AppColors.greyS50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyS200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyS200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.tealGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.red),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          'Phone Number',
          14,
          AppColors.darkNavy,
          FontWeight.w700,
          1,
          TextAlign.left,
          0.0,
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          decoration: InputDecoration(
            hintText: 'Enter mobile number',
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.greyS700,
              fontFamily: "Poppins",
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 15, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyS700,
                      fontFamily: "Poppins",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 24, color: AppColors.greyS300),
                ],
              ),
            ),
            filled: true,
            fillColor: AppColors.greyS50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyS200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyS200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.tealGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter mobile number';
            }
            if (value.length != 10) {
              return 'Enter valid 10 digit number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppRichText.setTextPoppinsStyle(
          context,
          'By signing up, you agree to our ',
          12,
          AppColors.greyS600,
          FontWeight.w500,
          1,
          TextAlign.center,
          1.5,
        ),
        GestureDetector(
          onTap: () {},
          child: AppRichText.setTextPoppinsStyle(
            context,
            'Terms',
            12,
            AppColors.tealGreen,
            FontWeight.w700,
            1,
            TextAlign.center,
            1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Already have an account? ',
            14,
            AppColors.greyS600,
            FontWeight.w500,
            1,
            TextAlign.center,
            0.0,
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OtpLoginPage())),
            child: AppRichText.setTextPoppinsStyle(
              context,
              'Sign In',
              14,
              AppColors.tealGreen,
              FontWeight.w800,
              1,
              TextAlign.center,
              0.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIllustration() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.tealGreen],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            top: 100,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.lightGold.withOpacity(0.3), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: 32),

                AppRichText.setTextPoppinsStyle(
                  context,
                  'Create Account',
                  24,
                  AppColors.white,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  1.2,
                ),
                SizedBox(height: 8),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Sign up to get started',
                  14,
                  AppColors.white.withOpacity(0.9),
                  FontWeight.w500,
                  1,
                  TextAlign.left,
                  1.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
