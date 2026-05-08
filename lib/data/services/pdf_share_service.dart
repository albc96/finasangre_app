import 'dart:typed_data';

import 'pdf_share_service_stub.dart'
    if (dart.library.io) 'pdf_share_service_io.dart'
    if (dart.library.html) 'pdf_share_service_web.dart';

class PdfShareService {
  Future<void> compartirPdfWhatsApp(Uint8List pdfBytes, String fileName) {
    return sharePdfWhatsAppImpl(pdfBytes, fileName);
  }

  Future<void> compartirPdfCorreo(Uint8List pdfBytes, String fileName) {
    return sharePdfCorreoImpl(pdfBytes, fileName);
  }
}
