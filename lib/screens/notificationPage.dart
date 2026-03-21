import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/notification_his_modal.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> notifications = [];
  UserModel? _user;
  Future<List<NotificationItem>>? _notificationFuture;

  @override
/*************  ✨ Windsurf Command ⭐  *************/
/*******  6603602a-fd5b-47f5-b0ba-0a5333bcfba7  *******/  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _user = await SessionManager.getUser();
    if (_user != null) {
      _notificationFuture = _fetchNotificationHistory();
      setState(() {});
    }
  }

  Future<List<NotificationItem>> _fetchNotificationHistory() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final response = await authRepository.fetchNotificationHistory({'user_id': _user?.id});
    if (response.statusCode == 200) {
      var jsonResponsesCount = jsonDecode(response.data);
      final List series = jsonResponsesCount['series'] ?? [];
      notifications = series.map((e) => NotificationItem.fromJson(e)).toList();
      return notifications;
    }
    return [];
  }

  /// Icon + color based on notification type
  Map<String, dynamic> _notifStyle(String createdBy, String subject) {
    final s = subject.toLowerCase();
    if (createdBy.toUpperCase() == 'SYSTEM') {
      return {'icon': Icons.shield_rounded, 'color': const Color(0xFFEF5350)};
    }
    if (s.contains('quiz') || s.contains('live')) {
      return {'icon': Icons.bolt_rounded, 'color': const Color(0xFFFF9800)};
    }
    if (s.contains('result') || s.contains('score')) {
      return {'icon': Icons.bar_chart_rounded, 'color': const Color(0xFF0D6E6E)};
    }
    return {'icon': Icons.campaign_rounded, 'color': const Color(0xFF2979FF)};
  }

  String _formatNotifDate(String raw) {
    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A3D3D), Color(0xFF0D6E6E)],
            ),
          ),
        ),
        leading: AppButton.setBackIcon(context, () => Navigator.pop(context), AppColors.white),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.3),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notificationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0D6E6E)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFF0D6E6E).withOpacity(0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF0D6E6E)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 6),
                  const Text('You\'re all caught up!', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final style = _notifStyle(n.createdBy, n.subject);
              final Color iconColor = style['color'];
              final IconData iconData = style['icon'];
              final bool isSystem = n.createdBy.toUpperCase() == 'SYSTEM';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: iconColor.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    /// Top accent bar
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [iconColor, iconColor.withOpacity(0.3)]),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Icon bubble
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(iconData, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 14),

                          /// Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Subject + badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.subject,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A2E),
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        n.createdBy.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: iconColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                /// Message
                                Text(
                                  n.message,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),

                                /// Time
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatNotifDate(n.datetime),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
