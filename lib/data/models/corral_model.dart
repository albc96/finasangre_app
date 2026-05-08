import 'model_utils.dart';

class CorralModel {
  const CorralModel({
    required this.idCorral,
    required this.numeroCorral,
    required this.nombreCorral,
    required this.ubicacion,
    required this.capacidad,
    required this.activo,
  });

  final int idCorral;
  final String numeroCorral;
  final String nombreCorral;
  final String ubicacion;
  final int capacidad;
  final String activo;

  factory CorralModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return CorralModel(
      idCorral: intValue(map['id_corral'] ?? map['id']),
      numeroCorral: stringValue(map['numero_corral']),
      nombreCorral: stringValue(map['nombre_corral']),
      ubicacion: stringValue(map['ubicacion']),
      capacidad: intValue(map['capacidad']),
      activo: stringValue(map['activo'], 'SI').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idCorral > 0) 'id_corral': idCorral,
        'numero_corral': numeroCorral,
        'nombre_corral': nombreCorral,
        'ubicacion': ubicacion,
        'capacidad': capacidad,
        'activo': activo,
      };

  CorralModel copyWith({
    int? idCorral,
    String? numeroCorral,
    String? nombreCorral,
    String? ubicacion,
    int? capacidad,
    String? activo,
  }) =>
      CorralModel(
        idCorral: idCorral ?? this.idCorral,
        numeroCorral: numeroCorral ?? this.numeroCorral,
        nombreCorral: nombreCorral ?? this.nombreCorral,
        ubicacion: ubicacion ?? this.ubicacion,
        capacidad: capacidad ?? this.capacidad,
        activo: activo ?? this.activo,
      );
}
