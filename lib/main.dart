import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/notification_service.dart';
import 'package:tazaquiznew/screens/splash.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  await NotificationService.initialize();
  NotificationService.listenForegroundMessages();

  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  Api_Client.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TazaQuiz',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), //OtpLoginPage(), //LoginPage(),
    );
  }
}
