class DailyNewsModel {
  final List<Map<String, dynamic>> points;

  DailyNewsModel({required this.points});

  factory DailyNewsModel.fromJson(Map<String, dynamic> json) {
    return DailyNewsModel(points: List<Map<String, dynamic>>.from(json['data']));
  }
}
