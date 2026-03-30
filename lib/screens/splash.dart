import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/authentication/notification_service.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/homeSceen.dart';
import 'dart:async';
import 'dart:math';
import 'package:tazaquiznew/screens/login.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _shimmerAnim;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground: ${message.notification?.title}');
    });

    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    _scaleAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.65, curve: Curves.elasticOut)));

    _slideAnim = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.35, 0.9, curve: Curves.easeOut)));

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

    _rotateAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_rotateController);

    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    _shimmerAnim = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    _mainController.forward();
    _checkloggedin();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    print('Permission: ${settings.authorizationStatus}');
  }

  void _checkloggedin() async {
    final bool isLoggedIn = await SessionManager.isLoggedIn();
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => isLoggedIn ? HomeScreen() : OtpLoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FF), Color(0xFFEEF2FF), Color(0xFFE8F4F8)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildBgDecorations(size),
            _buildGridPattern(size),

            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnim.value,
                            child: Opacity(
                              opacity: _fadeAnim.value,
                              child: Transform.scale(scale: _pulseAnim.value, child: _buildLogo()),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // App name
                      Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: Opacity(opacity: _fadeAnim.value, child: _buildAppName()),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle
                      Transform.translate(
                        offset: Offset(0, _slideAnim.value * 1.3),
                        child: Opacity(opacity: _fadeAnim.value, child: _buildSubtitle()),
                      ),

                      const SizedBox(height: 10),
                        Transform.translate(
                        offset: Offset(0, _slideAnim.value * 1.3),
                        child: Opacity(opacity: _fadeAnim.value, child: _buildFeatureLine()),
                      ),

                      const SizedBox(height: 20),

                      // Tagline pills
                      Transform.translate(
                        offset: Offset(0, _slideAnim.value * 1.6),
                        child: Opacity(opacity: _fadeAnim.value, child: _buildTaglinePills()),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom
            Positioned(
              bottom: 55,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(opacity: _fadeAnim.value, child: _buildBottomLoader());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOGO ─────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Soft bg glow
            Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.tealGreen.withOpacity(0.08), Colors.transparent]),
              ),
            ),

            // Outer rotating dashed ring
            Transform.rotate(
              angle: _rotateAnim.value,
              child: SizedBox(
                width: 212,
                height: 212,
                child: CustomPaint(
                  painter: _DashedCirclePainter(color: AppColors.tealGreen.withOpacity(0.25), dashCount: 30),
                ),
              ),
            ),

            // Inner counter rotating ring — gold
            Transform.rotate(
              angle: -_rotateAnim.value * 0.7,
              child: SizedBox(
                width: 186,
                height: 186,
                child: CustomPaint(
                  painter: _DashedCirclePainter(color: AppColors.lightGold.withOpacity(0.3), dashCount: 18),
                ),
              ),
            ),

            // Colored ring border
            Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.tealGreen.withOpacity(0.15), AppColors.lightGold.withOpacity(0.1)],
                ),
                border: Border.all(color: AppColors.tealGreen.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.tealGreen.withOpacity(0.15), blurRadius: 25, spreadRadius: 5),
                  BoxShadow(color: AppColors.lightGold.withOpacity(0.1), blurRadius: 20, spreadRadius: 3),
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
            ),

            // White logo container
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 6)),
                  BoxShadow(color: AppColors.tealGreen.withOpacity(0.1), blurRadius: 16, spreadRadius: 2),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),

            // Shimmer overlay on logo
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ClipOval(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_shimmerAnim.value - 1, -0.5),
                        end: Alignment(_shimmerAnim.value, 0.5),
                        colors: [Colors.transparent, Colors.white.withOpacity(0.25), Colors.transparent],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ─── APP NAME ─────────────────────────────────────────────────────────────

  Widget _buildAppName() {
    return Column(
      children: [
        // TazaQuiz with gradient
        ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkNavy, AppColors.tealGreen, const Color(0xFF0A6B5E)],
              ).createShader(bounds),
          child: const Text(
            'TazaQuiz',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Animated divider
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              width: 80,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.tealGreen, AppColors.lightGold, Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── SUBTITLE ─────────────────────────────────────────────────────────────

Widget _buildSubtitle() {
  return Text(
    'Live Tests, Mock Tests & Daily Quiz Practice',
    style: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      color: AppColors.darkNavy.withOpacity(0.55),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    ),
  );
}
Widget _buildFeatureLine() {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      'SSC • Railway • Banking • All Exams',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        color: AppColors.darkNavy.withOpacity(0.45),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    ),
  );
}

  // ─── TAGLINE PILLS ────────────────────────────────────────────────────────

Widget _buildTaglinePills() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _pill('🔴', 'Live Tests', AppColors.tealGreen, AppColors.tealGreen.withOpacity(0.1)),
      const SizedBox(width: 8),
      _pill('📝', 'Mock Tests', AppColors.darkNavy, AppColors.darkNavy.withOpacity(0.08)),
      const SizedBox(width: 8),
      _pill('⚡', 'Daily Quiz', const Color(0xFFB8860B), AppColors.lightGold.withOpacity(0.12)),
    ],
  );
}

  Widget _pill(String emoji, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: textColor.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM LOADER ────────────────────────────────────────────────────────

  Widget _buildBottomLoader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar style loader
        Container(
          width: 120,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.darkNavy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ((_shimmerAnim.value + 1) / 3).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.lightGold]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(
         'Loading Fresh Tests & Quizzes...',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.darkNavy.withOpacity(0.4),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ─── BG DECORATIONS ───────────────────────────────────────────────────────

  Widget _buildBgDecorations(Size size) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top right — teal
            Positioned(
              top: -100,
              right: -100,
              child: Opacity(
                opacity: 0.2 * _fadeAnim.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppColors.tealGreen.withOpacity(0.5), Colors.transparent]),
                  ),
                ),
              ),
            ),

            // Bottom left — gold
            Positioned(
              bottom: -120,
              left: -120,
              child: Opacity(
                opacity: 0.18 * _fadeAnim.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppColors.lightGold.withOpacity(0.5), Colors.transparent]),
                  ),
                ),
              ),
            ),

            // Mid left — navy
            Positioned(
              top: size.height * 0.3,
              left: -50,
              child: Opacity(
                opacity: 0.07 * _fadeAnim.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.darkNavy),
                ),
              ),
            ),

            // Mid right — teal small
            Positioned(
              top: size.height * 0.65,
              right: -30,
              child: Opacity(
                opacity: 0.08 * _fadeAnim.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tealGreen),
                ),
              ),
            ),

            // Dots
            ..._buildDots(size),
          ],
        );
      },
    );
  }

  // ─── GRID PATTERN ─────────────────────────────────────────────────────────

  Widget _buildGridPattern(Size size) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(opacity: 0.03 * _fadeAnim.value, child: CustomPaint(size: size, painter: _GridPatternPainter()));
      },
    );
  }

  List<Widget> _buildDots(Size size) {
    return List.generate(16, (index) {
      final rand = (index * 47) % 100;
      final x = ((rand * 3.9) % 100) * size.width / 100;
      final y = (rand * size.height / 100);
      final dotSize = 2.0 + (rand % 3).toDouble();
      final isGold = index % 3 == 0;
      final isTeal = index % 3 == 1;
      final color =
          isGold
              ? AppColors.lightGold
              : isTeal
              ? AppColors.tealGreen
              : AppColors.darkNavy;

      return Positioned(
        top: y,
        left: x,
        child: Opacity(
          opacity: (0.08 + (rand / 600)) * _fadeAnim.value,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      );
    });
  }
}

// ─── DASHED CIRCLE PAINTER ────────────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;

  _DashedCirclePainter({this.color = Colors.grey, this.dashCount = 24});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final dashAngle = (2 * pi) / dashCount;
    const gapRatio = 0.45;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapRatio);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashCount != dashCount;
}

// ─── GRID PATTERN PAINTER ─────────────────────────────────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.darkNavy
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
