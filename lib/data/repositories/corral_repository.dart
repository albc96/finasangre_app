// ignore_for_file: use_super_parameters

import '../../core/config/app_config.dart';
import '../models/corral_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class CorralRepository extends CrudRepository<CorralModel> {
  CorralRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.corrales,
          fromJson: CorralModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.idCorral,
          idKey: 'id_corral',
          offlineCache: offlineCache,
        );
}
