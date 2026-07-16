import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:firebase_analytics/firebase_analytics.dart'; // ✅ NEW
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ✅ NEW
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:tazaquiznew/API/Language_converter/translation_service.dart'; 
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/notificationHandler.dart';
import 'package:tazaquiznew/authentication/notification_service.dart';
import 'package:tazaquiznew/screens/splash.dart';

/// Background handler (Android / iOS / Web only)
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final title = message.data['title'] ?? 'TazaQuiz';
  final body = message.data['body'] ?? '';
  final image = message.data['image_url'];
}

Future<void> _saveInstallReferrer() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getString('install_referrer') ?? '';
    if (already.isNotEmpty) return;

    final ReferrerDetails referrerDetails = await PlayInstallReferrer.installReferrer;
    final referrer = referrerDetails.installReferrer ?? '';
    print('📦 INSTALL REFERRER: $referrer');

    if (referrer.isNotEmpty) {
      await prefs.setString('install_referrer', referrer);
    }
  } catch (e) {
    print('Referrer error: $e');
  }
}

bool isPushSupported() {
  return kIsWeb || Platform.isAndroid || Platform.isIOS;
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService.instance.init();
  await MobileAds.instance.initialize();
  await _saveInstallReferrer();

  if (isPushSupported()) {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await NotificationService.initialize();
    NotificationService.listenForegroundMessages();

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // ✅ NEW — Crashlytics setup
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

  } else {
    debugPrint("🔥 Firebase & Push disabled on Windows");
  }

  Api_Client.init();
  await NotificationPlatformHandler.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ✅ NEW
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TazaQuiz',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // ✅ NEW — screen tracking
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      home: SplashScreen(),
    );
  }
}