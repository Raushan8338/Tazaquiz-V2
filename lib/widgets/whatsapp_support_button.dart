import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Floating WhatsApp support button — standard placement is bottom-right,
/// above the bottom nav, opening a chat to the support number via the
/// universal wa.me deep link (works whether or not WhatsApp is installed).
class WhatsAppSupportButton extends StatelessWidget {
  const WhatsAppSupportButton({super.key});

  static const String _phoneNumber = '919874423064';

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/$_phoneNumber?text=${Uri.encodeComponent("Hi, I need help with TazaQuiz")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _openWhatsApp,
      backgroundColor: const Color(0xFF25D366),
      elevation: 4,
      child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 28),
    );
  }
}
