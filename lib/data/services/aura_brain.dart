import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../models/caballo_model.dart';
import '../models/corral_model.dart';
import '../models/herraje_model.dart';
import '../models/herrador_model.dart';
import '../models/preparador_model.dart';
import '../models/reporte_model.dart';
import '../models/suscripcion_model.dart';
import '../models/usuario_model.dart';
import 'ords_client.dart';

class AuraBrainResult {
  const AuraBrainResult({
    required this.response,
    required this.contexto,
    this.idReferencia,
  });

  final String response;
  final String contexto;
  final int? idReferencia;
}

class AuraBrain {
  AuraBrain(this.client);

  final OrdsClient client;

  Future<AuraBrainResult> process(String query) async {
    final data = await _AuraData.load(client);
    final q = normalizeText(query);
    final intent = detectIntent(q);

    if (intent == 'herrajes_hoy') {
      return AuraBrainResult(
        response: _listHerrajes(data.herrajes.where(_isToday), data,
            empty: 'Hoy no hay herrajes registrados.'),
        contexto: 'HERRAJE',
      );
    }
    if (intent == 'herrajes_ayer') {
      return AuraBrainResult(
        response: _listHerrajes(data.herrajes.where(_isYesterday), data,
            empty: 'Ayer no hay herrajes registrados.'),
        contexto: 'HERRAJE',
      );
    }
    if (intent == 'herrajes_mes') {
      final now = DateTime.now();
      return AuraBrainResult(
        response: _listHerrajes(
          data.herrajes.where((h) => _sameMonth(h, now)),
          data,
          empty: 'Este mes no hay herrajes registrados.',
        ),
        contexto: 'HERRAJE',
      );
    }
    if (intent == 'reporte') {
      return AuraBrainResult(
        response: _buildReporte(data),
        contexto: 'REPORTE',
      );
    }
    if (intent == 'inactivos') {
      return AuraBrainResult(
        response: _inactiveHorses(data, 30),
        contexto: 'HERRAJE',
      );
    }
    if (intent == 'suscripcion') {
      return AuraBrainResult(
        response: _subscriptionStatus(data, q),
        contexto: 'SUSCRIPCION',
      );
    }

    final corral = _findCorralQuery(q);
    if (corral != null) {
      final found = data.findCorral(corral);
      if (found == null) {
        return AuraBrainResult(
          response: 'No encontre ese corral o nave.',
          contexto: 'CABALLO',
        );
      }
      final horses =
          data.caballos.where((c) => c.idCorral == found.idCorral).toList();
      return AuraBrainResult(
        response: horses.isEmpty
            ? 'Sin registros reales todavia para ${data.corralName(found.idCorral)}.'
            : 'Caballos de ${data.corralName(found.idCorral)}:\n'
                '${horses.map((c) => c.nombreCaballo).join('\n')}',
        contexto: 'CABALLO',
        idReferencia: found.idCorral,
      );
    }

    final herradorName = _extractAfter(q, [
      'buscar herrador',
      'herrajes de',
      'cuantos herrajes hizo',
      'cuántos herrajes hizo',
      'reporte del herrador',
    ]);
    if (herradorName != null) {
      final herrador = data.findHerrador(herradorName);
      if (herrador == null) {
        return AuraBrainResult(
          response: 'No encontre herradores reales para "$herradorName".',
          contexto: 'HERRADOR',
        );
      }
      final now = DateTime.now();
      final herrajes = data.herrajes
          .where((h) => h.idHerrador == herrador.idHerrador)
          .where((h) => q.contains('mes') ? _sameMonth(h, now) : true)
          .toList();
      return AuraBrainResult(
        response: '${herrador.nombreCompleto}\n'
            'Telefono: ${herrador.telefono.isEmpty ? 'Sin telefono' : herrador.telefono}\n'
            'Email: ${herrador.email.isEmpty ? 'Sin email' : herrador.email}\n'
            'Herrajes encontrados: ${herrajes.length}',
        contexto: 'HERRADOR',
        idReferencia: herrador.idHerrador,
      );
    }

    final horseName = _extractHorseName(q);
    if (horseName != null) {
      final horse = data.findCaballo(horseName);
      if (horse == null) {
        return AuraBrainResult(
          response: 'No encontre el caballo "$horseName" en ORDS.',
          contexto: 'CABALLO',
        );
      }
      if (q.contains('ultimo herraje') || q.contains('herraje completo')) {
        final last = data.lastHerrajeFor(horse.idCaballo);
        return AuraBrainResult(
          response: last == null
              ? '${horse.nombreCaballo} no tiene herrajes registrados.'
              : 'Ultimo herraje de ${horse.nombreCaballo}:\n${data.describeHerraje(last)}',
          contexto: 'HERRAJE',
          idReferencia: horse.idCaballo,
        );
      }
      if (q.contains('edad')) {
        return AuraBrainResult(
          response: '${horse.nombreCaballo} tiene ${horse.edad} anos.',
          contexto: 'CABALLO',
          idReferencia: horse.idCaballo,
        );
      }
      if (q.contains('preparador')) {
        return AuraBrainResult(
          response:
              'Preparador de ${horse.nombreCaballo}: ${data.preparadorName(horse.idPreparador)}',
          contexto: 'CABALLO',
          idReferencia: horse.idCaballo,
        );
      }
      if (q.contains('corral')) {
        return AuraBrainResult(
          response:
              '${horse.nombreCaballo} esta en ${data.corralName(horse.idCorral)}.',
          contexto: 'CABALLO',
          idReferencia: horse.idCaballo,
        );
      }
      return AuraBrainResult(
        response: data.describeCaballo(horse),
        contexto: 'CABALLO',
        idReferencia: horse.idCaballo,
      );
    }

    return const AuraBrainResult(
      response: 'Puedo buscar caballos, ultimo herraje, herrajes de hoy, '
          'caballos por corral, herradores, reportes del mes y caballos sin herraje hace 30 dias.',
      contexto: 'GENERAL',
    );
  }

  String normalizeText(String text) => _fold(text);

  String detectIntent(String q) {
    if (q.contains('hoy')) return 'herrajes_hoy';
    if (q.contains('ayer')) return 'herrajes_ayer';
    if (q.contains('este mes') || q.contains('del mes')) return 'herrajes_mes';
    if (q.contains('reporte') || q.contains('generar pdf')) return 'reporte';
    if (q.contains('sin herraje') || q.contains('falta por herraje')) {
      return 'inactivos';
    }
    if (q.contains('no ha pagado') ||
        q.contains('bloqueados') ||
        q.contains('mensualidades')) {
      return 'suscripcion';
    }
    return 'general';
  }

  String? _extractHorseName(String q) {
    return _extractAfter(q, const [
      'buscar caballo',
      'ficha de',
      'ver ficha',
      'edad de',
      'preparador tiene',
      'que preparador tiene',
      'en que corral esta',
      'ultimo herraje de',
      'herraje completo de',
    ]);
  }

  String? _extractAfter(String q, List<String> prefixes) {
    for (final prefix in prefixes) {
      final index = q.indexOf(prefix);
      if (index >= 0) {
        final value = q.substring(index + prefix.length).trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  String? _findCorralQuery(String q) {
    final match = RegExp(r'(corral|nave)\s+([a-z0-9 ]+)').firstMatch(q);
    return match?.group(2)?.trim();
  }

  bool _isToday(HerrajeModel h) {
    final now = DateTime.now();
    final f = h.fechaHerraje;
    if (f != null) return _sameDate(f, now);
    return h.dia == now.day && h.mes == now.month && h.anio == now.year;
  }

  bool _isYesterday(HerrajeModel h) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final f = h.fechaHerraje;
    if (f != null) return _sameDate(f, yesterday);
    return h.dia == yesterday.day &&
        h.mes == yesterday.month &&
        h.anio == yesterday.year;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameMonth(HerrajeModel h, DateTime now) {
    final f = h.fechaHerraje;
    if (f != null) return f.year == now.year && f.month == now.month;
    return h.mes == now.month && h.anio == now.year;
  }

  String _listHerrajes(
    Iterable<HerrajeModel> herrajes,
    _AuraData data, {
    required String empty,
  }) {
    final list = herrajes.toList();
    if (list.isEmpty) return empty;
    return list.take(12).map(data.describeHerraje).join('\n\n');
  }

  String _buildReporte(_AuraData data) {
    final now = DateTime.now();
    final rows = data.herrajes.where((h) => _sameMonth(h, now)).toList();
    final completos =
        rows.where((h) => _fold(h.tipoHerraje).contains('completo')).length;
    final manos =
        rows.where((h) => _fold(h.tipoHerraje).contains('manos')).length;
    final patas =
        rows.where((h) => _fold(h.tipoHerraje).contains('patas')).length;
    return 'Reporte ${now.month}/${now.year}\n'
        'Completos: $completos\n'
        'Manos: $manos\n'
        'Patas: $patas\n'
        'Total general: ${rows.length}';
  }

  String _subscriptionStatus(_AuraData data, String q) {
    final pending = data.suscripciones.where((s) {
      final estado = s.estado.toUpperCase();
      return !s.pagado || estado == 'PENDIENTE' || estado == 'BLOQUEADA';
    }).toList();
    if (pending.isEmpty) {
      return 'No encontre mensualidades pendientes ni bloqueadas.';
    }
    final blocked =
        pending.where((s) => s.estado.toUpperCase() == 'BLOQUEADA').toList();
    final rows = (q.contains('bloquead') ? blocked : pending).take(12);
    if (rows.isEmpty) return 'No encontre herradores bloqueados.';
    return rows.map((s) {
      final user = data.usuarioName(s.idUsuario);
      final paid = s.pagado ? 'pagado' : 'pendiente';
      return '$user: ${s.estado} $paid ${s.mes}/${s.anio}';
    }).join('\n');
  }

  String _inactiveHorses(_AuraData data, int days) {
    final limit = DateTime.now().subtract(Duration(days: days));
    final missing = data.caballos.where((horse) {
      final last = data.lastHerrajeFor(horse.idCaballo);
      if (last == null) return true;
      return data.herrajeDate(last).isBefore(limit);
    }).toList();
    if (missing.isEmpty) {
      return 'No encontre caballos sin herraje hace mas de $days dias.';
    }
    return 'Caballos sin herraje hace mas de $days dias:\n'
        '${missing.map((c) => c.nombreCaballo).join('\n')}';
  }
}

class _AuraData {
  const _AuraData({
    required this.caballos,
    required this.corrales,
    required this.preparadores,
    required this.herradores,
    required this.herrajes,
    required this.reportes,
    required this.suscripciones,
    required this.usuarios,
  });

  final List<CaballoModel> caballos;
  final List<CorralModel> corrales;
  final List<PreparadorModel> preparadores;
  final List<HerradorModel> herradores;
  final List<HerrajeModel> herrajes;
  final List<ReporteModel> reportes;
  final List<SuscripcionModel> suscripciones;
  final List<UsuarioModel> usuarios;

  static Future<_AuraData> load(OrdsClient client) async {
    final rows = await Future.wait([
      client.getList(OrdsEndpoints.caballos),
      client.getList(OrdsEndpoints.corrales),
      client.getList(OrdsEndpoints.preparadores),
      client.getList(OrdsEndpoints.herradores),
      client.getList(OrdsEndpoints.herrajes),
      client.getList(OrdsEndpoints.reportes),
      client.getList(OrdsEndpoints.suscripciones),
      client.getList(OrdsEndpoints.usuarios),
    ]);
    return _AuraData(
      caballos: rows[0].map(CaballoModel.fromJson).toList(),
      corrales: rows[1].map(CorralModel.fromJson).toList(),
      preparadores: rows[2].map(PreparadorModel.fromJson).toList(),
      herradores: rows[3].map(HerradorModel.fromJson).toList(),
      herrajes: rows[4].map(HerrajeModel.fromJson).toList(),
      reportes: rows[5].map(ReporteModel.fromJson).toList(),
      suscripciones: rows[6].map(SuscripcionModel.fromJson).toList(),
      usuarios: rows[7].map(UsuarioModel.fromJson).toList(),
    );
  }

  CaballoModel? findCaballo(String name) {
    final needle = _fold(name);
    return caballos.where((c) {
      final value = _fold(c.nombreCaballo);
      return value.contains(needle) || _loose(value, needle);
    }).firstOrNull;
  }

  HerradorModel? findHerrador(String name) {
    final needle = _fold(name);
    return herradores.where((h) {
      final value = _fold(h.nombreCompleto);
      return value.contains(needle) || _loose(value, needle);
    }).firstOrNull;
  }

  CorralModel? findCorral(String query) {
    final needle = _fold(query);
    return corrales.where((c) {
      return _fold(c.numeroCorral).contains(needle) ||
          _fold(c.nombreCorral).contains(needle) ||
          _fold(c.ubicacion).contains(needle);
    }).firstOrNull;
  }

  HerrajeModel? lastHerrajeFor(int horseId) {
    final rows = herrajes.where((h) => h.idCaballo == horseId).toList()
      ..sort((a, b) => herrajeDate(b).compareTo(herrajeDate(a)));
    return rows.firstOrNull;
  }

  DateTime herrajeDate(HerrajeModel h) {
    return h.fechaHerraje ??
        DateTime(
          h.anio == 0 ? 1900 : h.anio,
          h.mes == 0 ? 1 : h.mes,
          h.dia == 0 ? 1 : h.dia,
        );
  }

  String describeCaballo(CaballoModel c) {
    final last = lastHerrajeFor(c.idCaballo);
    return 'Encontre a ${c.nombreCaballo}\n'
        'Edad: ${c.edad} anos\n'
        'Sexo: ${c.sexo.isEmpty ? 'Sin dato' : c.sexo}\n'
        'Color: ${c.color.isEmpty ? 'Sin dato' : c.color}\n'
        'Corral: ${corralName(c.idCorral)}\n'
        'Preparador: ${preparadorName(c.idPreparador)}\n\n'
        'Ultimo herraje:\n'
        '${last == null ? 'Sin herrajes registrados' : describeHerraje(last)}';
  }

  String describeHerraje(HerrajeModel h) {
    return 'Caballo: ${caballoName(h.idCaballo)}\n'
        'Tipo: ${h.tipoHerraje}\n'
        'Fecha: ${formatDate(h)}\n'
        'Hora: ${h.hora.isEmpty ? 'Sin hora' : h.hora}\n'
        'Herrador: ${herradorName(h.idHerrador)}\n'
        'Corral: ${corralName(h.idCorral)}';
  }

  String caballoName(int id) =>
      caballos
          .where((c) => c.idCaballo == id)
          .map((c) => c.nombreCaballo)
          .firstOrNull ??
      'Caballo sin nombre';

  String corralName(int id) {
    final c = corrales.where((c) => c.idCorral == id).firstOrNull;
    if (c == null) return 'Corral sin nombre';
    return [c.nombreCorral, c.numeroCorral]
        .where((v) => v.trim().isNotEmpty)
        .join(' ');
  }

  String preparadorName(int id) =>
      preparadores
          .where((p) => p.idPreparador == id)
          .map((p) => p.nombreCompleto)
          .firstOrNull ??
      'Preparador sin nombre';

  String herradorName(int id) =>
      herradores
          .where((h) => h.idHerrador == id)
          .map((h) => h.nombreCompleto)
          .firstOrNull ??
      'Herrador sin nombre';

  String usuarioName(int id) =>
      usuarios
          .where((u) => u.idUsuario == id)
          .map((u) => u.nombreCompleto.isEmpty ? u.email : u.nombreCompleto)
          .firstOrNull ??
      'Usuario sin nombre';

  String formatDate(HerrajeModel h) {
    final date = h.fechaHerraje;
    if (date != null) return DateFormat('dd/MM/yyyy').format(date);
    if (h.dia > 0 && h.mes > 0 && h.anio > 0) {
      return '${h.dia.toString().padLeft(2, '0')}/${h.mes.toString().padLeft(2, '0')}/${h.anio}';
    }
    return 'Sin fecha';
  }

  bool _loose(String value, String needle) {
    if (needle.length < 4) return false;
    var hits = 0;
    for (final part in needle.split(' ')) {
      if (part.isNotEmpty && value.contains(part)) hits++;
    }
    return hits > 0;
  }
}

String _fold(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var text = value.toLowerCase().trim();
  accents.forEach((from, to) => text = text.replaceAll(from, to));
  return text.replaceAll(RegExp(r'\s+'), ' ');
}
