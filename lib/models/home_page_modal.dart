// Main Response Model
import 'package:tazaquiznew/models/coaching_item_modal.dart';
import 'package:tazaquiznew/models/course_item_modal.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/models/studyMaterial_modal.dart';

class HomeDataResponse {
  final bool status;
  final List<HomeSection> data;

  HomeDataResponse({required this.status, required this.data});

  factory HomeDataResponse.fromJson(Map<String, dynamic> json) {
    return HomeDataResponse(
      status: json['status'] ?? false,
      data: (json['data'] as List?)?.map((item) => HomeSection.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'data': data.map((item) => item.toJson()).toList()};
  }
}

// Home Section Model (Quiz, Course, Coaching, Study Material)
class HomeSection {
  final String section;
  final String title;
  final String? subtitle;
  final String viewAllType;
  final List<dynamic> items;

  HomeSection({
    required this.section,
    required this.title,
    this.subtitle,
    required this.viewAllType,
    required this.items,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    String section = json['section'] ?? '';
    List<dynamic> items = [];

    // Parse items based on section type
    if (json['items'] != null) {
      switch (section) {
        case 'quiz':
          items = (json['items'] as List).map((item) => QuizItem.fromJson(item)).toList();
          break;
        case 'course':
          items = (json['items'] as List).map((item) => CourseItem.fromJson(item)).toList();
          break;
        case 'coaching':
          items = (json['items'] as List).map((item) => CoachingItem.fromJson(item)).toList();
          break;
        case 'study_material':
          items = (json['items'] as List).map((item) => StudyMaterialItem.fromJson(item)).toList();
          break;
        default:
          items = json['items'] as List;
      }
    }

    return HomeSection(
      section: section,
      title: json['title'] ?? '',
      subtitle: json['quiz_subtitle'] ?? json['course_subtitle'] ?? json['coach_subtitle'] ?? json['study_subtitle'],
      viewAllType: json['view_all_type'] ?? '',
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section': section,
      'title': title,
      if (subtitle != null) _getSubtitleKey(): subtitle,
      'view_all_type': viewAllType,
      'items':
          items.map((item) {
            if (item is QuizItem) return item.toJson();
            if (item is CourseItem) return item.toJson();
            if (item is CoachingItem) return item.toJson();
            if (item is StudyMaterialItem) return item.toJson();
            return item;
          }).toList(),
    };
  }

  String _getSubtitleKey() {
    switch (section) {
      case 'quiz':
        return 'quiz_subtitle';
      case 'course':
        return 'course_subtitle';
      case 'coaching':
        return 'coach_subtitle';
      case 'study_material':
        return 'study_subtitle';
      default:
        return 'subtitle';
    }
  }
}

// Example Usage:
/*
void main() {
  // Parse JSON response
  String jsonString = '{"status":true,"data":[...]}';
  Map<String, dynamic> jsonData = json.decode(jsonString);
  
  HomeDataResponse response = HomeDataResponse.fromJson(jsonData);
  
  // Access data
  for (var section in response.data) {
    print('Section: ${section.section}');
    print('Title: ${section.title}');
    print('Subtitle: ${section.subtitle}');
    
    if (section.section == 'study_material') {
      List<StudyMaterialItem> materials = section.items.cast<StudyMaterialItem>();
      for (var material in materials) {
        print('Material: ${material.title}');
        print('Description: ${material.description}');
      }
    }
  }
}
*/
