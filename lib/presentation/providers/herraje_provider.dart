import '../../data/models/herraje_model.dart';
import '../../data/repositories/herraje_repository.dart';
import '../../data/services/audit_service.dart';
import 'crud_provider.dart';

class HerrajeProvider extends CrudProvider<HerrajeModel> {
  HerrajeProvider(HerrajeRepository super.repository, [this.auditService]);

  final AuditService? auditService;

  int get herrajesHoy {
    final now = DateTime.now();
    return items.where((h) {
      final date = h.fechaHerraje;
      if (date != null) {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }
      return h.dia == now.day && h.mes == now.month && h.anio == now.year;
    }).length;
  }

  @override
  Future<bool> crear(HerrajeModel item) async {
    final ok = await super.crear(item);
    if (ok) {
      await auditService?.record(
        action: 'creacion_herraje',
        module: 'HERRAJES',
        detail: '${item.idCaballo} ${item.tipoHerraje}',
      );
    }
    return ok;
  }

  @override
  Future<bool> actualizar(HerrajeModel item) async {
    final ok = await super.actualizar(item);
    if (ok) {
      await auditService?.record(
        action: 'edicion_herraje',
        module: 'HERRAJES',
        detail: '${item.idHerraje} ${item.tipoHerraje}',
      );
    }
    return ok;
  }

  @override
  Future<bool> eliminar(dynamic id) async {
    final ok = await super.eliminar(id);
    if (ok) {
      await auditService?.record(
        action: 'eliminacion_herraje',
        module: 'HERRAJES',
        detail: '$id',
      );
    }
    return ok;
  }
}
