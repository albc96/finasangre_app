import '../../data/models/corral_model.dart';
import '../../data/repositories/corral_repository.dart';
import 'crud_provider.dart';

class CorralProvider extends CrudProvider<CorralModel> {
  CorralProvider(CorralRepository super.repository);
}
