import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
