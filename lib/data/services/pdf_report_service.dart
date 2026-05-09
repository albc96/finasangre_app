import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/herraje_model.dart';

class HerrajeView {
  const HerrajeView({
    required this.herraje,
    required this.caballo,
    required this.corral,
    required this.preparador,
    required this.herrador,
  });

  final HerrajeModel herraje;
  final String caballo;
  final String corral;
  final String preparador;
  final String herrador;

  DateTime get fecha =>
      herraje.fechaHerraje ??
      DateTime(herraje.anio, herraje.mes.clamp(1, 12), herraje.dia.clamp(1, 28));

  String get tipo => herraje.tipoHerraje;
  String get hora => herraje.hora;
  String get observaciones => herraje.observaciones;
}

class HerrajeReportItem extends HerrajeView {
  const HerrajeReportItem({
    required super.herraje,
    required super.caballo,
    required super.corral,
    required super.preparador,
    required super.herrador,
  });

  int get idHerraje => herraje.idHerraje;
}

class PdfReportService {
  static const _cyan = PdfColor.fromInt(0xFF00E5FF);
  static const _pink = PdfColor.fromInt(0xFFFF2D95);
  static const _bg = PdfColor.fromInt(0xFF050B18);
  static const _panel = PdfColor.fromInt(0xFF0A1224);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);
  static const _muted = PdfColor.fromInt(0xFFB9C7D8);

  Future<Uint8List> buildMonthlyReportPdf({
    required List<HerrajeView> herrajes,
    required int month,
    required int year,
    required String herradorNombre,
    int? previousMonthTotal,
  }) async {
    final doc = pw.Document();
    final ByteData heroData = await rootBundle.load(
      'assets/hero_finasangre.png',
    );
    final Uint8List heroBytes = heroData.buffer.asUint8List();

    debugPrint('HERO FINASANGRE BYTES: ${heroBytes.length}');

    if (heroBytes.isEmpty) {
      throw Exception('No se cargó assets/hero_finasangre.png');
    }

    final pw.MemoryImage heroImage = pw.MemoryImage(heroBytes);
    final periodStart = DateTime(year, month);
    final periodEnd = DateTime(year, month + 1, 0);
    final rows = herrajes.toList()..sort(_compareHerrajes);

    final completos = _countTipo(rows, 'COMPLETO');
    final manos = _countTipo(rows, 'MANOS');
    final patas = _countTipo(rows, 'PATAS');
    final anterior = previousMonthTotal ?? 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.montserratRegular(),
          bold: await PdfGoogleFonts.montserratBold(),
        ),
        build: (context) => [
          _hero(
            heroImage: heroImage,
            periodStart: periodStart,
            periodEnd: periodEnd,
            herradorNombre: herradorNombre,
            total: rows.length,
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('DETALLE DE HERRAJES DEL PERIODO'),
          pw.SizedBox(height: 8),
          ..._detailSections(rows),
          pw.SizedBox(height: 14),
          _summaryCards(
            completos: completos,
            manos: manos,
            patas: patas,
            total: rows.length,
          ),
          pw.SizedBox(height: 12),
          _compareCard(rows.length, anterior),
          pw.SizedBox(height: 12),
          _auraBlock(
            total: rows.length,
            completos: completos,
            manos: manos,
            patas: patas,
            previous: anterior,
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _hero({
    required pw.ImageProvider heroImage,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String herradorNombre,
    required int total,
  }) {
    final fmt = DateFormat('dd/MM/yyyy');
    return pw.Container(
      height: 260,
      width: double.infinity,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Image(
              heroImage,
              fit: pw.BoxFit.cover,
              alignment: pw.Alignment.centerRight,
            ),
          ),
          pw.Positioned.fill(
            child: pw.Row(
              children: [
                pw.Container(
                  width: 300,
                  decoration: const pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      begin: pw.Alignment.centerLeft,
                      end: pw.Alignment.centerRight,
                      colors: [
                        PdfColor.fromInt(0xF2050B18),
                        PdfColor.fromInt(0xBB050B18),
                        PdfColor.fromInt(0x33050B18),
                        PdfColor.fromInt(0x00050B18),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Container(),
                ),
              ],
            ),
          ),
          pw.Positioned(
            right: 12,
            top: 12,
            bottom: 12,
            child: pw.Container(
              width: 210,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xAA00E5FF),
                  width: .7,
                ),
              ),
              child: pw.ClipRect(
                child: pw.Image(
                  heroImage,
                  fit: pw.BoxFit.cover,
                  alignment: pw.Alignment.centerRight,
                ),
              ),
            ),
          ),
          pw.Positioned(
            left: 24,
            top: 28,
            bottom: 24,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'FINASANGRE',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF00E5FF),
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Sistema de Gestión Equina',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Text(
                  'REPORTE',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'MENSUAL',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFFFF2D95),
                    fontSize: 34,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'DE HERRAJES',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Periodo: ${fmt.format(periodStart)} al ${fmt.format(periodEnd)}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
                ),
                pw.Text(
                  'Herrador: $herradorNombre',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
                ),
                pw.Text(
                  'Total de herrajes: $total',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF00E5FF),
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _panel,
        border: pw.Border(
          left: pw.BorderSide(color: _pink, width: 3),
          bottom: pw.BorderSide(color: _cyan, width: .5),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _white,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _table(List<HerrajeView> rows) {
    final headers = ['#', 'Fecha', 'Hora', 'Caballo', 'Corral', 'Tipo', 'Obs.'];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: [
        for (var i = 0; i < rows.length; i++)
          [
            '${i + 1}',
            DateFormat('dd/MM/yyyy').format(rows[i].fecha),
            rows[i].hora,
            _fit(rows[i].caballo),
            _fit(rows[i].corral),
            _fit(rows[i].tipo),
            _fit(rows[i].observaciones),
          ],
      ],
      border: pw.TableBorder.all(color: PdfColor.fromInt(0x5530DFFF), width: .45),
      headerDecoration: const pw.BoxDecoration(color: _panel),
      headerStyle: pw.TextStyle(
        color: _cyan,
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(color: _white, fontSize: 6.5),
      cellDecoration: (index, data, rowNum) => pw.BoxDecoration(
        color: rowNum.isEven
            ? PdfColor.fromInt(0xFF08101F)
            : PdfColor.fromInt(0xFF0D1730),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FixedColumnWidth(34),
        3: const pw.FlexColumnWidth(1.35),
        4: const pw.FlexColumnWidth(1.15),
        5: const pw.FlexColumnWidth(.85),
        6: const pw.FlexColumnWidth(1.25),
      },
    );
  }

  List<pw.Widget> _detailSections(List<HerrajeView> rows) {
    if (rows.isEmpty) {
      return [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _panel,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _cyan, width: .7),
          ),
          child: pw.Text(
            'Sin herrajes registrados para este periodo.',
            style: const pw.TextStyle(color: _white, fontSize: 9),
          ),
        ),
      ];
    }

    final herradores = <String, List<HerrajeView>>{};
    for (final row in rows) {
      final key = _groupKey(row.herrador, 'Herrador sin nombre');
      herradores.putIfAbsent(key, () => []).add(row);
    }

    if (herradores.length == 1) {
      return _preparadorSections(rows);
    }

    final widgets = <pw.Widget>[];
    final herradoresOrdenados = herradores.keys.toList()..sort();
    for (final herrador in herradoresOrdenados) {
      final items = herradores[herrador]!..sort(_compareHerrajes);
      widgets.add(_groupHeader('HERRADOR: $herrador', items));
      widgets.add(pw.SizedBox(height: 8));
      widgets.addAll(_preparadorSections(items, nested: true));
      widgets.add(pw.SizedBox(height: 6));
    }
    return widgets;
  }

  List<pw.Widget> _preparadorSections(
    List<HerrajeView> rows, {
    bool nested = false,
  }) {
    final porPreparador = <String, List<HerrajeView>>{};
    for (final row in rows) {
      final key = _groupKey(row.preparador, 'Sin preparador');
      porPreparador.putIfAbsent(key, () => []).add(row);
    }

    final widgets = <pw.Widget>[];
    final preparadoresOrdenados = porPreparador.keys.toList()..sort();
    for (final preparador in preparadoresOrdenados) {
      final items = porPreparador[preparador]!..sort(_compareHerrajes);
      widgets.add(_groupHeader('PREPARADOR: $preparador', items));
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_table(items));
      widgets.add(pw.SizedBox(height: nested ? 12 : 14));
    }
    return widgets;
  }

  pw.Widget _groupHeader(String title, List<HerrajeView> rows) {
    final completos = _countTipo(rows, 'COMPLETO');
    final manos = _countTipo(rows, 'MANOS');
    final patas = _countTipo(rows, 'PATAS');
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _cyan, width: .7),
      ),
      child: pw.Text(
        '$title  -  Total: ${rows.length}  -  Completos: $completos  -  Manos: $manos  -  Patas: $patas',
        style: pw.TextStyle(
          color: _cyan,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _summaryCards({
    required int completos,
    required int manos,
    required int patas,
    required int total,
  }) {
    return pw.Row(
      children: [
        _metricCard('Completos', '$completos', _cyan),
        pw.SizedBox(width: 8),
        _metricCard('Manos', '$manos', _pink),
        pw.SizedBox(width: 8),
        _metricCard('Patas', '$patas', _cyan),
        pw.SizedBox(width: 8),
        _metricCard('Total general', '$total', _pink),
      ],
    );
  }

  pw.Widget _metricCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _panel,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: .7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 8)),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _compareCard(int current, int previous) {
    final text = _compareText(current, previous);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _pink, width: .7),
      ),
      child: pw.Text(
        'COMPARATIVO: $text',
        style: pw.TextStyle(
          color: _white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _auraBlock({
    required int total,
    required int completos,
    required int manos,
    required int patas,
    required int previous,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _cyan, width: .8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AURA IA - RESUMEN INTELIGENTE',
            style: pw.TextStyle(
              color: _cyan,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _auraText(total, completos, manos, patas, previous),
            style: const pw.TextStyle(color: _white, fontSize: 9.5, lineSpacing: 2),
          ),
        ],
      ),
    );
  }

  int _countTipo(List<HerrajeView> herrajes, String tipo) {
    return herrajes
        .where((h) => h.tipo.toUpperCase().contains(tipo))
        .length;
  }

  String _compareText(int current, int previous) {
    if (previous <= 0 && current > 0) {
      return 'Sin actividad registrada el mes anterior; este mes inicia con $current herrajes.';
    }
    if (previous <= 0) return 'Este mes se mantuvo igual.';
    final diff = current - previous;
    final pct = ((diff.abs() / previous) * 100).round();
    if (diff > 0) return '+$pct% vs mes anterior';
    if (diff < 0) return 'Este mes bajaron los herrajes un $pct%';
    return 'Este mes se mantuvo igual';
  }

  String _auraText(
    int total,
    int completos,
    int manos,
    int patas,
    int previous,
  ) {
    final tendencia = _compareText(total, previous).toLowerCase();
    final foco = completos >= manos + patas
        ? 'predomina el herraje completo'
        : 'conviene revisar la distribucion entre manos y patas';
    return 'Este mes se registraron $total herrajes. En el desglose operativo hay $completos completos, $manos de manos y $patas de patas; $foco. Tendencia: $tendencia. Recomendacion: revisar caballos sin herraje en los ultimos 30 dias y planificar carga semanal del herrador.';
  }

  String _fit(String value) {
    final clean = value.trim().isEmpty ? '-' : value.trim();
    return clean.length <= 24 ? clean : '${clean.substring(0, 21)}...';
  }

  String _groupKey(String value, String fallback) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  int _compareHerrajes(HerrajeView a, HerrajeView b) {
    final byDate = a.fecha.compareTo(b.fecha);
    if (byDate != 0) return byDate;
    final byTime = a.hora.compareTo(b.hora);
    if (byTime != 0) return byTime;
    return a.herraje.idHerraje.compareTo(b.herraje.idHerraje);
  }
}
