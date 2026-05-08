import 'model_utils.dart';

class AuraModel {
  const AuraModel({
    required this.idAura,
    required this.idUsuario,
    required this.tipo,
    required this.mensaje,
    required this.respuesta,
    required this.contexto,
    this.idReferencia,
    this.fecha,
  });

  final int idAura;
  final int idUsuario;
  final String tipo;
  final String mensaje;
  final String respuesta;
  final String contexto;
  final int? idReferencia;
  final DateTime? fecha;

  factory AuraModel.fromJson(Map<String, dynamic> json) => AuraModel(
        idAura: intValue(json['id_aura'] ?? json['id']),
        idUsuario: intValue(json['id_usuario']),
        tipo: stringValue(json['tipo'], 'RESPUESTA').toUpperCase(),
        mensaje: stringValue(json['mensaje']),
        respuesta: stringValue(json['respuesta']),
        contexto: stringValue(json['contexto'], 'GENERAL').toUpperCase(),
        idReferencia: json['id_referencia'] == null
            ? null
            : intValue(json['id_referencia']),
        fecha: dateValue(json['fecha_creacion'] ?? json['fecha']),
      );

  Map<String, dynamic> toJson() => {
        if (idAura > 0) 'id_aura': idAura,
        'id_usuario': idUsuario,
        'tipo': tipo,
        'mensaje': mensaje,
        'respuesta': respuesta,
        'contexto': contexto,
        'id_referencia': idReferencia,
        'fecha_creacion': fecha?.toIso8601String(),
      };
}
