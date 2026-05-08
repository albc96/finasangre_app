import 'model_utils.dart';

class ReporteModel {
  const ReporteModel({
    required this.idReporte,
    required this.idHerrador,
    this.periodoInicio,
    this.periodoFin,
    required this.mes,
    required this.anio,
    required this.totalHerrajes,
    required this.pdfUrl,
    required this.enviadoWhatsapp,
    required this.enviadoCorreo,
    required this.estado,
    this.tipoReporte = 'HERRADOR',
    this.fechaCreacion,
  });

  final int idReporte;
  final int? idHerrador;
  final DateTime? periodoInicio;
  final DateTime? periodoFin;
  final int mes;
  final int anio;
  final int totalHerrajes;
  final String pdfUrl;
  final bool enviadoWhatsapp;
  final bool enviadoCorreo;
  final String estado;
  final String tipoReporte;
  final DateTime? fechaCreacion;

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    final map = normalizeKeys(json);
    return ReporteModel(
      idReporte: intValue(map['id_reporte'] ?? map['id']),
      idHerrador:
          map['id_herrador'] == null ? null : intValue(map['id_herrador']),
      periodoInicio: dateValue(map['periodo_inicio']),
      periodoFin: dateValue(map['periodo_fin']),
      mes: intValue(map['mes']),
      anio: intValue(map['anio']),
      totalHerrajes: intValue(map['total_herrajes']),
      pdfUrl: stringValue(map['pdf_url']),
      enviadoWhatsapp: boolValue(map['enviado_whatsapp']),
      enviadoCorreo: boolValue(map['enviado_correo']),
      estado: stringValue(map['estado'], 'GENERADO'),
      tipoReporte: stringValue(map['tipo_reporte'], 'HERRADOR'),
      fechaCreacion: dateValue(map['fecha_creacion']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idReporte > 0) 'id_reporte': idReporte,
        'id_herrador': idHerrador,
        'periodo_inicio': periodoInicio?.toIso8601String(),
        'periodo_fin': periodoFin?.toIso8601String(),
        'mes': mes,
        'anio': anio,
        'total_herrajes': totalHerrajes,
        'pdf_url': pdfUrl,
        'enviado_whatsapp': enviadoWhatsapp ? 'SI' : 'NO',
        'enviado_correo': enviadoCorreo ? 'SI' : 'NO',
        'estado': estado,
        'tipo_reporte': tipoReporte,
      };
}
