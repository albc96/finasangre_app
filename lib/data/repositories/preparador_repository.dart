// ignore_for_file: use_super_parameters

import '../../core/config/app_config.dart';
import '../models/preparador_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class PreparadorRepository extends CrudRepository<PreparadorModel> {
  PreparadorRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.preparadores,
          fromJson: PreparadorModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.idPreparador,
          idKey: 'id_preparador',
          offlineCache: offlineCache,
        );
}
