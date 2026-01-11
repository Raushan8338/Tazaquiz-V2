import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/authentication/notification_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/home.dart';
import 'package:tazaquiznew/screens/homeSceen.dart';
import 'dart:async';
import 'package:tazaquiznew/screens/login.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  //hyggtt
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  @override
  void initState() {
    super.initState();
    requestPermission();

    /// 2️⃣ Foreground notification listener 🔥 (YAHI ADD KARNA THA)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      print(message.notification?.title);
      print(message.notification?.body);

      // OPTIONAL: yahan custom snackbar / dialog dikha sakte ho
    });

    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 2000));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.6, curve: Curves.easeIn)));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.6, curve: Curves.elasticOut)));

    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Interval(0.3, 0.8, curve: Curves.easeOut)));

    _controller.forward();

    _checkloggedin();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

    print('Permission status: ${settings.authorizationStatus}');
  }

  void _checkloggedin() async {
    final bool isLoggedIn = await SessionManager.isLoggedIn();
    if (isLoggedIn) {
      Timer(Duration(seconds: 2), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      });
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OtpLoginPage()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkNavy, // Dark Navy
              AppColors.tealGreen, // Teal
              AppColors.oxfordBlue, // Deep Blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            _buildBackgroundCircles(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            width: 280,
                            height: 280,
                            padding: EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lightGold.withOpacity(0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(20),
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 40),

                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                'Learn • Practice • Excel',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  color: AppColors.lightGold,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3,
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                width: 60,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.lightGold, AppColors.white, AppColors.lightGold],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Loading indicator at bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(AppColors.lightGold),
                            backgroundColor: AppColors.white.withOpacity(0.2),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Version at bottom
            // Positioned(
            //   bottom: 30,
            //   left: 0,
            //   right: 0,
            //   child: AnimatedBuilder(
            //     animation: _controller,
            //     builder: (context, child) {
            //       return Opacity(
            //         opacity: _fadeAnimation.value,
            //         child: Text(
            //           'Version 1.0.0',
            //           textAlign: TextAlign.center,
            //           style: TextStyle(
            //             fontFamily: 'Poppins',
            //             fontSize: 12,
            //             color: AppColors.white.withOpacity(0.6),
            //             fontWeight: FontWeight.w400,
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCircles() {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.1 * _fadeAnimation.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppColors.lightGold, AppColors.transparent]),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom left circle
        Positioned(
          bottom: -150,
          left: -150,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.1 * _fadeAnimation.value,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppColors.lightGold, AppColors.transparent]),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: -50,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.05 * _fadeAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white),
                ),
              );
            },
          ),
        ),

        ...List.generate(20, (index) {
          final random = (index * 37) % 100;
          return Positioned(
            top: (random * MediaQuery.of(context).size.height / 100),
            left: ((random * 3.7) % 100) * MediaQuery.of(context).size.width / 100,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: (0.3 + (random / 200)) * _fadeAnimation.value,
                  child: Container(
                    width: 4 + (random % 6).toDouble(),
                    height: 4 + (random % 6).toDouble(),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.lightGold,
                      boxShadow: [
                        BoxShadow(color: AppColors.lightGold.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
