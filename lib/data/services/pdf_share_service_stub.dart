import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<void> sharePdfWhatsAppImpl(Uint8List pdfBytes, String fileName) {
  return Printing.sharePdf(bytes: pdfBytes, filename: fileName);
}

Future<void> sharePdfCorreoImpl(Uint8List pdfBytes, String fileName) {
  return Printing.sharePdf(bytes: pdfBytes, filename: fileName);
}
