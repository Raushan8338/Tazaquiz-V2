import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiz/API/api_client.dart';
import 'package:tazaquiz/authentication/notification_service.dart';
import 'package:tazaquiz/screens/splash.dart';

/// Background handler (Android / iOS / Web only)

bool isPushSupported() {
  return kIsWeb || Platform.isAndroid || Platform.isIOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
