import '../../data/models/caballo_model.dart';
import '../../data/repositories/caballo_repository.dart';
import '../../data/services/audit_service.dart';
import 'crud_provider.dart';

class CaballoProvider extends CrudProvider<CaballoModel> {
  CaballoProvider(CaballoRepository super.repository, [this.auditService]);

  final AuditService? auditService;
  CaballoRepository get _caballos => repository as CaballoRepository;

  @override
  Future<bool> crear(CaballoModel item) async {
    final ok = await super.crear(item);
    if (ok) {
      await auditService?.record(
        action: 'creacion_caballo',
        module: 'CABALLOS',
        detail: item.nombreCaballo,
      );
    }
    return ok;
  }

  @override
  Future<bool> actualizar(CaballoModel item) async {
    final ok = await super.actualizar(item);
    if (ok) {
      await auditService?.record(
        action: 'edicion_caballo',
        module: 'CABALLOS',
        detail: item.nombreCaballo,
      );
    }
    return ok;
  }

  @override
  Future<bool> eliminar(dynamic id) async {
    return eliminarPermanente(id as int);
  }

  Future<bool> eliminarPermanente(
    int id, {
    bool eliminarHistorial = false,
  }) async {
    final ok = await mutate(
      () async => _caballos.eliminar(
        id,
        eliminarHistorial: eliminarHistorial,
      ),
    );
    if (ok) {
      await auditService?.record(
        action: 'eliminacion_caballo',
        module: 'CABALLOS',
        detail: '$id',
      );
    }
    return ok;
  }

  Future<bool> desactivar(int id) async {
    final ok = await mutate(() async => _caballos.desactivar(id));
    if (ok) {
      await auditService?.record(
        action: 'desactivacion_caballo',
        module: 'CABALLOS',
        detail: '$id',
      );
    }
    return ok;
  }
}
