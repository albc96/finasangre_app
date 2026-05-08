import 'package:url_launcher/url_launcher.dart';

class EmailService {
  Future<bool> sendReport({required String to, required String body}) {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': 'Reporte FINASANGRE',
        'body': body,
      },
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
