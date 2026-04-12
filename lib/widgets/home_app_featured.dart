import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';

class CourseFeatureStrip extends StatelessWidget {
  final List<Map<String, dynamic>> actions;

  const CourseFeatureStrip({Key? key, required this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
          child: TranslatedText(
            "App Features",
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        SizedBox(
  height: 100, // ← 92 tha, overflow fix
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.only(left: 0, right: 16, bottom: 4),
    itemCount: actions.length,
    separatorBuilder: (_, __) => const SizedBox(width: 9),
    itemBuilder: (context, index) {
      final action = actions[index];
      final Color color = action['color'] as Color;

      return GestureDetector(
       onTap: (){
        Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudyMaterialPurchaseHistoryScreen('1')),
    );
       },
        child: Container(
          width: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withOpacity(0.07),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 11, 8, 9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              TranslatedText(
                action['label'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
),
      ],
    );
  }
}