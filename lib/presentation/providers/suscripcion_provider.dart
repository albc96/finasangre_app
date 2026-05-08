import '../../data/models/suscripcion_model.dart';
import '../../data/repositories/suscripcion_repository.dart';
import 'crud_provider.dart';

class SuscripcionProvider extends CrudProvider<SuscripcionModel> {
  SuscripcionProvider(this.suscripcionRepository)
      : super(suscripcionRepository);

  final SuscripcionRepository suscripcionRepository;
  SuscripcionModel? actual;

  bool get bloqueada => actual?.bloqueada ?? false;

  String estadoCalculado(SuscripcionModel? sub) {
    final now = DateTime.now();
    if (sub?.pagado == true) return 'PAGADA';
    if (now.day <= 7) return 'GRACIA';
    return 'BLOQUEADA';
  }

  Future<void> cargarActual(int userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.list();
      actual = items
          .where((s) =>
              s.idUsuario == userId &&
              s.mes == DateTime.now().month &&
              s.anio == DateTime.now().year)
          .cast<SuscripcionModel?>()
          .firstWhere((s) => s != null, orElse: () => null);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> marcarPagado(SuscripcionModel sub) {
    return actualizar(sub.copyWith(estado: 'PAGADA', pagado: true));
  }

  Future<bool> bloquear(SuscripcionModel sub) {
    return actualizar(sub.copyWith(estado: 'BLOQUEADA', pagado: false));
  }

  Future<bool> desbloquear(SuscripcionModel sub) {
    return actualizar(sub.copyWith(estado: 'GRACIA', pagado: false));
  }
}
