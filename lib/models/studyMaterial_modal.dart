// Study Material Item Model
class StudyMaterialItem {
  final String id;
  final String title;
  final String? boardIcon;
  final String description;
  final int category_id;
  final String DateTime;
  final int is_purchased; // ← New field for video URL

  StudyMaterialItem({
    required this.id,
    required this.title,
    this.boardIcon,
    required this.description,
    required this.category_id,
    required this.DateTime,
    required this.is_purchased, // ← Include in constructor
  });

factory StudyMaterialItem.fromJson(Map<String, dynamic> json) {
  return StudyMaterialItem(
    id: json['id']?.toString() ?? '',
    title: json['title'] ?? '',
    boardIcon: json['boardIcon']?.isEmpty ?? true ? null : json['boardIcon'],
    description: json['description'] ?? '',
    category_id: int.tryParse(json['category_id'].toString()) ?? 0,
    DateTime: json['DateTime'] ?? '',
    is_purchased: int.tryParse(json['is_purchased'].toString()) ?? 0, // ✅ FIX
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'boardIcon': boardIcon ?? '',
      'description': description,
      'category_id': category_id,
      'is_purchased': is_purchased, // ← Include in JSON
    };
  }
}
