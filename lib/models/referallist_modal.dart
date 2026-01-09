class ReferralUserDetail {
  String id;
  String name;
  String email;
  String phone;
  DateTime datetime;
  String status;
  String deviceId;
  String userId;

  ReferralUserDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.datetime,
    required this.status,
    required this.deviceId,
    required this.userId,
  });

  factory ReferralUserDetail.fromJson(Map<String, dynamic> json) => ReferralUserDetail(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
    datetime: DateTime.parse(json["datetime"]),
    status: json["status"],
    deviceId: json["device_id"],
    userId: json["userId"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "phone": phone,
    "datetime": datetime.toIso8601String(),
    "status": status,
    "device_id": deviceId,
    "userId": userId,
  };
}
