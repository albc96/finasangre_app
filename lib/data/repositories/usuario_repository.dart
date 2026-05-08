// ignore_for_file: use_super_parameters

import '../../core/config/app_config.dart';
import '../models/usuario_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class UsuarioRepository extends CrudRepository<UsuarioModel> {
  UsuarioRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.usuarios,
          fromJson: UsuarioModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.idUsuario,
          idKey: 'id_usuario',
          offlineCache: offlineCache,
        );
}
