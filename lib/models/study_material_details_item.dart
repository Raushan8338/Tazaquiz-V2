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

  // 🔥 NEW OPTIONAL FLAGS (SAFE)
  final bool isPurchased;
  final bool isAccessible;

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
    this.author = '***********',

    // 🔥 DEFAULT SAFE VALUES
    this.isPurchased = false,
    this.isAccessible = false,
  });

  factory StudyMaterialDetailsItem.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    bool _toBool(dynamic v) => v == true || v == 1 || v == '1';

    return StudyMaterialDetailsItem(
      materialId: _toInt(json['material_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
      creatorId: _toInt(json['creator_id']),
      categoryId: _toInt(json['category_id']),
      subjectId: _toInt(json['subject_id']),
      price: _toDouble(json['price']),
      isPaid: _toBool(json['is_paid']),
      levelId: _toInt(json['level_id']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      isPublished: _toBool(json['is_published']),
      rating: json['rating']?.toString() ?? '4.5',
      thumbnail: json['thumbnail']?.toString() ?? '',
      author: json['author']?.toString() ?? '**********',

      // 🔥 SAFE PARSING (agar na aaye to false)
      isPurchased: _toBool(json['is_purchased']),
      isAccessible: _toBool(json['is_accessible']),
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

      // 🔥 OPTIONAL
      'is_purchased': isPurchased,
      'is_accessible': isAccessible,
    };
  }
}
