import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/reporte_model.dart';
import '../../../data/services/email_service.dart';
import '../../../data/services/whatsapp_service.dart';

class ReporteDetailScreen extends StatelessWidget {
  const ReporteDetailScreen({super.key, required this.reporte});
  final ReporteModel reporte;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Reporte ${reporte.mes}/${reporte.anio}')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
              title: const Text('Total herrajes'),
              subtitle: Text('${reporte.totalHerrajes}')),
          ListTile(title: const Text('Estado'), subtitle: Text(reporte.estado)),
          ListTile(
              title: const Text('PDF URL'),
              subtitle: Text(reporte.pdfUrl.isEmpty
                  ? 'PDF local generado por Printing'
                  : reporte.pdfUrl)),
          ListTile(
              title: const Text('WhatsApp'),
              subtitle:
                  Text(reporte.enviadoWhatsapp ? 'Enviado' : 'Pendiente')),
          ListTile(
              title: const Text('Correo'),
              subtitle: Text(reporte.enviadoCorreo ? 'Enviado' : 'Pendiente')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              if (reporte.pdfUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Este reporte no tiene URL de PDF guardada.'),
                  ),
                );
                return;
              }
              await launchUrl(Uri.parse(reporte.pdfUrl),
                  mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Ver PDF'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => WhatsappService().shareReport(
              reporte.pdfUrl.isEmpty
                  ? 'Reporte FINASANGRE ${reporte.mes}/${reporte.anio}: ${reporte.totalHerrajes} herrajes.'
                  : 'Reporte FINASANGRE ${reporte.mes}/${reporte.anio}: ${reporte.pdfUrl}',
            ),
            icon: const Icon(Icons.send),
            label: const Text('Compartir WhatsApp'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => EmailService().sendReport(
              to: 'admin@finasangre.cl',
              body:
                  'Reporte FINASANGRE ${reporte.mes}/${reporte.anio}: ${reporte.totalHerrajes} herrajes. ${reporte.pdfUrl}',
            ),
            icon: const Icon(Icons.email),
            label: const Text('Enviar correo'),
          ),
        ]),
      );
}
