import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tazaquiz/screens/buyQuizes.dart';

// Notification click handler example

class NotificationHandler {
  // App ke main.dart me ye setup karo
  static void setupNotificationHandler(GlobalKey<NavigatorState> navigatorKey) {
    // Ye method notification service ke initialize me call hoga
    // Jab notification click hoga tab ye run hoga
  }

  // Notification click handle karo
  static void handleNotificationClick(BuildContext context, NotificationResponse response) {
    final String? payload = response.payload;
    final String? actionId = response.actionId;

    print('Notification clicked!');
    print('Action: $actionId');
    print('Payload: $payload');

    // Action ke basis pe navigate karo
    if (actionId == 'join_quiz') {
      // Live quiz join karo
      _navigateToQuiz(context, payload);
    } else if (payload != null) {
      // Simple notification click - quiz details page pe jao
      _navigateToQuizDetails(context, payload);
    }
  }

  // Quiz page pe navigate
  static void _navigateToQuiz(BuildContext context, String? quizId) {
    if (quizId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizDetailPage(quizId: quizId, is_subscribed: false)),
    );
  }

  // Quiz details page pe navigate
  static void _navigateToQuizDetails(BuildContext context, String quizId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizDetailPage(quizId: quizId, is_subscribed: false)),
    );
  }
}
