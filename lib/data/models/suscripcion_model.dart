import 'model_utils.dart';

class SuscripcionModel {
  const SuscripcionModel({
    required this.id,
    required this.idUsuario,
    required this.mes,
    required this.anio,
    required this.estado,
    this.fechaLimitePago,
    required this.pagado,
  });

  final int id;
  final int idUsuario;
  final int mes;
  final int anio;
  final String estado;
  final DateTime? fechaLimitePago;
  final bool pagado;

  bool get bloqueada => estado.toUpperCase() == 'BLOQUEADA';

  factory SuscripcionModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return SuscripcionModel(
      id: intValue(map['id_suscripcion'] ?? map['id']),
      idUsuario: intValue(map['id_usuario']),
      mes: intValue(map['mes']),
      anio: intValue(map['anio']),
      estado: stringValue(map['estado'], 'GRACIA').toUpperCase(),
      fechaLimitePago: dateValue(map['fecha_limite_pago']),
      pagado: boolValue(map['pagado']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id > 0) 'id_suscripcion': id,
        'id_usuario': idUsuario,
        'mes': mes,
        'anio': anio,
        'estado': estado,
        'fecha_limite_pago': fechaLimitePago?.toIso8601String(),
        'pagado': pagado ? 'SI' : 'NO',
      };

  SuscripcionModel copyWith({
    int? id,
    int? idUsuario,
    int? mes,
    int? anio,
    String? estado,
    DateTime? fechaLimitePago,
    bool? pagado,
  }) =>
      SuscripcionModel(
        id: id ?? this.id,
        idUsuario: idUsuario ?? this.idUsuario,
        mes: mes ?? this.mes,
        anio: anio ?? this.anio,
        estado: estado ?? this.estado,
        fechaLimitePago: fechaLimitePago ?? this.fechaLimitePago,
        pagado: pagado ?? this.pagado,
      );
}
