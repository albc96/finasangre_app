import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/glass_panel.dart';
import 'usuario_form_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UsuarioProvider>().cargar();
    });
  }

  Future<void> _openForm([UsuarioModel? usuario]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UsuarioFormScreen(usuario: usuario)),
    );
    if (mounted) context.read<UsuarioProvider>().cargar();
  }

  Future<void> _deactivate(UsuarioModel usuario) async {
    if (usuario.isSystemOwner) {
      _message('No puedes desactivar al OWNER abrahambc.');
      return;
    }
    final provider = context.read<UsuarioProvider>();
    final ok = await provider.actualizar(usuario.copyWith(activo: 'NO'));
    _message(ok
        ? 'Actualizado correctamente'
        : provider.error ?? 'No se pudo desactivar.');
  }

  Future<void> _delete(UsuarioModel usuario) async {
    if (usuario.isSystemOwner) {
      _message('No puedes eliminar al OWNER abrahambc.');
      return;
    }
    final provider = context.read<UsuarioProvider>();
    final ok = await provider.eliminar(usuario.idUsuario);
    _message(ok
        ? 'Eliminado correctamente'
        : provider.error ?? 'No se pudo eliminar.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();
    final current = context.watch<AuthProvider>().user;
    final allowed = current?.isSystemOwner == true;

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Usuarios'), actions: [
          IconButton(
              onPressed: provider.cargar, icon: const Icon(Icons.refresh)),
          if (allowed)
            IconButton(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add_alt_1),
            ),
        ]),
        body: !allowed
            ? const Center(
                child: GlassPanel(
                  width: 480,
                  child: Text('Solo OWNER puede administrar usuarios.'),
                ),
              )
            : provider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan))
                : provider.error != null
                    ? ErrorState(provider.error!, onRetry: provider.cargar)
                    : provider.items.isEmpty
                        ? const EmptyState('Sin registros reales todavia')
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final user = provider.items[index];
                              return _UsuarioCard(
                                user: user,
                                onEdit: () => _openForm(user),
                                onDeactivate: user.isSystemOwner
                                    ? () => _message(
                                        'No puedes modificar al OWNER abrahambc.')
                                    : () => _deactivate(user),
                                onDelete: user.isSystemOwner
                                    ? () => _message(
                                        'No puedes eliminar al OWNER abrahambc.')
                                    : () => _delete(user),
                              );
                            },
                          ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  const _UsuarioCard({
    required this.user,
    required this.onEdit,
    required this.onDeactivate,
    required this.onDelete,
  });

  final UsuarioModel user;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person, color: AppColors.cyan, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.email} • ${user.rol} • ${user.activo}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
              IconButton(
                tooltip: user.isSystemOwner ? 'OWNER protegido' : 'Desactivar',
                onPressed: onDeactivate,
                icon: const Icon(Icons.block, color: AppColors.pink),
              ),
              IconButton(
                tooltip: user.isSystemOwner ? 'OWNER protegido' : 'Eliminar',
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppColors.red),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 8),
              actions,
            ],
          );
        },
      ),
    );
  }
}
