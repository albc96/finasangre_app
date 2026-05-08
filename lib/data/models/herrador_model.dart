import 'model_utils.dart';

class HerradorModel {
  const HerradorModel({
    required this.idHerrador,
    required this.idUsuario,
    required this.codigoHerrador,
    required this.nombreCompleto,
    required this.telefono,
    required this.email,
    required this.activo,
  });

  final int idHerrador;
  final int idUsuario;
  final String codigoHerrador;
  final String nombreCompleto;
  final String telefono;
  final String email;
  final String activo;

  factory HerradorModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return HerradorModel(
      idHerrador: intValue(map['id_herrador'] ?? map['id']),
      idUsuario: intValue(map['id_usuario']),
      codigoHerrador: stringValue(map['codigo_herrador']),
      nombreCompleto: stringValue(map['nombre_completo']),
      telefono: stringValue(map['telefono']),
      email: stringValue(map['email']).toLowerCase(),
      activo: stringValue(map['activo'], 'SI').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idHerrador > 0) 'id_herrador': idHerrador,
        'id_usuario': idUsuario,
        'codigo_herrador': codigoHerrador,
        'nombre_completo': nombreCompleto,
        'telefono': telefono,
        'email': email,
        'activo': activo,
      };

  HerradorModel copyWith({
    int? idHerrador,
    int? idUsuario,
    String? codigoHerrador,
    String? nombreCompleto,
    String? telefono,
    String? email,
    String? activo,
  }) =>
      HerradorModel(
        idHerrador: idHerrador ?? this.idHerrador,
        idUsuario: idUsuario ?? this.idUsuario,
        codigoHerrador: codigoHerrador ?? this.codigoHerrador,
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        telefono: telefono ?? this.telefono,
        email: email ?? this.email,
        activo: activo ?? this.activo,
      );
}
