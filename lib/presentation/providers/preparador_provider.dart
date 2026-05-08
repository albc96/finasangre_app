import '../../data/models/preparador_model.dart';
import '../../data/repositories/preparador_repository.dart';
import 'crud_provider.dart';

class PreparadorProvider extends CrudProvider<PreparadorModel> {
  PreparadorProvider(PreparadorRepository super.repository);
}
