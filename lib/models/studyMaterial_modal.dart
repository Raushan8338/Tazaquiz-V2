// Study Material Item Model
class StudyMaterialItem {
  final String id;
  final String title;
  final String? boardIcon;
  final String description;

  StudyMaterialItem({required this.id, required this.title, this.boardIcon, required this.description});

  factory StudyMaterialItem.fromJson(Map<String, dynamic> json) {
    return StudyMaterialItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      boardIcon: json['boardIcon']?.isEmpty ?? true ? null : json['boardIcon'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'boardIcon': boardIcon ?? '', 'description': description};
  }
}
