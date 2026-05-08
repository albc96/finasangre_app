// ignore_for_file: use_super_parameters

import '../../core/config/app_config.dart';
import '../models/suscripcion_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class SuscripcionRepository extends CrudRepository<SuscripcionModel> {
  SuscripcionRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.suscripciones,
          fromJson: SuscripcionModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.id,
          idKey: 'id_suscripcion',
          offlineCache: offlineCache,
        );

  Future<SuscripcionModel?> currentForUser(int userId) async {
    final now = DateTime.now();
    final all = await list();
    final matches = all.where((s) =>
        s.idUsuario == userId && s.mes == now.month && s.anio == now.year);
    return matches.isEmpty ? null : matches.first;
  }
}
