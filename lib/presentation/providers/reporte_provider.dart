import '../../data/models/reporte_model.dart';
import '../../data/repositories/reporte_repository.dart';
import 'crud_provider.dart';

class ReporteProvider extends CrudProvider<ReporteModel> {
  ReporteProvider(ReporteRepository super.repository);

  ReporteRepository get _reportes => repository as ReporteRepository;

  Future<bool> generarHerrador(int idHerrador) {
    return mutate(() async => _reportes.generarHerrador(idHerrador));
  }

  Future<bool> generarTodos() {
    return mutate(() async => _reportes.generarTodos());
  }
}
