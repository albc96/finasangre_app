import 'model_utils.dart';

class HerrajeModel {
  const HerrajeModel({
    required this.idHerraje,
    required this.idCaballo,
    required this.idHerrador,
    required this.idCorral,
    required this.tipoHerraje,
    this.fechaHerraje,
    required this.dia,
    required this.mes,
    required this.anio,
    required this.hora,
    this.observaciones = '',
    this.fotoAntesUrl = '',
    this.fotoDespuesUrl = '',
  });

  final int idHerraje;
  final int idCaballo;
  final int idHerrador;
  final int idCorral;
  final String tipoHerraje;
  final DateTime? fechaHerraje;
  final int dia;
  final int mes;
  final int anio;
  final String hora;
  final String observaciones;
  final String fotoAntesUrl;
  final String fotoDespuesUrl;

  factory HerrajeModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return HerrajeModel(
      idHerraje: intValue(map['id_herraje'] ?? map['id']),
      idCaballo: intValue(map['id_caballo']),
      idHerrador: intValue(map['id_herrador']),
      idCorral: intValue(map['id_corral']),
      tipoHerraje: stringValue(map['tipo_herraje'], 'COMPLETO'),
      fechaHerraje: dateValue(map['fecha_herraje']),
      dia: intValue(map['dia']),
      mes: intValue(map['mes']),
      anio: intValue(map['anio']),
      hora: stringValue(map['hora']),
      observaciones: stringValue(map['observaciones']),
      fotoAntesUrl: stringValue(map['foto_antes_url']),
      fotoDespuesUrl: stringValue(map['foto_despues_url']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idHerraje > 0) 'id_herraje': idHerraje,
        'id_caballo': idCaballo,
        'id_herrador': idHerrador,
        'id_corral': idCorral,
        'tipo_herraje': tipoHerraje,
        'fecha_herraje': _formatFechaHerrajeForOrds(fechaHerraje),
        'dia': dia,
        'mes': mes,
        'anio': anio,
        'hora': hora,
        'observaciones': observaciones,
        'foto_antes_url': fotoAntesUrl,
        'foto_despues_url': fotoDespuesUrl,
      };

  HerrajeModel copyWith({
    int? idHerraje,
    int? idCaballo,
    int? idHerrador,
    int? idCorral,
    String? tipoHerraje,
    DateTime? fechaHerraje,
    int? dia,
    int? mes,
    int? anio,
    String? hora,
    String? observaciones,
    String? fotoAntesUrl,
    String? fotoDespuesUrl,
  }) =>
      HerrajeModel(
        idHerraje: idHerraje ?? this.idHerraje,
        idCaballo: idCaballo ?? this.idCaballo,
        idHerrador: idHerrador ?? this.idHerrador,
        idCorral: idCorral ?? this.idCorral,
        tipoHerraje: tipoHerraje ?? this.tipoHerraje,
        fechaHerraje: fechaHerraje ?? this.fechaHerraje,
        dia: dia ?? this.dia,
        mes: mes ?? this.mes,
        anio: anio ?? this.anio,
        hora: hora ?? this.hora,
        observaciones: observaciones ?? this.observaciones,
        fotoAntesUrl: fotoAntesUrl ?? this.fotoAntesUrl,
        fotoDespuesUrl: fotoDespuesUrl ?? this.fotoDespuesUrl,
      );
}

String? _formatFechaHerrajeForOrds(DateTime? fecha) {
  if (fecha == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');

  return '${fecha.year}-'
      '${two(fecha.month)}-'
      '${two(fecha.day)}T'
      '${two(fecha.hour)}:'
      '${two(fecha.minute)}:00Z';
}
