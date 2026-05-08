// ignore_for_file: use_super_parameters

import '../../core/config/app_config.dart';
import '../models/herrador_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class HerradorRepository extends CrudRepository<HerradorModel> {
  HerradorRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.herradores,
          fromJson: HerradorModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.idHerrador,
          idKey: 'id_herrador',
          offlineCache: offlineCache,
        );
}
