import 'model_utils.dart';

class UsuarioModel {
  const UsuarioModel({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.email,
    required this.telefono,
    required this.passwordHash,
    required this.rol,
    required this.activo,
  });

  final int idUsuario;
  final String nombreCompleto;
  final String email;
  final String telefono;
  final String passwordHash;
  final String rol;
  final String activo;

  bool get isOwnerOrAdmin {
    final role = rol.toUpperCase();
    return role == 'OWNER' || role == 'ADMIN';
  }

  bool get isOwner => rol.toUpperCase() == 'OWNER';
  bool get isSystemOwner => isOwner && email.toLowerCase().trim() == 'abrahambc';
  bool get isAdmin => rol.toUpperCase() == 'ADMIN';
  bool get isHerrador => rol.toUpperCase() == 'HERRADOR';
  bool get isPreparador => rol.toUpperCase() == 'PREPARADOR';

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return UsuarioModel(
      idUsuario: intValue(map['id_usuario'] ?? map['id']),
      nombreCompleto: stringValue(map['nombre_completo'] ?? map['nombre']),
      email: stringValue(map['email']).toLowerCase(),
      telefono: stringValue(map['telefono']),
      passwordHash: stringValue(map['password_hash']),
      rol: stringValue(map['rol'], 'HERRADOR').toUpperCase(),
      activo: stringValue(map['activo'], 'SI').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idUsuario > 0) 'id_usuario': idUsuario,
        'nombre_completo': nombreCompleto,
        'email': email,
        'telefono': telefono,
        'password_hash': passwordHash,
        'rol': rol,
        'activo': activo,
      };

  UsuarioModel copyWith({
    int? idUsuario,
    String? nombreCompleto,
    String? email,
    String? telefono,
    String? passwordHash,
    String? rol,
    String? activo,
  }) =>
      UsuarioModel(
        idUsuario: idUsuario ?? this.idUsuario,
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        email: email ?? this.email,
        telefono: telefono ?? this.telefono,
        passwordHash: passwordHash ?? this.passwordHash,
        rol: rol ?? this.rol,
        activo: activo ?? this.activo,
      );
}
