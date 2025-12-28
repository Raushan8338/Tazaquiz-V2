import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/screens/login.dart';
<<<<<<< Updated upstream
=======
import 'package:tazaquiznew/screens/profileScreen.dart';
import 'package:tazaquiznew/screens/splash.dart';
import 'package:tazaquiznew/screens/studyMaterial.dart';
import 'package:tazaquiznew/screens/testSeries.dart';
import 'package:tazaquiznew/testpage.dart';
>>>>>>> Stashed changes

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Api_Client.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taza Quiz',
      debugShowCheckedModeBanner: false,

      home: ContactUsPage()//SplashScreen()//OtpLoginPage(), //LoginPage(),
    );
  }
}
