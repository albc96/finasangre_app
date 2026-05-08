import '../../core/config/app_config.dart';
import 'offline_cache_service.dart';
import 'ords_client.dart';

class AuditService {
  AuditService(this.client, {OfflineCacheService? offlineCache})
      : _offlineCache = offlineCache;

  final OrdsClient client;
  final OfflineCacheService? _offlineCache;

  Future<void> record({
    required String action,
    String module = 'APP',
    String? detail,
    int? userId,
  }) async {
    final payload = {
      'accion': action,
      'modulo': module,
      'detalle': detail ?? '',
      if (userId != null) 'id_usuario': userId,
      'fecha_evento': DateTime.now().toIso8601String(),
    };
    try {
      await client.post(OrdsEndpoints.auditoria, payload);
    } catch (_) {
      await _offlineCache?.addPendingMutation(
        endpoint: OrdsEndpoints.auditoria,
        method: 'POST',
        payload: payload,
      );
    }
  }
}
