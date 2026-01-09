class CouponApplyModel {
  final String couponCode;
  final int discount;
  final double finalPrice;

  CouponApplyModel({required this.couponCode, required this.discount, required this.finalPrice});

  factory CouponApplyModel.fromJson(Map<String, dynamic> json) {
    return CouponApplyModel(
      couponCode: json['coupon_code'],
      discount: json['discount'],
      finalPrice: double.parse(json['final_price'].toString()),
    );
  }
}
