class UserModel {
  final String userId;
  final String username;
  final String email;
  final String phone;
  final String? profileImage;
  final String deviceId;
  final String androidInfo;
  final String createdAt;
  final String? lastLogin;
  final String userRole;
  final String status;
  final String referalId;
  final String id;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.deviceId,
    required this.androidInfo,
    required this.createdAt,
    this.lastLogin,
    required this.userRole,
    required this.status,
    required this.referalId,
    required this.id,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      deviceId: json['device_id'] ?? '',
      androidInfo: json['androidInfo'] ?? '',
      createdAt: json['created_at'],
      lastLogin: json['last_login'],
      userRole: json['user_role'],
      status: json['status'],
      referalId: json['referalId'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'device_id': deviceId,
      'androidInfo': androidInfo,
      'created_at': createdAt,
      'last_login': lastLogin,
      'user_role': userRole,
      'status': status,
      'referalId': referalId,
      'id': id,
    };
  }
}
