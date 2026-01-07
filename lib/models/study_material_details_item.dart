class StudyMaterialDetailsItem {
  final int materialId;
  final String title;
  final String description;
  final String contentType;
  final String filePath;
  final int creatorId;
  final int categoryId;
  final int subjectId;
  final double price;
  final bool isPaid;
  final int levelId;
  final DateTime createdAt;
  final bool isPublished;
  final String rating;
  final String thumbnail;
  final String author;

  StudyMaterialDetailsItem({
    required this.materialId,
    required this.title,
    required this.description,
    required this.contentType,
    required this.filePath,
    required this.creatorId,
    required this.categoryId,
    required this.subjectId,
    required this.price,
    required this.isPaid,
    required this.levelId,
    required this.createdAt,
    required this.isPublished,
    this.rating = '4.5',
    required this.thumbnail,
    this.author = 'Raushan Kumar',
  });

  factory StudyMaterialDetailsItem.fromJson(Map<String, dynamic> json) {
    return StudyMaterialDetailsItem(
      materialId: int.parse(json['material_id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      contentType: json['content_type'] ?? '',
      filePath: json['file_path'] ?? '',
      creatorId: int.parse(json['creator_id'].toString()),
      categoryId: int.parse(json['category_id'].toString()),
      subjectId: int.parse(json['subject_id'].toString()),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      levelId: int.parse(json['level_id'].toString()),
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      isPublished: json['is_published'] == 1 || json['is_published'] == true,
      rating: json['rating'] ?? '4.5',
      thumbnail: json['thumbnail'] ?? '',
      author: json['author'] ?? 'Raushan Kumar',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'title': title,
      'description': description,
      'content_type': contentType,
      'file_path': filePath,
      'creator_id': creatorId,
      'category_id': categoryId,
      'subject_id': subjectId,
      'price': price.toString(),
      'is_paid': isPaid,
      'level_id': levelId,
      'created_at': createdAt.toIso8601String(),
      'is_published': isPublished ? 1 : 0,
      'rating': rating,
      'thumbnail': thumbnail,
      'author': author,
    };
  }
}
