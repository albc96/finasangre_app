import '../../data/models/herrador_model.dart';
import '../../data/repositories/herrador_repository.dart';
import 'crud_provider.dart';

class HerradorProvider extends CrudProvider<HerradorModel> {
  HerradorProvider(HerradorRepository super.repository);
}
