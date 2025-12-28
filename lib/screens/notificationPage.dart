import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';


class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Unread', 'Important', 'Archived'];

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'achievement',
      'icon': Icons.emoji_events,
      'color': Colors.orange,
      'title': 'New Achievement Unlocked!',
      'message': 'Congratulations! You\'ve earned the "Top Performer" badge for scoring 90+ in 5 consecutive tests.',
      'time': DateTime.now().subtract(Duration(minutes: 5)),
      'isRead': false,
      'isImportant': true,
      'category': 'Achievement',
    },
    {
      'id': '2',
      'type': 'test',
      'icon': Icons.quiz,
      'color': AppColors.tealGreen,
      'title': 'New Test Available',
      'message': 'Advanced Mathematics Test is now available. Complete before 31st Dec 2025.',
      'time': DateTime.now().subtract(Duration(hours: 2)),
      'isRead': false,
      'isImportant': false,
      'category': 'Test',
    },
    {
      'id': '3',
      'type': 'result',
      'icon': Icons.assessment,
      'color': Colors.green,
      'title': 'Test Results Published',
      'message': 'Your Physics Mock Test results are now available. You scored 85%!',
      'time': DateTime.now().subtract(Duration(hours: 5)),
      'isRead': true,
      'isImportant': false,
      'category': 'Result',
    },
    {
      'id': '4',
      'type': 'announcement',
      'icon': Icons.campaign,
      'color': AppColors.darkNavy,
      'title': 'Important Announcement',
      'message': 'New study materials have been added for Chemistry. Check the Materials section now.',
      'time': DateTime.now().subtract(Duration(days: 1)),
      'isRead': true,
      'isImportant': true,
      'category': 'Announcement',
    },
    {
      'id': '5',
      'type': 'reminder',
      'icon': Icons.notifications_active,
      'color': Colors.purple,
      'title': 'Test Reminder',
      'message': 'Don\'t forget! Your Biology test starts in 2 hours.',
      'time': DateTime.now().subtract(Duration(days: 1, hours: 3)),
      'isRead': true,
      'isImportant': false,
      'category': 'Reminder',
    },
    {
      'id': '6',
      'type': 'course',
      'icon': Icons.school,
      'color': AppColors.tealGreen,
      'title': 'Course Update',
      'message': 'New chapter added to your enrolled course "Organic Chemistry Basics".',
      'time': DateTime.now().subtract(Duration(days: 2)),
      'isRead': true,
      'isImportant': false,
      'category': 'Course',
    },
    {
      'id': '7',
      'type': 'payment',
      'icon': Icons.payment,
      'color': AppColors.blue,
      'title': 'Payment Successful',
      'message': 'Your payment of ₹2,499 for Premium Annual Plan has been processed successfully.',
      'time': DateTime.now().subtract(Duration(days: 3)),
      'isRead': true,
      'isImportant': true,
      'category': 'Payment',
    },
    {
      'id': '8',
      'type': 'social',
      'icon': Icons.people,
      'color': AppColors.pink,
      'title': 'New Follower',
      'message': 'Priya Sharma started following you. Connect and share your progress!',
      'time': DateTime.now().subtract(Duration(days: 4)),
      'isRead': true,
      'isImportant': false,
      'category': 'Social',
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'All') {
      return _notifications;
    } else if (_selectedFilter == 'Unread') {
      return _notifications.where((n) => !n['isRead']).toList();
    } else if (_selectedFilter == 'Important') {
      return _notifications.where((n) => n['isImportant']).toList();
    }
    return _notifications;
  }

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
       appBar: AppBar(
        leading: AppButton.setBackIcon(context, (){Navigator.pop(context);}, AppColors.white),
         title:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             AppRichText.setTextPoppinsStyle(
                        context,
                        'Notifications',
                        20,
                        AppColors.white,
                        FontWeight.w900,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                SizedBox(height: 2),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Stay updated with your activities',
                    13,
                    AppColors.lightGold,
                    FontWeight.w600,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                    SizedBox(height: 4),
           ],
         ),


      centerTitle: false,
      // leading: 
      flexibleSpace: Container(
      decoration:  BoxDecoration(
      gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
    ),
  ),
      ),
     
      body: CustomScrollView(
        slivers: [
       
          _buildNotificationsList(),
        ],
      ),
    );
  }


  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.lightGold, size: 24),
        ),
        SizedBox(height: 10),
       AppRichText.setTextPoppinsStyle(
          context,
          value,
          20,
          AppColors.white,
          FontWeight.w900,
          1,
          TextAlign.center,
          0.0,
        ),
        SizedBox(height: 2),
       AppRichText.setTextPoppinsStyle(
          context,
          label,
          11,
          AppColors.white.withOpacity(0.9),
          FontWeight.w600,
          1,
          TextAlign.center,
          0.0,
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    final notifications = _filteredNotifications;

    if (notifications.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.greyS1,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: AppColors.greyS400,
                ),
              ),
              SizedBox(height: 20),
             AppRichText.setTextPoppinsStyle(
                context,
                'No Notifications',
                18,
                AppColors.darkNavy,
                FontWeight.w900,
                1,
                TextAlign.center,
                0.0,
              ),
              SizedBox(height: 8),
             AppRichText.setTextPoppinsStyle(
                context,
                'You\'re all caught up!',
                13,
                AppColors.greyS600,
                FontWeight.w500,
                1,
                TextAlign.center,
                0.0,
              ),
            ],
          ),
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
    for (var notification in notifications) {
      String dateKey = _getDateLabel(notification['time']);
      if (!groupedNotifications.containsKey(dateKey)) {
        groupedNotifications[dateKey] = [];
      }
      groupedNotifications[dateKey]!.add(notification);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entries = groupedNotifications.entries.toList();
          final dateKey = entries[index].key;
          final dateNotifications = entries[index].value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                child:AppRichText.setTextPoppinsStyle(
                  context,
                  dateKey,
                  14,
                  AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ),
              ...dateNotifications.map((notification) {
                return _buildNotificationCard(notification);
              }).toList(),
            ],
          );
        },
        childCount: groupedNotifications.length,
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'];
    final isImportant = notification['isImportant'];

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete, color: AppColors.white, size: 28),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                setState(() {
                  _notifications.add(notification);
                });
              },
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isImportant
              ? Border.all(color: AppColors.lightGold, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          notification['color'],
                          notification['color'].withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notification['icon'],
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:AppRichText.setTextPoppinsStyle(
                                context,
                                notification['title'],
                                14,
                                AppColors.darkNavy,
                                isRead ? FontWeight.w600 : FontWeight.w900,
                                1,
                                TextAlign.left,
                                1.3,
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.tealGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6),
                       AppRichText.setTextPoppinsStyle(
                          context,
                          notification['message'],
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
                            Icon(Icons.access_time,
                                size: 14, color: AppColors.greyS500),
                            SizedBox(width: 4),
                           AppRichText.setTextPoppinsStyle(
                              context,
                              _formatTime(notification['time']),
                              11,
                              AppColors.greyS600,
                              FontWeight.w500,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: notification['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child:AppRichText.setTextPoppinsStyle(
                                context,
                                notification['category'],
                                10,
                                notification['color'],
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
            if (isImportant)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.lightGold,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star, color: AppColors.darkNavy, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }


  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }
}

