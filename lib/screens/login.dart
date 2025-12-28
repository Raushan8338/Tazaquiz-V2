import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/API/api_endpoint.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/otpVerificationPage.dart';
import 'package:tazaquiznew/screens/singup.dart';
import 'package:tazaquiznew/testpage.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';

class OtpLoginPage extends StatefulWidget {
  @override
  _OtpLoginPageState createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> with TickerProviderStateMixin {
  bool _isPhoneLogin = true;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Authrepository authRepository = Authrepository(Api_Client.dio);
      try {
        final data = {
          'phone': _phoneController.text,
          'email': _emailController.text,
          'device_id': 'sd',
          'androidInfo': 'android',
        };
        final response = await authRepository.loginUser(data);

        if (response.statusCode == 200) {
          print('Login Response: ${response.data}');
          final data = jsonDecode(response.data); // ✅ FIX

          final status = data['status'];
          final otpSent = data['otp_sent'] == true;

          if (status == "register" && otpSent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => OTPBasedVerificationPage(
                      phoneNumber: _phoneController.text,
                      name: '',
                      email: '',
                      referalCode: '',
                    ),
              ),
            );
          } else if (status == "not_register") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppRichText.setTextPoppinsStyle(
                  context,
                  'Something went wrong. Please try again.',
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
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppRichText.setTextPoppinsStyle(
                  context,
                  'Something went wrong. Please try again.',
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
      } catch (e) {
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleLoginMethod() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
          child: Column(children: [_buildTopIllustration(), Expanded(child: _buildLoginForm())]),
        ),
      ),
    );
  }

  Widget _buildTopIllustration() {
    return Container(
      height: 310,
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
          // Background circles
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
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),

                Container(
                  height: 120,
                  width: 120,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 30, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'QuizMaster',
                  32,
                  AppColors.white,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  1.0,
                ),

                SizedBox(height: 8),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Learn • Practice • Excel',
                  14,
                  AppColors.lightGold,
                  FontWeight.w600,
                  1,
                  TextAlign.left,
                  2.0,
                ),

                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 0),
              Center(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  'Welcome Back!',
                  26,
                  AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  'Sign in to continue learning',
                  14,
                  AppColors.greyS600,
                  FontWeight.normal,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ),
              SizedBox(height: 25),

              _buildPhoneFields(),
              SizedBox(height: 24),
              _buildLoginButton(),

              SizedBox(height: 24),
              _buildOrDivider(),
              SizedBox(height: 24),
              _buildSocialButtons(),
              Spacer(),
              _buildSignUpPrompt(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneFields() {
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Enter mobile number',
            hintStyle: TextStyle(color: AppColors.greyS400, fontSize: 14),
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

  Widget _buildLoginButton() {
    return AppButton.setButtonStyle(
      context,
      _isPhoneLogin ? 'Send OTP' : 'Sign In',
      _isLoading ? null : _handleLogin,
      _isLoading,
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.greyS300, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AppRichText.setTextPoppinsStyle(
            context,
            'OR',
            13,
            AppColors.greyS500,
            FontWeight.w700,
            1,
            TextAlign.left,
            0.0,
          ),
        ),
        Expanded(child: Divider(color: AppColors.greyS300, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(children: [Expanded(child: _buildSocialButton('Sign In With Google', () {}))]);
  }

  Widget _buildSocialButton(String name, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.greyS1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyS300!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(4)),
                  child: Center(
                    child: AppRichText.setTextPoppinsStyle(
                      context,
                      'G',
                      12,
                      AppColors.white,
                      FontWeight.bold,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ),
                );
              },
            ),

            SizedBox(width: 10),
            AppRichText.setTextPoppinsStyle(
              context,
              name,
              15,
              AppColors.darkNavy,
              FontWeight.w700,
              1,
              TextAlign.left,
              0.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'Don\'t have an account?',
            14,
            AppColors.greyS600,
            FontWeight.normal,
            1,
            TextAlign.left,
            0.0,
          ),

          SizedBox(width: 6),
          AppButton.setGestureDetectorButtonStyle(context, 'Sign Up', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationPage()));
          }),
        ],
      ),
    );
  }
}
