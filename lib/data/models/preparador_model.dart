import 'model_utils.dart';

class PreparadorModel {
  const PreparadorModel({
    required this.idPreparador,
    required this.nombreCompleto,
    required this.telefono,
    required this.email,
    required this.activo,
  });

  final int idPreparador;
  final String nombreCompleto;
  final String telefono;
  final String email;
  final String activo;

  factory PreparadorModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return PreparadorModel(
      idPreparador: intValue(map['id_preparador'] ?? map['id']),
      nombreCompleto: stringValue(map['nombre_completo']),
      telefono: stringValue(map['telefono']),
      email: stringValue(map['email']).toLowerCase(),
      activo: stringValue(map['activo'], 'SI').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idPreparador > 0) 'id_preparador': idPreparador,
        'nombre_completo': nombreCompleto,
        'telefono': telefono,
        'email': email,
        'activo': activo,
      };

  PreparadorModel copyWith({
    int? idPreparador,
    String? nombreCompleto,
    String? telefono,
    String? email,
    String? activo,
  }) =>
      PreparadorModel(
        idPreparador: idPreparador ?? this.idPreparador,
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        telefono: telefono ?? this.telefono,
        email: email ?? this.email,
        activo: activo ?? this.activo,
      );
}
