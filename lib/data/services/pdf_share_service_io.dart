import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePdfWhatsAppImpl(Uint8List pdfBytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(pdfBytes, flush: true);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    text: 'Reporte mensual FINASANGRE',
  );
}

Future<void> sharePdfCorreoImpl(Uint8List pdfBytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(pdfBytes, flush: true);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    subject: 'Reporte mensual FINASANGRE',
    text: 'Adjunto reporte mensual de herrajes FINASANGRE.',
  );
}
