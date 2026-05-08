import 'package:flutter/foundation.dart';

import '../../data/models/aura_model.dart';
import '../../data/repositories/aura_repository.dart';
import '../../data/services/audit_service.dart';
import '../../data/services/aura_brain.dart';

class AuraMessage {
  const AuraMessage({required this.role, required this.text});
  final String role;
  final String text;
}

class AuraProvider extends ChangeNotifier {
  AuraProvider({
    required AuraRepository repository,
    required AuraBrain brain,
    required AuditService auditService,
  })  : _repository = repository,
        _brain = brain,
        _auditService = auditService;

  final AuraRepository _repository;
  final AuraBrain _brain;
  final AuditService _auditService;

  bool loading = false;
  String? error;
  int? idUsuario;

  final List<AuraMessage> messages = [
    const AuraMessage(
      role: 'aura',
      text:
          'Hola, soy AURA. Puedo buscar caballos, herrajes, corrales, reportes y suscripciones con datos reales.',
    ),
  ];

  String? get lastAuraResponse {
    return messages.reversed
        .where((message) => message.role == 'aura')
        .map((message) => message.text)
        .firstOrNull;
  }

  Future<void> cargarHistorial(int? userId) async {
    idUsuario = userId;
    if (userId == null) return;
    final history = await _repository.obtenerHistorial(userId);
    if (history.isEmpty) return;
    messages
      ..clear()
      ..addAll(history.expand((item) {
        return [
          if (item.mensaje.trim().isNotEmpty)
            AuraMessage(role: 'user', text: item.mensaje),
          if (item.respuesta.trim().isNotEmpty)
            AuraMessage(role: 'aura', text: item.respuesta),
        ];
      }));
    notifyListeners();
  }

  Future<void> send(String text) => enviarMensaje(text);

  Future<void> quick(String label) => enviarMensaje(label);

  Future<void> enviarMensaje(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    messages.add(AuraMessage(role: 'user', text: clean));
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await procesarConsulta(clean);
      messages.add(AuraMessage(role: 'aura', text: result.response));
      await _guardar(
        clean,
        result.response,
        result.contexto,
        result.idReferencia,
      );
      await _auditService.record(
        action: 'CONSULTA',
        module: 'AURA',
        detail: clean,
        userId: idUsuario,
      );
    } catch (e) {
      error = e.toString();
      messages.add(const AuraMessage(
        role: 'aura',
        text:
            'No pude consultar ORDS en este momento. Revisa conexion o endpoints AURA.',
      ));
    }

    loading = false;
    notifyListeners();
  }

  Future<AuraBrainResult> procesarConsulta(String query) {
    return _brain.process(query);
  }

  Future<void> limpiarHistorial() async {
    final userId = idUsuario;
    messages
      ..clear()
      ..add(const AuraMessage(
        role: 'aura',
        text: 'Historial limpio. Estoy lista para una nueva consulta.',
      ));
    notifyListeners();
    if (userId != null) await _repository.limpiarHistorial(userId);
  }

  Future<void> _guardar(
    String mensaje,
    String respuesta,
    String contexto,
    int? idReferencia,
  ) async {
    final userId = idUsuario;
    if (userId == null) return;
    await _repository.guardarMensaje(AuraModel(
      idAura: 0,
      idUsuario: userId,
      tipo: 'RESPUESTA',
      mensaje: mensaje,
      respuesta: respuesta,
      contexto: contexto,
      idReferencia: idReferencia,
      fecha: DateTime.now(),
    ));
  }
}
