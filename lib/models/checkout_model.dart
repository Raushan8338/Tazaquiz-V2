class CheckoutModel {
  final String contentType;
  final int id;
  final String title;
  final String description;
  final double basePrice;
  final int gstRate;
  final double gstAmount;
  final double finalPrice;

  CheckoutModel({
    required this.contentType,
    required this.id,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.gstRate,
    required this.gstAmount,
    required this.finalPrice,
  });

  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    return CheckoutModel(
      contentType: json['content_type'],
      id: json['id'],
      title: json['title'],
      description: json['description'],
      basePrice: double.parse(json['base_price'].toString()),
      gstRate: json['gst_rate'],
      gstAmount: double.parse(json['gst_amount'].toString()),
      finalPrice: double.parse(json['final_price'].toString()),
    );
  }

  // ✅ STEP 2: copyWith() ADD HERE
  CheckoutModel copyWith({double? finalPrice}) {
    return CheckoutModel(
      contentType: contentType,
      id: id,
      title: title,
      description: description,
      basePrice: basePrice,
      gstRate: gstRate,
      gstAmount: gstAmount,
      finalPrice: finalPrice ?? this.finalPrice,
    );
  }
}
