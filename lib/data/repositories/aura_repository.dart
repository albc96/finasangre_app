import '../../core/config/app_config.dart';
import '../models/aura_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';

class AuraRepository {
  AuraRepository(this.client, {OfflineCacheService? offlineCache})
      : _offlineCache = offlineCache;

  final OrdsClient client;
  final OfflineCacheService? _offlineCache;

  Future<List<AuraModel>> obtenerHistorial(int idUsuario) async {
    try {
      final rows = await client.getList(OrdsEndpoints.aura);
      final items = rows.map(AuraModel.fromJson).where((a) {
        return a.idUsuario == idUsuario;
      }).toList()
        ..sort((a, b) {
          final af = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bf = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          return af.compareTo(bf);
        });
      for (final item in items) {
        await _offlineCache?.saveAura(item);
      }
      return items;
    } on OrdsException {
      return await _offlineCache?.readAura(idUsuario) ?? [];
    }
  }

  Future<void> guardarMensaje(AuraModel item) async {
    try {
      await client.post(OrdsEndpoints.aura, item.toJson()..remove('id_aura'));
      await _offlineCache?.saveAura(item);
    } on OrdsException {
      await _offlineCache?.saveAura(item, pending: true);
    }
  }

  Future<void> limpiarHistorial(int idUsuario) async {
    try {
      await client.post('${OrdsEndpoints.aura}/limpiar', {
        'id_usuario': idUsuario,
      });
    } on OrdsException {
      // No bloqueante.
    }
    await _offlineCache?.clearAura(idUsuario);
  }
}
