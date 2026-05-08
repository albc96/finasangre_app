// ignore_for_file: use_super_parameters

import '../../core/config/app_config.dart';
import '../models/reporte_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class ReporteRepository extends CrudRepository<ReporteModel> {
  ReporteRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.reportes,
          fromJson: ReporteModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.idReporte,
          idKey: 'id_reporte',
          offlineCache: offlineCache,
        );

  @override
  Future<List<ReporteModel>> list() async {
    try {
      return await super.list();
    } on OrdsException {
      return [];
    }
  }

  Future<void> generarHerrador(int idHerrador) async {
    try {
      await client.post(OrdsEndpoints.generarReporte, {
        'id_herrador': idHerrador,
      });
    } catch (_) {
      await offlineCache?.addPendingMutation(
        endpoint: OrdsEndpoints.generarReporte,
        method: 'POST',
        payload: {'id_herrador': idHerrador},
      );
      rethrow;
    }
  }

  Future<void> generarTodos() async {
    try {
      await client.post(OrdsEndpoints.generarReporteTodos, {});
    } catch (_) {
      await offlineCache?.addPendingMutation(
        endpoint: OrdsEndpoints.generarReporteTodos,
        method: 'POST',
        payload: {},
      );
      rethrow;
    }
  }
}
