import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../../data/models/herraje_model.dart';
import '../../../data/models/caballo_model.dart';
import '../../../data/models/corral_model.dart';
import '../../../data/models/herrador_model.dart';
import '../../../data/models/preparador_model.dart';
import '../../../data/services/pdf_report_service.dart';
import '../../../data/services/pdf_share_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caballo_provider.dart';
import '../../providers/corral_provider.dart';
import '../../providers/herraje_provider.dart';
import '../../providers/herrador_provider.dart';
import '../../providers/preparador_provider.dart';
import '../../providers/reporte_provider.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/dashboard/stat_card.dart';
import 'reporte_detail_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final pdfReportService = PdfReportService();
  final pdfShareService = PdfShareService();
  Uint8List? _lastPdfBytes;
  String? _lastPdfFileName;
  int? selectedHerrador;
  late int selectedMonth;
  late int selectedYear;

  static const _monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final previous = _previousMonth();
    selectedMonth = previous.start.month;
    selectedYear = previous.start.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReporteProvider>().cargar();
      context.read<HerrajeProvider>().cargar();
      context.read<CaballoProvider>().cargar();
      context.read<HerradorProvider>().cargar();
      context.read<CorralProvider>().cargar();
      context.read<PreparadorProvider>().cargar();
    });
  }

  DateTimeRange _previousMonth() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month - 1),
      end: DateTime(now.year, now.month, 0),
    );
  }

  Future<void> _generatePdf({int? idHerrador, bool openViewer = true}) async {
    await context.read<HerrajeProvider>().cargar();
    if (!mounted) return;

    final allHerrajes = context.read<HerrajeProvider>().items;
    final herrajes = _filterHerrajes(
      allHerrajes,
      month: selectedMonth,
      year: selectedYear,
      idHerrador: idHerrador,
    );

    final caballos = context.read<CaballoProvider>().items;
    final herradores = context.read<HerradorProvider>().items;
    final corrales = context.read<CorralProvider>().items;
    final preparadores = context.read<PreparadorProvider>().items;
    final herradorName = idHerrador == null
        ? 'Todos'
        : herradores
            .where((h) => h.idHerrador == idHerrador)
            .map((h) => h.nombreCompleto)
            .firstOrNull;
    final itemsPdf = _buildHerrajeViews(
      herrajes,
      caballos: caballos,
      herradores: herradores,
      corrales: corrales,
      preparadores: preparadores,
    );
    final previous = DateTime(selectedYear, selectedMonth - 1);
    final previousTotal = _filterHerrajes(
      allHerrajes,
      month: previous.month,
      year: previous.year,
      idHerrador: idHerrador,
    ).length;

    debugPrint('TOTAL HERRAJES ORDS: ${allHerrajes.length}');
    debugPrint('TOTAL MES $selectedMonth/$selectedYear: ${herrajes.length}');
    debugPrint('FILTRO HERRADOR: $idHerrador');
    debugPrint('TOTAL PDF: ${itemsPdf.length}');

    final fileName =
        'reporte_finasangre_${_monthNames[selectedMonth - 1].toLowerCase()}_$selectedYear.pdf';
    final pdfBytes = await pdfReportService.buildMonthlyReportPdf(
      herrajes: itemsPdf,
      month: selectedMonth,
      year: selectedYear,
      herradorNombre: herradorName ?? 'Herrador sin nombre',
      previousMonthTotal: previousTotal,
    );
    _lastPdfBytes = pdfBytes;
    _lastPdfFileName = fileName;

    if (openViewer) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generado: ${itemsPdf.length} herrajes.')),
      );
    }
  }

  List<HerrajeModel> _filterHerrajes(
    List<HerrajeModel> herrajes, {
    required int month,
    required int year,
    int? idHerrador,
  }) {
    return herrajes.where((h) {
      final fecha = h.fechaHerraje ?? DateTime(h.anio, h.mes, h.dia);
      final inMonth = fecha.year == year && fecha.month == month;
      final inHerrador = idHerrador == null || h.idHerrador == idHerrador;
      return inMonth && inHerrador;
    }).toList();
  }

  List<HerrajeView> _buildHerrajeViews(
    List<HerrajeModel> herrajes, {
    required List<CaballoModel> caballos,
    required List<HerradorModel> herradores,
    required List<CorralModel> corrales,
    required List<PreparadorModel> preparadores,
  }) {
    return herrajes.map((h) {
      final caballo =
          caballos.where((c) => c.idCaballo == h.idCaballo).firstOrNull;
      final corral = corrales.where((c) => c.idCorral == h.idCorral).firstOrNull;
      final preparador = caballo == null
          ? null
          : preparadores
              .where((p) => p.idPreparador == caballo.idPreparador)
              .firstOrNull;
      final herrador =
          herradores.where((hr) => hr.idHerrador == h.idHerrador).firstOrNull;
      return HerrajeView(
        herraje: h,
        caballo: caballo?.nombreCaballo ?? 'Caballo ${h.idCaballo}',
        corral: corral == null
            ? 'Corral ${h.idCorral}'
            : [corral.nombreCorral, corral.numeroCorral]
                .where((v) => v.trim().isNotEmpty)
                .join(' '),
        preparador: preparador?.nombreCompleto ?? 'Sin preparador',
        herrador: herrador?.nombreCompleto ?? 'Herrador ${h.idHerrador}',
      );
    }).toList();
  }

  List<CaballoModel> _caballosSinHerrar(
    List<CaballoModel> caballos,
    List<HerrajeModel> herrajesMes,
  ) {
    final herrados = herrajesMes.map((h) => h.idCaballo).toSet();
    return caballos.where((c) {
      final activo = c.activo.toUpperCase() != 'NO';
      return activo && !herrados.contains(c.idCaballo);
    }).toList();
  }

  String _horseLabel(int idCaballo) {
    final caballos = context.read<CaballoProvider>().items;
    final corrales = context.read<CorralProvider>().items;
    final caballo = caballos.where((c) => c.idCaballo == idCaballo).firstOrNull;
    if (caballo == null) return 'Caballo $idCaballo';
    final corral =
        corrales.where((c) => c.idCorral == caballo.idCorral).firstOrNull;
    final corralName = corral == null
        ? 'corral sin nombre'
        : [corral.nombreCorral, corral.numeroCorral]
            .where((v) => v.trim().isNotEmpty)
            .join(' ');
    return '${caballo.nombreCaballo} ($corralName)';
  }

  Future<void> _generateHerrador() async {
    final id = selectedHerrador;
    if (id == null) return;
    await _generatePdf(idHerrador: id, openViewer: false);
  }

  Future<void> _generateAll(bool isOwner) async {
    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Solo OWNER puede generar reporte global.')),
      );
      return;
    }
    await _generatePdf(openViewer: false);
  }

  Future<void> _ensurePdfReady() async {
    if (_lastPdfBytes == null || _lastPdfFileName == null) {
      await _generatePdf(idHerrador: selectedHerrador, openViewer: false);
    }
  }

  Future<void> _viewPdf() async {
    await _ensurePdfReady();
    final bytes = _lastPdfBytes;
    if (bytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _shareWhatsAppPdf() async {
    await _ensurePdfReady();
    final bytes = _lastPdfBytes;
    final fileName = _lastPdfFileName;
    if (bytes == null || fileName == null) return;
    await pdfShareService.compartirPdfWhatsApp(bytes, fileName);
  }

  Future<void> _shareEmailPdf() async {
    await _ensurePdfReady();
    final bytes = _lastPdfBytes;
    final fileName = _lastPdfFileName;
    if (bytes == null || fileName == null) return;
    await pdfShareService.compartirPdfCorreo(bytes, fileName);
  }

  @override
  Widget build(BuildContext context) {
    final reportes = context.watch<ReporteProvider>();
    final herrajes = context.watch<HerrajeProvider>();
    final herradores = context.watch<HerradorProvider>().items;
    final isOwner = context.watch<AuthProvider>().user?.isSystemOwner == true;

    return AppShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Reportes')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          GlassPanel(
            child: Wrap(spacing: 10, runSpacing: 10, children: [
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int>(
                  initialValue: selectedHerrador,
                  decoration: const InputDecoration(labelText: 'Herrador'),
                  items: herradores
                      .where((h) => h.activo == 'SI')
                      .map((h) => DropdownMenuItem(
                            value: h.idHerrador,
                            child: Text(h.nombreCompleto),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedHerrador = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Mes'),
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_monthNames[index]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedMonth = value);
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(labelText: 'Año'),
                  items: List.generate(
                          7, (index) => DateTime.now().year - 3 + index)
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedYear = value);
                  },
                ),
              ),
              NeonButton(
                text: 'Generar PDF herrador',
                icon: Icons.picture_as_pdf,
                onPressed: selectedHerrador == null ? null : _generateHerrador,
              ),
              NeonButton(
                text: 'Generar PDF todos',
                icon: Icons.groups,
                onPressed: () => _generateAll(isOwner),
              ),
              NeonButton(
                text: 'Ver PDF',
                icon: Icons.visibility,
                onPressed: _viewPdf,
              ),
              NeonButton(
                text: 'Compartir WhatsApp',
                icon: Icons.send,
                onPressed: _shareWhatsAppPdf,
              ),
              NeonButton(
                text: 'Enviar correo',
                icon: Icons.email,
                onPressed: _shareEmailPdf,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (reportes.loading || herrajes.loading)
            const LinearProgressIndicator(),
          if (reportes.error != null)
            ErrorState(reportes.error!, onRetry: reportes.cargar),
          if (herrajes.error != null)
            ErrorState(herrajes.error!, onRetry: herrajes.cargar),
          _MonthSummary(
            herrajes: herrajes.items,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            caballosSinHerrar: _caballosSinHerrar(
              context.watch<CaballoProvider>().items,
              _filterHerrajes(
                herrajes.items,
                month: selectedMonth,
                year: selectedYear,
              ),
            ).map((c) => _horseLabel(c.idCaballo)).toList(),
          ),
          const SizedBox(height: 16),
          if (!reportes.loading && reportes.items.isEmpty)
            const EmptyState('Sin registros reales todavia'),
          ...reportes.items.map(
            (r) => Card(
              child: ListTile(
                title: Text('Reporte ${r.mes}/${r.anio}'),
                subtitle: Text('${r.totalHerrajes} herrajes / ${r.estado}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ReporteDetailScreen(reporte: r)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.herrajes,
    required this.selectedMonth,
    required this.selectedYear,
    required this.caballosSinHerrar,
  });

  final List<HerrajeModel> herrajes;
  final int selectedMonth;
  final int selectedYear;
  final List<String> caballosSinHerrar;

  @override
  Widget build(BuildContext context) {
    final monthRows = herrajes.where((h) {
      return h.anio == selectedYear && h.mes == selectedMonth;
    }).toList();
    final completos = monthRows
        .where((h) => h.tipoHerraje.toUpperCase().contains('COMPLETO'))
        .length;
    final manos = monthRows
        .where((h) => h.tipoHerraje.toUpperCase().contains('MANOS'))
        .length;
    final patas = monthRows
        .where((h) => h.tipoHerraje.toUpperCase().contains('PATAS'))
        .length;

    return GlassPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Resumen $selectedMonth/$selectedYear',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (monthRows.isEmpty)
          const EmptyState('Sin herrajes reales este mes')
        else
          Wrap(spacing: 10, runSpacing: 10, children: [
            Chip(label: Text('Completos: $completos')),
            Chip(label: Text('Manos: $manos')),
            Chip(label: Text('Patas: $patas')),
            Chip(
              label: Text('Total: ${monthRows.length}'),
              backgroundColor: AppColors.cyan.withValues(alpha: .16),
            ),
          ]),
        if (caballosSinHerrar.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Quedaron sin herrar en el mes $selectedMonth:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...caballosSinHerrar.map((name) => Text('Quedo $name sin herrar.')),
        ],
      ]),
    );
  }
}
