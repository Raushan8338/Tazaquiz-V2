// Study Material Item Model
class StudyMaterialItem {
  final String id;
  final String title;
  final String? boardIcon;
  final String description;
  final int category_id;
  final String DateTime;

  StudyMaterialItem({
    required this.id,
    required this.title,
    this.boardIcon,
    required this.description,
    required this.category_id,
    required this.DateTime,
  });

  factory StudyMaterialItem.fromJson(Map<String, dynamic> json) {
    return StudyMaterialItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      boardIcon: json['boardIcon']?.isEmpty ?? true ? null : json['boardIcon'],
      description: json['description'] ?? '',
      category_id: json['category_id'] ?? 0,
      DateTime: json['DateTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'boardIcon': boardIcon ?? '',
      'description': description,
      'category_id': category_id,
    };
  }
}
