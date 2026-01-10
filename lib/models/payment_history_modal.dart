// Payment History Response Model
class PaymentHistoryResponse {
  final bool success;
  final String message;
  final int totalRecords;
  final int fetchedRecords;
  final PaymentStats stats;
  final List<PaymentItem> data;

  PaymentHistoryResponse({
    required this.success,
    required this.message,
    required this.totalRecords,
    required this.fetchedRecords,
    required this.stats,
    required this.data,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      totalRecords: json['total_records'] ?? 0,
      fetchedRecords: json['fetched_records'] ?? 0,
      stats: PaymentStats.fromJson(json['stats'] ?? {}),
      data: (json['data'] as List?)?.map((e) => PaymentItem.fromJson(e)).toList() ?? [],
    );
  }
}

// Payment Stats Model
class PaymentStats {
  final double totalSpent;
  final int totalTransactions;
  final int successCount;
  final int pendingCount;
  final int failedCount;

  PaymentStats({
    required this.totalSpent,
    required this.totalTransactions,
    required this.successCount,
    required this.pendingCount,
    required this.failedCount,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalSpent: _toDouble(json['total_spent']),
      totalTransactions: _toInt(json['total_transactions']),
      successCount: _toInt(json['success_count']),
      pendingCount: _toInt(json['pending_count']),
      failedCount: _toInt(json['failed_count']),
    );
  }

  static int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
  static double _toDouble(dynamic value) => double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
}

// Payment Item Model
class PaymentItem {
  final int id;
  final String orderId;
  final int userId;
  final int productId;
  final String productType;
  final ProductDetails? productDetails;
  final double amount;
  final String? couponCode;
  final double couponDiscount;
  final String currency;
  final String? paymentSessionId;
  final String orderStatus;
  final String? cfPaymentId;
  final String? paymentMethod;
  final String? transactionId;
  final String purchaseDate;
  final String createdAt;
  final String updatedAt;

  PaymentItem({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.productId,
    required this.productType,
    this.productDetails,
    required this.amount,
    this.couponCode,
    required this.couponDiscount,
    required this.currency,
    this.paymentSessionId,
    required this.orderStatus,
    this.cfPaymentId,
    this.paymentMethod,
    this.transactionId,
    required this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    return PaymentItem(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString() ?? '',
      userId: _toInt(json['user_id']),
      productId: _toInt(json['product_id']),
      productType: json['product_type']?.toString() ?? '',
      productDetails: json['product_details'] != null ? ProductDetails.fromJson(json['product_details']) : null,
      amount: _toDouble(json['amount']),
      couponCode: json['coupon_code']?.toString(),
      couponDiscount: _toDouble(json['coupon_discount']),
      currency: json['currency']?.toString() ?? 'INR',
      paymentSessionId: json['payment_session_id']?.toString(),
      orderStatus: json['order_status']?.toString() ?? 'PENDING',
      cfPaymentId: json['cf_payment_id']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      purchaseDate: json['purchase_date']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
  static double _toDouble(dynamic value) => double.tryParse(value?.toString() ?? '0.0') ?? 0.0;

  // Helper getters
  String get displayStatus {
    switch (orderStatus.toUpperCase()) {
      case 'SUCCESS':
      case 'PAID':
        return 'success';
      case 'PENDING':
        return 'pending';
      case 'FAILED':
        return 'failed';
      default:
        return 'pending';
    }
  }

  String get productDisplayName {
    return productDetails?.name ?? 'Product #$productId';
  }

  String get productTypeDisplay {
    switch (productType.toUpperCase()) {
      case 'QUIZ':
        return 'Quiz Entry Fee';
      case 'STUDY':
      case 'COURSE':
      case 'STUDY_MATERIAL':
        return 'Course Purchase';
      default:
        return productType;
    }
  }
}

// Product Details Model
class ProductDetails {
  final int id;
  final String name;
  final String description;
  final String? image;
  final double price;
  final int categoryId;

  // Quiz specific fields
  final String? difficultyLevel;
  final String? timeLimit;
  final int? questionCount;

  // Study Material specific fields
  final String? contentType;
  final int? levelId;

  ProductDetails({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.price,
    required this.categoryId,
    this.difficultyLevel,
    this.timeLimit,
    this.questionCount,
    this.contentType,
    this.levelId,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      price: _toDouble(json['price']),
      categoryId: _toInt(json['category_id']),
      difficultyLevel: json['difficulty_level']?.toString(),
      timeLimit: json['time_limit']?.toString(),
      questionCount: _toInt(json['question_count']),
      contentType: json['content_type']?.toString(),
      levelId: _toInt(json['level_id']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
