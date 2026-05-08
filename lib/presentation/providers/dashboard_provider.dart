import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/caballo_model.dart';
import '../../data/models/corral_model.dart';
import '../../data/models/herraje_model.dart';
import '../../data/models/herrador_model.dart';
import '../../data/models/preparador_model.dart';
import '../../data/models/suscripcion_model.dart';
import '../../data/repositories/caballo_repository.dart';
import '../../data/repositories/corral_repository.dart';
import '../../data/repositories/herraje_repository.dart';
import '../../data/repositories/herrador_repository.dart';
import '../../data/repositories/preparador_repository.dart';
import '../../data/repositories/suscripcion_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required this.caballos,
    required this.corrales,
    required this.herradores,
    required this.herrajes,
    required this.preparadores,
    required this.suscripciones,
  });

  final CaballoRepository caballos;
  final CorralRepository corrales;
  final HerradorRepository herradores;
  final HerrajeRepository herrajes;
  final PreparadorRepository preparadores;
  final SuscripcionRepository suscripciones;

  bool loading = false;
  String? error;
  List<CaballoModel> caballosData = [];
  List<CorralModel> corralesData = [];
  List<HerradorModel> herradoresData = [];
  List<HerrajeModel> herrajesData = [];
  List<PreparadorModel> preparadoresData = [];
  List<SuscripcionModel> suscripcionesData = [];
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  int? selectedHerradorId;
  int? selectedCorralId;
  String selectedTipo = 'TODOS';

  DateTime herrajeDate(HerrajeModel h) {
    final parsed = h.fechaHerraje;
    if (parsed != null) return parsed;
    return DateTime(h.anio, h.mes.clamp(1, 12), h.dia.clamp(1, 28));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameMonth(DateTime date, int month, int year) =>
      date.year == year && date.month == month;

  List<HerrajeModel> get filteredHerrajes => herrajesData.where((h) {
        final date = herrajeDate(h);
        final samePeriod = _sameMonth(date, selectedMonth, selectedYear);
        final herradorOk =
            selectedHerradorId == null || h.idHerrador == selectedHerradorId;
        final corralOk = selectedCorralId == null || h.idCorral == selectedCorralId;
        final tipoOk = selectedTipo == 'TODOS' ||
            h.tipoHerraje.trim().toUpperCase() == selectedTipo;
        return samePeriod && herradorOk && corralOk && tipoOk;
      }).toList();

  int get herrajesHoy {
    final now = DateTime.now();
    return herrajesData.where((h) {
      return _sameDay(herrajeDate(h), now);
    }).length;
  }

  int get herrajesMes => herrajesData
      .where((h) => _sameMonth(herrajeDate(h), selectedMonth, selectedYear))
      .length;

  int get caballosActivos =>
      caballosData.where((c) => c.activo.toUpperCase() == 'SI').length;

  int get herradoresActivos =>
      herradoresData.where((h) => h.activo.toUpperCase() == 'SI').length;

  int get corralesActivos =>
      corralesData.where((c) => c.activo.toUpperCase() == 'SI').length;

  int get suscripcionesVencidas {
    final now = DateTime.now();
    if (now.day <= 7) return 0;
    return suscripcionesData
        .where((s) => s.mes == now.month && s.anio == now.year && !s.pagado)
        .length;
  }

  int get previousMonthTotal {
    final previous = DateTime(selectedYear, selectedMonth - 1);
    return herrajesData
        .where((h) => _sameMonth(herrajeDate(h), previous.month, previous.year))
        .length;
  }

  Map<int, int> get herrajesPorDia {
    final days = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final values = {for (var day = 1; day <= days; day++) day: 0};
    for (final h in filteredHerrajes) {
      final date = herrajeDate(h);
      values[date.day] = (values[date.day] ?? 0) + 1;
    }
    return values;
  }

  Map<String, int> get distribucionTipo {
    final values = {'COMPLETO': 0, 'MANOS': 0, 'PATAS': 0};
    for (final h in filteredHerrajes) {
      final tipo = h.tipoHerraje.trim().toUpperCase();
      if (values.containsKey(tipo)) values[tipo] = values[tipo]! + 1;
    }
    return values;
  }

  Map<String, int> get rankingHerrador {
    final values = <String, int>{};
    for (final h in filteredHerrajes) {
      final name = herradorNombre(h.idHerrador);
      values[name] = (values[name] ?? 0) + 1;
    }
    return _sortedTop(values);
  }

  Map<String, int> get actividadCorral {
    final values = <String, int>{};
    for (final h in filteredHerrajes) {
      final name = corralNombre(h.idCorral);
      values[name] = (values[name] ?? 0) + 1;
    }
    return _sortedTop(values);
  }

  List<CaballoModel> get caballosSinHerraje30Dias {
    final limit = DateTime.now().subtract(const Duration(days: 30));
    return caballosData.where((caballo) {
      if (caballo.activo.toUpperCase() != 'SI') return false;
      final rows = herrajesData
          .where((h) => h.idCaballo == caballo.idCaballo)
          .map(herrajeDate)
          .toList()
        ..sort();
      return rows.isEmpty || rows.last.isBefore(limit);
    }).toList();
  }

  List<HerradorModel> get herradoresBloqueados => herradoresData
      .where((h) => h.activo.toUpperCase() != 'SI')
      .toList();

  String get auraResumen {
    final current = herrajesMes;
    final previous = previousMonthTotal;
    final diff = current - previous;
    final pct = previous == 0 ? 0 : ((diff.abs() / previous) * 100).round();
    final trend = previous == 0
        ? 'Sin base del mes anterior; este mes registra $current herrajes.'
        : diff > 0
            ? 'Este mes aumentaron los herrajes un $pct% respecto al mes anterior.'
            : diff < 0
                ? 'Este mes bajaron los herrajes un $pct% respecto al mes anterior.'
                : 'Este mes se mantuvieron los herrajes respecto al mes anterior.';
    final top = rankingHerrador.entries.firstOrNull;
    return '$trend Herrador con mayor carga: ${top?.key ?? 'sin registros'} (${top?.value ?? 0}). Hay ${caballosSinHerraje30Dias.length} caballos sin herraje hace 30 dias, $suscripcionesVencidas suscripciones vencidas y ${herradoresBloqueados.length} herradores bloqueados.';
  }

  void setFilters({
    int? month,
    int? year,
    int? herradorId,
    int? corralId,
    String? tipo,
    bool clearHerrador = false,
    bool clearCorral = false,
  }) {
    selectedMonth = month ?? selectedMonth;
    selectedYear = year ?? selectedYear;
    selectedHerradorId = clearHerrador ? null : herradorId ?? selectedHerradorId;
    selectedCorralId = clearCorral ? null : corralId ?? selectedCorralId;
    selectedTipo = tipo ?? selectedTipo;
    notifyListeners();
  }

  Map<String, int> _sortedTop(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(8));
  }

  String caballoNombre(int id) =>
      caballosData
          .where((c) => c.idCaballo == id)
          .map((c) => c.nombreCaballo)
          .firstOrNull ??
      'Caballo sin nombre';

  String herradorNombre(int id) =>
      herradoresData
          .where((h) => h.idHerrador == id)
          .map((h) => h.nombreCompleto)
          .firstOrNull ??
      'Herrador sin nombre';

  String corralNombre(int id) {
    final corral = corralesData.where((c) => c.idCorral == id).firstOrNull;
    if (corral == null) return 'Corral sin nombre';
    return [corral.nombreCorral, corral.numeroCorral]
        .where((v) => v.trim().isNotEmpty)
        .join(' ');
  }

  String preparadorNombre(int id) =>
      preparadoresData
          .where((p) => p.idPreparador == id)
          .map((p) => p.nombreCompleto)
          .firstOrNull ??
      'Preparador sin nombre';

  Future<void> cargar() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        caballos.list().timeout(const Duration(seconds: 15)),
        corrales.list().timeout(const Duration(seconds: 15)),
        herradores.list().timeout(const Duration(seconds: 15)),
        herrajes.list().timeout(const Duration(seconds: 15)),
        preparadores.list().timeout(const Duration(seconds: 15)),
        suscripciones.list().timeout(const Duration(seconds: 15)),
      ]).timeout(const Duration(seconds: 20));
      caballosData = results[0] as List<CaballoModel>;
      corralesData = results[1] as List<CorralModel>;
      herradoresData = results[2] as List<HerradorModel>;
      herrajesData = results[3] as List<HerrajeModel>;
      preparadoresData = results[4] as List<PreparadorModel>;
      suscripcionesData = results[5] as List<SuscripcionModel>;
    } on TimeoutException catch (_) {
      error =
          'Error de conexión o servidor no responde. Por favor, revisa tu internet e intenta nuevamente.';
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
