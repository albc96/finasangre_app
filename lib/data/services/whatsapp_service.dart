import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  Future<bool> shareReport(String message) {
    final uri =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
