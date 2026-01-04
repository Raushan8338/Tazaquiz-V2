// Course Item Model
class CourseItem {
  final String id;
  final String courseName;
  final String? courseImage;
  final String description;
  final String duration;
  final String price;
  final String? mrpPrice;
  final String? discountPrice;
  final String totalTests;
  final String totalMaterials;
  final String courseType;
  final String finalPrice;
  final bool isFree;

  CourseItem({
    required this.id,
    required this.courseName,
    this.courseImage,
    required this.description,
    required this.duration,
    required this.price,
    this.mrpPrice,
    this.discountPrice,
    required this.totalTests,
    required this.totalMaterials,
    required this.courseType,
    required this.finalPrice,
    required this.isFree,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: json['id']?.toString() ?? '',
      courseName: json['course_name'] ?? '',
      courseImage: json['course_image'],
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      price: json['price']?.toString() ?? '0',
      mrpPrice: json['mrp_price']?.toString(),
      discountPrice: json['discount_price']?.toString(),
      totalTests: json['total_tests']?.toString() ?? '0',
      totalMaterials: json['total_materials']?.toString() ?? '0',
      courseType: json['course_type'] ?? '',
      finalPrice: json['final_price']?.toString() ?? '0',
      isFree: json['is_free'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_name': courseName,
      'course_image': courseImage,
      'description': description,
      'duration': duration,
      'price': price,
      'mrp_price': mrpPrice,
      'discount_price': discountPrice,
      'total_tests': totalTests,
      'total_materials': totalMaterials,
      'course_type': courseType,
      'final_price': finalPrice,
      'is_free': isFree,
    };
  }
}
