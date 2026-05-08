// ignore_for_file: use_super_parameters

import '../../core/config/app_config.dart';
import '../models/caballo_model.dart';
import '../services/offline_cache_service.dart';
import '../services/ords_client.dart';
import 'crud_repository.dart';

class CaballoRepository extends CrudRepository<CaballoModel> {
  CaballoRepository(OrdsClient client, {OfflineCacheService? offlineCache})
      : super(
          client: client,
          endpoint: OrdsEndpoints.caballos,
          fromJson: CaballoModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.idCaballo,
          idKey: 'id_caballo',
          offlineCache: offlineCache,
        );

  Future<List<CaballoModel>> listar() => list();

  Future<void> crear(CaballoModel caballo) => create(caballo);

  Future<void> actualizar(CaballoModel caballo) => update(caballo);

  Future<void> eliminar(
    int idCaballo, {
    bool eliminarHistorial = false,
  }) async {
    await client.deleteWithBody(endpoint, idCaballo, {
      'delete_history': eliminarHistorial ? 'SI' : 'NO',
    });
  }

  Future<void> desactivar(int idCaballo) async {
    final current = await get(idCaballo);
    await update(current.copyWith(activo: 'NO'));
  }
}
