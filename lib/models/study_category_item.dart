class CategoryItem {
  final int category_id;
  final String name;

  CategoryItem({required this.category_id, required this.name});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      category_id: int.parse((json['category_id'] ?? json['level_id']).toString()),
      name: _resolveName(json),
    );
  }

  static String _resolveName(Map<String, dynamic> json) {
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      return json['name'].toString();
    }
    if (json['level_name'] != null && json['level_name'].toString().isNotEmpty) {
      return json['level_name'].toString();
    }
    return '';
  }
}
