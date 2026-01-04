import 'dart:convert';

import 'package:flutter/material.dart';
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

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationItem> notifications = [];
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    // Fetch and set user data here if needed
    _user = await SessionManager.getUser();
    setState(() {});
  }

  Future<List<NotificationItem>> NotificationHistory() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    final data = {'user_id': _user?.id};

    final response = await authRepository.fetchNotificationHistory(data);

    if (response.statusCode == 200) {
      print('Notification History: ${response.data}');
      var jsonResponsesCount = jsonDecode(response.data);
      final List series = jsonResponsesCount['series'] ?? [];
      notifications = series.map((e) => NotificationItem.fromJson(e)).toList();
      return notifications;
    } else {
      print('Failed to fetch notification history');
      return []; // return empty list if failed
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: AppBar(
        leading: AppButton.setBackIcon(context, () {
          Navigator.pop(context);
        }, AppColors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRichText.setTextPoppinsStyle(
              context,
              'Notifications',
              18,
              AppColors.white,
              FontWeight.normal,
              1,
              TextAlign.left,
              0.0,
            ),
            SizedBox(height: 2),
          ],
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: NotificationHistory(),
        builder: (BuildContext context, AsyncSnapshot<List<NotificationItem>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('snapshot error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGold, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.tealGreen.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications, color: AppColors.white, size: 16),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppRichText.setTextPoppinsStyle(
                                    context,
                                    notification.subject,
                                    14,
                                    AppColors.darkNavy,
                                    FontWeight.w600,
                                    1,
                                    TextAlign.left,
                                    1.3,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              notification.message,
                              12,
                              AppColors.greyS700,
                              FontWeight.w500,
                              25,
                              TextAlign.left,
                              1.40,
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: AppColors.greyS500),
                                SizedBox(width: 4),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  notification.datetime,
                                  11,
                                  AppColors.greyS600,
                                  FontWeight.w500,
                                  1,
                                  TextAlign.left,
                                  0.0,
                                ),
                                SizedBox(width: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: AppRichText.setTextPoppinsStyle(
                                    context,
                                    notification.createdBy,
                                    10,
                                    AppColors.tealGreen,
                                    FontWeight.w700,
                                    1,
                                    TextAlign.center,
                                    0.0,
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
              );
            },
          );
        },
      ),
    );
  }
}
