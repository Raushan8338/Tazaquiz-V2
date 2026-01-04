import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/homeSceen.dart';
import 'package:tazaquiznew/screens/singup.dart';
import 'dart:async';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';

class OTPBasedVerificationPage extends StatefulWidget {
  final String phoneNumber, name, email;
  final String? referalCode;

  OTPBasedVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.name,
    required this.email,
    this.referalCode,
  });

  @override
  _OTPBasedVerificationPageState createState() => _OTPBasedVerificationPageState();
}

class _OTPBasedVerificationPageState extends State<OTPBasedVerificationPage> {
  //hyggtt
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpControllers.forEach((controller) => controller.dispose());
    _focusNodes.forEach((node) => node.dispose());
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _resendOTP() async {
    // Ye check kro
    setState(() {
      _otpControllers.forEach((controller) => controller.clear());
      _focusNodes[0].requestFocus();
    });
    _startTimer();
    Authrepository authRepository = Authrepository(Api_Client.dio);

    try {
      final data = {'phone': widget.phoneNumber, 'email': '', 'device_id': 'sd', 'androidInfo': 'android'};
      final response = await authRepository.loginUser(data);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppRichText.setTextPoppinsStyle(
              context,
              'OTP resent successfully',
              12,
              AppColors.white,
              FontWeight.normal,
              1,
              TextAlign.left,
              0.0,
            ),
            backgroundColor: AppColors.tealGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppRichText.setTextPoppinsStyle(
              context,
              'Failed to resend OTP. Please try again.',
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
    } catch (e) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOTP() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);

    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == 6) {
      setState(() => _isLoading = true);
      final data = {
        'mobile': widget.phoneNumber,
        'OTP': otp,
        'name': widget.name,
        'email': widget.email,
        'device_id': '',
        'referalCode': 'widget.referalCode',
        'androidInfo': '',
      };

      print(data);

      final responseFuture = await authRepository.signupVerifyOTP(data);

      print("STATUS => ${responseFuture.statusCode}");
      print("DATA => ${responseFuture.data}");

      if (responseFuture.statusCode == 200) {
        setState(() => _isLoading = false);
        final userJson = responseFuture.data['series'];
        final user = UserModel.fromJson(userJson);
        await SessionManager.saveUser(user);
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen()), (route) => false);
      } else {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppRichText.setTextPoppinsStyle(
              context,
              'Invalid OTP. Please try again.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppRichText.setTextPoppinsStyle(
            context,
            'Please enter complete OTP',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              Container(
                height: 140,
                width: 140,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.transparent,
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
              SizedBox(height: 32),
              AppRichText.setTextPoppinsStyle(
                context,
                'OTP Verification',
                20,
                AppColors.darkNavy,
                FontWeight.w900,
                1,
                TextAlign.left,
                0.0,
              ),

              SizedBox(height: 12),
              AppRichText.setTextPoppinsStyle(
                context,
                'Enter the 6-digit code sent to',
                14,
                AppColors.greyS600,
                FontWeight.normal,
                1,
                TextAlign.left,
                0.0,
              ),

              SizedBox(height: 4),
              AppRichText.setTextPoppinsStyle(
                context,
                '+91 ${widget.phoneNumber}',
                16,
                AppColors.tealGreen,
                FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),

              SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPBox(index)),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.greyS600),
                  SizedBox(width: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    _resendTimer > 0 ? 'Resend OTP in ${_resendTimer}s' : 'Didn\'t receive code?',
                    14,
                    AppColors.greyS600,
                    FontWeight.normal,
                    1,
                    TextAlign.left,
                    0.0,
                  ),

                  if (_resendTimer == 0) ...[
                    SizedBox(width: 8),
                    AppButton.setGestureDetectorButtonStyle(context, 'Resend', _resendOTP),
                  ],
                ],
              ),
              SizedBox(height: 48),
              AppButton.setButtonStyle(context, 'Verify & Continue', _isLoading ? null : _verifyOTP, _isLoading),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFDEB9E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFFDEB9E).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.tealGreen, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'OTP is valid for 10 minutes',
                        13,
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
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpControllers[index].text.isNotEmpty ? AppColors.tealGreen : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.greyS700, fontFamily: "Poppins"),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(counterText: '', border: InputBorder.none),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
