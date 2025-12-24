import 'package:flutter/material.dart';

class AppFonts {
  AppFonts._(); // prevents instantiation

  /// 🔥 App / Brand Header (TazaQuiz, Hero, AppBar title)
  static const TextStyle appHeader = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// 🧩 Section Title (Quiz name, Category title)
  static const TextStyle sectionTitle = TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w500);

  /// 📝 Normal body text (Descriptions, instructions)
  static const TextStyle bodyText = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// ❓ Quiz Question (MOST IMPORTANT)
  static const TextStyle question = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// ✅ Answer Options (MCQ)
  static const TextStyle answer = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// ⭐ Highlight / Eye-catch (Score, Rank, Timer, CTA)
  static const TextStyle highlight = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  /// ⏱️ Small info text (Timer label, footer text)
  static const TextStyle caption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  /// 🔘 Button text
  static const TextStyle button = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}
