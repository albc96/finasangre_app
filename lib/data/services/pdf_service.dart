import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/herraje_model.dart';

class PdfService {
  Future<void> monthlyReport(
    List<HerrajeModel> herrajes, {
    DateTime? periodoInicio,
    DateTime? periodoFin,
    String? tituloHerrador,
    List<String> caballosSinHerrar = const [],
    String Function(int id)? caballoName,
    String Function(int id)? herradorName,
    String Function(int id)? corralName,
    String Function(int id)? preparadorName,
  }) async {
    final doc = pw.Document();
    final inicio = periodoInicio ?? _firstDayOfCurrentMonth();
    final fin = periodoFin ?? DateTime(inicio.year, inicio.month + 1, 0);
    final completos = _countTipo(herrajes, 'COMPLETO');
    final manos = _countTipo(herrajes, 'MANOS');
    final patas = _countTipo(herrajes, 'PATAS');
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FINASANGRE',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Reporte mensual de herrajes'),
              pw.Text(
                'Periodo: ${DateFormat('dd/MM/yyyy').format(inicio)} al ${DateFormat('dd/MM/yyyy').format(fin)}',
              ),
              pw.Text(
                  'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              pw.Text(tituloHerrador == null
                  ? 'Herradores: todos'
                  : 'Herrador: $tituloHerrador'),
              pw.SizedBox(height: 18),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Caballo',
                  'Corral',
                  'Preparador',
                  'Herrador',
                  'Tipo',
                  'Fecha',
                  'Hora',
                ],
                data: herrajes
                    .map((h) => [
                          caballoName?.call(h.idCaballo) ?? '${h.idCaballo}',
                          corralName?.call(h.idCorral) ?? '${h.idCorral}',
                          preparadorName?.call(h.idCaballo) ?? '',
                          herradorName?.call(h.idHerrador) ?? '${h.idHerrador}',
                          h.tipoHerraje,
                          _fechaHerraje(h),
                          h.hora,
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 18),
              pw.Text('Totales',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Completos: $completos'),
              pw.Text('Manos: $manos'),
              pw.Text('Patas: $patas'),
              pw.Text('Total general: ${herrajes.length}'),
              if (caballosSinHerrar.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                pw.Text(
                  'Caballos sin herraje en el mes',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                ...caballosSinHerrar.map(
                  (name) => pw.Text('Quedo $name sin herrar este mes.'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    final pdfBytes = await doc.save();
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  DateTime _firstDayOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  int _countTipo(List<HerrajeModel> herrajes, String tipo) {
    return herrajes
        .where((h) => h.tipoHerraje.toUpperCase().contains(tipo))
        .length;
  }

  String _fechaHerraje(HerrajeModel h) {
    if (h.dia > 0 && h.mes > 0 && h.anio > 0) {
      return '${h.dia.toString().padLeft(2, '0')}/${h.mes.toString().padLeft(2, '0')}/${h.anio}';
    }
    final fecha = h.fechaHerraje;
    if (fecha != null) return DateFormat('dd/MM/yyyy').format(fecha);
    return '';
  }
}
