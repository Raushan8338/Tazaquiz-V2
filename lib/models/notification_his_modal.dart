class NotificationItem {
  final int id;
  final String subject;
  final String message;
  final String createdBy;
  final String updateStatus;
  final int userId;
  final int quizId;
  final String datetime;

  NotificationItem({
    required this.id,
    required this.subject,
    required this.message,
    required this.createdBy,
    required this.updateStatus,
    required this.userId,
    required this.quizId,
    required this.datetime,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      createdBy: json['createdBy'] ?? '',
      updateStatus: json['update_status'] ?? '',
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      quizId: int.tryParse(json['quiz_id'].toString()) ?? 0,
      datetime: json['datetime'] ?? '',
    );
  }
}
