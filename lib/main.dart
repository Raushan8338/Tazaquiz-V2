import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/screens/login.dart';

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

      home: OtpLoginPage(), //LoginPage(),
    );
  }
}
