class SelectedCourseItem {
  final int categoryId;
  final String categoryName;
  final int? parentCategoryId;
  final String description;
  bool isSelected;

  SelectedCourseItem({
    required this.categoryId,
    required this.categoryName,
    this.parentCategoryId,
    required this.description,
    required this.isSelected,
  });

  factory SelectedCourseItem.fromJson(Map<String, dynamic> json) {
    return SelectedCourseItem(
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '',
      parentCategoryId: json['parent_category_id'],
      description: json['description'] ?? '',
      isSelected: json['is_selected'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'parent_category_id': parentCategoryId,
      'description': description,
      'is_selected': isSelected ? 1 : 0,
    };
  }
}
