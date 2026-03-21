import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings,
      // onDidReceiveNotificationResponse: (NotificationResponse response) {
      //   // Notification click handle karo
      //   _handleNotificationClick(response);
      // },
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'start_quiz') {
          String? quizId = response.payload;

          // 👉 Navigate to Quiz Screen
          // navigatorKey.currentState?.pushNamed('/quiz', arguments: quizId);
        }
      },
    );

    // Android channel banao
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tazaquiz_channel',
      'TazaQuiz Notifications',
      description: 'Notifications for TazaQuiz',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle notification click
  static void _handleNotificationClick(NotificationResponse response) {
    print('Notification clicked!');
    print('Payload: ${response.payload}');

    // Yaha pe navigation kar sakte ho
    // Example: Navigator.push(...) quiz page pe
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl, // 👈 NEW
  }) async {
    BigPictureStyleInformation? bigPictureStyle;

    // ✅ Image from URL
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final largeIcon = await _downloadAndSaveFile(imageUrl, 'largeIcon');
      final bigPicture = await _downloadAndSaveFile(imageUrl, 'bigPicture');

      bigPictureStyle = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicture),
        largeIcon: FilePathAndroidBitmap(largeIcon),
        contentTitle: title,
        summaryText: body,
      );
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tazaquiz_channel',
      'TazaQuiz Notifications',
      channelDescription: 'Notifications for TazaQuiz',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4F46E5),

      // ✅ Apply Image Style
      styleInformation: bigPictureStyle,

      // ✅ Action Buttons
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('start_quiz', 'Start Quiz', showsUserInterface: true),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details, payload: payload);
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  // Simple notification
  // static Future<void> showNotification({required String title, required String body, String? payload}) async {
  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     'tazaquiz_channel',
  //     'TazaQuiz Notifications',
  //     channelDescription: 'Notifications for TazaQuiz',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     icon: '@mipmap/ic_launcher',
  //     largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  //     color: Color(0xFF4F46E5),
  //   );

  //   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );

  //   const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  //   await _notifications.show(DateTime.now().millisecond, title, body, details, payload: payload);
  // }

  // 🎯 BANNER NOTIFICATION WITH IMAGE
  static Future<void> showBannerNotification({
    required String title,
    required String body,
    required String imageUrl,
    String? payload,
  }) async {
    // Image download karo
    final ByteArrayAndroidBitmap? bigPicture = await _downloadImage(imageUrl);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tazaquiz_channel',
      'TazaQuiz Notifications',
      channelDescription: 'Notifications for TazaQuiz',
      importance: Importance.high,
      priority: Priority.high,

      // Banner image style
      styleInformation: BigPictureStyleInformation(
        bigPicture ?? const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        contentTitle: title,
        summaryText: body,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),

      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4F46E5),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(DateTime.now().millisecond, title, body, details, payload: payload);
  }

  // 🔥 LIVE QUIZ NOTIFICATION WITH "JOIN NOW" BUTTON
  static Future<void> showLiveQuizNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? quizId,
  }) async {
    ByteArrayAndroidBitmap? bigPicture;
    if (imageUrl != null) {
      bigPicture = await _downloadImage(imageUrl);
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tazaquiz_channel',
      'TazaQuiz Notifications',
      channelDescription: 'Notifications for TazaQuiz',
      importance: Importance.high,
      priority: Priority.high,

      // Banner image (agar hai)
      styleInformation:
          bigPicture != null
              ? BigPictureStyleInformation(
                bigPicture,
                contentTitle: title,
                summaryText: body,
                largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              )
              : BigTextStyleInformation(body, contentTitle: title),

      // 🎯 ACTION BUTTONS
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('join_quiz', 'Join Now', showsUserInterface: true, contextual: true),
        const AndroidNotificationAction('dismiss', 'Later', cancelNotification: true),
      ],

      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF10B981), // Green color for live
      ticker: '🔴 Live Quiz Starting!',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: quizId, // Quiz ID pass karo
    );
  }

  // Image download helper
  static Future<ByteArrayAndroidBitmap?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(Uint8List.fromList(response.bodyBytes));
      }
    } catch (e) {
      print('Image download error: $e');
    }
    return null;
  }

  // Listen foreground messages
  static void listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      // Check notification type from data
      final String type = message.data['type'] ?? 'default';
      final String? imageUrl = message.data['image'];
      final String? quizId = message.data['quiz_id'];

      if (type == 'live_quiz') {
        // Live quiz notification with Join button
        showLiveQuizNotification(
          title: message.notification?.title ?? '🔴 Live Quiz!',
          body: message.notification?.body ?? 'Join now to play!',
          imageUrl: imageUrl,
          quizId: quizId,
        );
      } else {
        // Simple notification
        // showNotification(
        //   title: message.notification?.title ?? 'TazaQuiz',
        //   body: message.notification?.body ?? '',
        //   payload: quizId,
        //   imageUrl: imageUrl,
        // );
      }
    });
  }
}
