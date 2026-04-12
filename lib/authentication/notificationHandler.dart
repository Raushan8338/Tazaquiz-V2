import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiznew/main.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/daily_quiz_screen.dart';
import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/screens/notificationPage.dart';
import 'package:tazaquiznew/screens/studyMaterialPurchaseHistory.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationPlatformHandler {
  static const platform = MethodChannel('tazaquiz/notification');
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    platform.setMethodCallHandler((call) async {
      if (call.method == "onNotificationClick") {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _logNotification(data);
        _handleNavigation(data);
      }
    });

    try {
      await platform.invokeMethod('flutterReady');
    } catch (e) {
      // debugPrint("flutterReady error: $e");
    }
  }

  static void _logNotification(Map<String, dynamic> data) {
    // debugPrint("==== NOTIFICATION TAP ====");
    // debugPrint("Page             : ${data['page']}");
    // debugPrint("Type             : ${data['type']}");
    // debugPrint("Quiz ID          : ${data['quiz_id']}");
    // debugPrint("Title            : ${data['title']}");
    // debugPrint("Body             : ${data['body']}");
    // debugPrint("Meta             : ${data['meta']}");
    // debugPrint("Notification Type: ${data['notification_type']}");
    // debugPrint("Image            : ${data['image']}");
    // debugPrint("=========================");
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final meta = data['meta'] as String? ?? '';

    // ✅ 800ms delay — emulator slow hota hai
    Future.delayed(const Duration(milliseconds: 800), () {
      final context = navigatorKey.currentContext;
      //  debugPrint("🎯 Context: $context | type: $type");
      if (context == null) {
        debugPrint("❌ Context null!");
        return;
      }

      switch (type) {
        case 'start_quiz':
        case 'quiz':
          final quizId = data['quiz_id'] as String? ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuizDetailPage(quizId: quizId, is_subscribed: false)),
          );
          //_showQuizJoinSheet(context, data);
          break;

        case 'payment':
        case 'payment_success':
        case 'purchase':
          Navigator.push(context, _fadeRoute(StudyMaterialPurchaseHistoryScreen('1')));
          break;

        case 'web':
          // ✅ canLaunchUrl CHECK HATAO — directly launch karo
          _launchURL(meta);
          break;

        case 'news':
        case 'notification':
          Navigator.push(context, _fadeRoute(NotificationsPage()));
          break;
        case 'daily_quiz':
          Navigator.push(context, _fadeRoute(DailyQuizScreen())); // apna screen name daalo
          break;

        default:
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (r) => false);
          break;
      }
    });
  }

  static Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      //  debugPrint("❌ URL empty");
      return;
    }
    try {
      // debugPrint("🌐 Launching: $url");
      final uri = Uri.parse(url); // ✅ tryParse ki jagah parse
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      //  debugPrint("✅ Launched!");
    } catch (e) {
      // debugPrint("❌ Launch error: $e");
      // ✅ Fallback
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      } catch (e2) {
        //    debugPrint("❌ Fallback error: $e2");
      }
    }
  }

  // static void _showQuizJoinSheet(BuildContext context, Map<String, dynamic> data) {
  //   final quizId = data['quiz_id'] as String? ?? '';
  //   final title = data['title'] as String? ?? 'Live Quiz';
  //   final body = data['body'] as String? ?? '';
  //   final imageUrl = data['image'] as String? ?? '';
  //   final type = data['type'] as String? ?? '';

  //   debugPrint("🎯 Opening sheet | quizId=$quizId | title=$title");

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     useRootNavigator: true, // ✅ ADD THIS — nested navigator issue fix
  //     builder: (_) => _QuizJoinSheet(quizId: quizId, title: title, body: body, imageUrl: imageUrl, type: type),
  //   );
  // }

  static Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Quiz Join Bottom Sheet Widget
// ───────────────────────────────────────────────────────────────────────────
// class _QuizJoinSheet extends StatelessWidget {
//   final String quizId;
//   final String title;
//   final String body;
//   final String imageUrl;
//   final String type;

//   const _QuizJoinSheet({
//     required this.quizId,
//     required this.title,
//     required this.body,
//     required this.imageUrl,
//     required this.type,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isLive = type == 'start_quiz';

//     return Container(
//       margin: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0F1B2D),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.white.withOpacity(0.08)),
//         boxShadow: [BoxShadow(color: const Color(0xFF0D6E6E).withOpacity(0.3), blurRadius: 30, spreadRadius: -5)],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // ── Drag handle ─────────────────────────────────────────────
//           Container(
//             margin: const EdgeInsets.only(top: 12),
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
//           ),

//           // ── Banner image ─────────────────────────────────────────────
//           if (imageUrl.isNotEmpty)
//             Container(
//               margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//               height: 160,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
//               ),
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [Colors.transparent, const Color(0xFF0F1B2D).withOpacity(0.8)],
//                   ),
//                 ),
//               ),
//             ),

//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Live / Upcoming badge ──────────────────────────────
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color:
//                         isLive ? const Color(0xFFE53935).withOpacity(0.15) : const Color(0xFF0D6E6E).withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color:
//                           isLive ? const Color(0xFFE53935).withOpacity(0.4) : const Color(0xFF0D6E6E).withOpacity(0.4),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 6,
//                         height: 6,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: isLive ? const Color(0xFFE53935) : const Color(0xFF0D6E6E),
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         isLive ? '🔴 LIVE NOW' : '⏰ UPCOMING',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           letterSpacing: 0.8,
//                           color: isLive ? const Color(0xFFE53935) : const Color(0xFF0D6E6E),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 // ── Title ──────────────────────────────────────────────
//                 Text(
//                   title,
//                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
//                 ),

//                 if (body.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   Text(body, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5)),
//                 ],

//                 const SizedBox(height: 24),

//                 // ── Buttons ────────────────────────────────────────────
//                 Row(
//                   children: [
//                     // Later
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Container(
//                           height: 52,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(color: Colors.white.withOpacity(0.12)),
//                           ),
//                           child: Center(
//                             child: Text(
//                               'Later',
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.white.withOpacity(0.6),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(width: 12),

//                     // Join Now
//                     Expanded(
//                       flex: 2,
//                       child: GestureDetector(
//                         onTap: () {
//                           Navigator.pop(context);
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => LiveTestScreen(testTitle: title, subject: '', Quiz_id: quizId),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           height: 52,
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(colors: [Color(0xFF0D6E6E), Color(0xFF0A9396)]),
//                             borderRadius: BorderRadius.circular(14),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF0D6E6E).withOpacity(0.4),
//                                 blurRadius: 16,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: const Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text('🚀', style: TextStyle(fontSize: 18)),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Join Now',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.white,
//                                   letterSpacing: 0.3,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
