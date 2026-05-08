import 'model_utils.dart';

class CaballoModel {
  const CaballoModel({
    required this.idCaballo,
    required this.nombreCaballo,
    required this.edad,
    this.fechaNacimiento,
    required this.idCorral,
    required this.idPreparador,
    required this.sexo,
    required this.color,
    this.activo = 'SI',
    this.fotoUrl = '',
  });

  final int idCaballo;
  final String nombreCaballo;
  final int edad;
  final DateTime? fechaNacimiento;
  final int idCorral;
  final int idPreparador;
  final String sexo;
  final String color;
  final String activo;
  final String fotoUrl;

  factory CaballoModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return CaballoModel(
      idCaballo: intValue(map['id_caballo'] ?? map['id']),
      nombreCaballo: stringValue(map['nombre_caballo']),
      edad: intValue(map['edad']),
      fechaNacimiento: dateValue(map['fecha_nacimiento']),
      idCorral: intValue(map['id_corral']),
      idPreparador: intValue(map['id_preparador']),
      sexo: stringValue(map['sexo']),
      color: stringValue(map['color']),
      activo: stringValue(map['activo'], 'SI').toUpperCase(),
      fotoUrl: stringValue(map['foto_url']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idCaballo > 0) 'id_caballo': idCaballo,
        'nombre_caballo': nombreCaballo,
        'edad': edad,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'id_corral': idCorral,
        'id_preparador': idPreparador,
        'sexo': sexo,
        'color': color,
        'activo': activo,
        'foto_url': fotoUrl,
      };

  CaballoModel copyWith({
    int? idCaballo,
    String? nombreCaballo,
    int? edad,
    DateTime? fechaNacimiento,
    int? idCorral,
    int? idPreparador,
    String? sexo,
    String? color,
    String? activo,
    String? fotoUrl,
  }) =>
      CaballoModel(
        idCaballo: idCaballo ?? this.idCaballo,
        nombreCaballo: nombreCaballo ?? this.nombreCaballo,
        edad: edad ?? this.edad,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
        idCorral: idCorral ?? this.idCorral,
        idPreparador: idPreparador ?? this.idPreparador,
        sexo: sexo ?? this.sexo,
        color: color ?? this.color,
        activo: activo ?? this.activo,
        fotoUrl: fotoUrl ?? this.fotoUrl,
      );
}
