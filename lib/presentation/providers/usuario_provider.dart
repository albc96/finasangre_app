import '../../data/models/usuario_model.dart';
import 'crud_provider.dart';

class UsuarioProvider extends CrudProvider<UsuarioModel> {
  UsuarioProvider(super.usuarioRepository);
}
