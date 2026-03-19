import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/notification_service.dart';
import 'package:tazaquiznew/firebase_options.dart';
import 'package:tazaquiznew/screens/splash.dart';

/// Background handler (Android / iOS / Web only)
///
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final title = message.data['title'] ?? 'TazaQuiz';
  final body = message.data['body'] ?? '';
  final image = message.data['image_url'];

  if (image != null && image.isNotEmpty) {
    await NotificationService.showBannerNotification(title: title, body: body, imageUrl: image);
  } else {
    await NotificationService.showNotification(title: title, body: body);
  }
}

bool isPushSupported() {
  return kIsWeb || Platform.isAndroid || Platform.isIOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService.instance.init();
  await MobileAds.instance.initialize();

  /// 🔥 Firebase ONLY for supported platforms
  if (isPushSupported()) {
    await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await NotificationService.initialize();
    NotificationService.listenForegroundMessages();

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  } else {
    debugPrint("🔥 Firebase & Push disabled on Windows");
  }

  Api_Client.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'TazaQuiz', debugShowCheckedModeBanner: false, home: SplashScreen());
  }
}
