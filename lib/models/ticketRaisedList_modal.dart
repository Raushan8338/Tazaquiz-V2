class TicketRaisedList {
  String reqId;
  String reason;
  String issueDescription;
  String datetime;
  String adminRemarks;
  String adminDateTime;
  String status;

  TicketRaisedList({
    required this.reqId,
    required this.reason,
    required this.issueDescription,
    required this.datetime,
    required this.adminRemarks,
    required this.adminDateTime,
    required this.status,
  });

  factory TicketRaisedList.fromJson(Map<String, dynamic> json) => TicketRaisedList(
    reqId: json["reqId"]?.toString() ?? "",
    reason: json["reason"]?.toString() ?? "",
    issueDescription: json["issueDescription"]?.toString() ?? "",
    datetime: json["datetime"]?.toString() ?? "",
    adminRemarks: json["adminRemarks"]?.toString() ?? "",
    adminDateTime: json["adminDateTime"]?.toString() ?? "",
    status: json["status"]?.toString() ?? "0",
  );

  Map<String, dynamic> toJson() => {
    "reqId": reqId,
    "reason": reason,
    "issueDescription": issueDescription,
    "datetime": datetime,
    "adminRemarks": adminRemarks,
    "adminDateTime": adminDateTime,
    "status": status,
  };
}
