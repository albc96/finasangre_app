import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../widgets/app_background_scaffold.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/glass_panel.dart';

class UsuarioFormScreen extends StatefulWidget {
  const UsuarioFormScreen({super.key, this.usuario});

  final UsuarioModel? usuario;

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _email;
  late final TextEditingController _telefono;
  late final TextEditingController _clave;
  String _rol = 'HERRADOR';
  String _activo = 'SI';

  bool get _editing => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombre = TextEditingController(text: u?.nombreCompleto ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _telefono = TextEditingController(text: u?.telefono ?? '');
    _clave = TextEditingController(text: u?.passwordHash ?? '');
    _rol = u?.rol ?? 'HERRADOR';
    _activo = u?.activo ?? 'SI';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = context.read<AuthProvider>().user;
    if (current?.isSystemOwner != true) {
      _message('Solo el dueño del sistema puede crear o editar usuarios');
      return;
    }
    if (widget.usuario?.isSystemOwner == true &&
        (_activo != 'SI' || _email.text.trim().toLowerCase() != 'abrahambc')) {
      _message('No puedes desactivar al dueño del sistema');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final user = UsuarioModel(
      idUsuario: widget.usuario?.idUsuario ?? 0,
      nombreCompleto: _nombre.text.trim(),
      email: _email.text.trim().toLowerCase(),
      telefono: _telefono.text.trim(),
      passwordHash: _clave.text,
      rol: _rol,
      activo: _activo,
    );
    final provider = context.read<UsuarioProvider>();
    final ok =
        _editing ? await provider.actualizar(user) : await provider.crear(user);
    if (!mounted) return;
    _message(ok
        ? (_editing ? 'Actualizado correctamente' : 'Guardado correctamente')
        : provider.error ?? 'No se pudo guardar el usuario');
    if (ok) Navigator.pop(context);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AuthProvider>().user;
    final allowed = current?.isSystemOwner == true;
    final roles = const ['OWNER', 'ADMIN', 'HERRADOR', 'PREPARADOR'];

    return AppBackgroundScaffold(
      showSidebar: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: GlassPanel(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          _editing ? 'Editar usuario' : 'Crear usuario',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!allowed)
                    const Text(
                      'Solo el dueño del sistema puede crear o editar usuarios.',
                      style: TextStyle(color: AppColors.red),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nombre,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Usuario/email'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefono,
                    decoration: const InputDecoration(labelText: 'Telefono'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clave,
                    decoration: const InputDecoration(labelText: 'Clave'),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: allowed ? (v) => setState(() => _rol = v!) : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _activo,
                    decoration: const InputDecoration(labelText: 'Activo'),
                    items: const [
                      DropdownMenuItem(value: 'SI', child: Text('SI')),
                      DropdownMenuItem(value: 'NO', child: Text('NO')),
                    ],
                    onChanged:
                        allowed ? (v) => setState(() => _activo = v!) : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: allowed ? _save : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
