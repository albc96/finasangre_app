import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/caballo_provider.dart';
import '../../providers/corral_provider.dart';
import '../../providers/herraje_provider.dart';
import '../../providers/preparador_provider.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import 'caballo_detail_screen.dart';
import 'caballo_form_screen.dart';

class CaballosScreen extends StatefulWidget {
  const CaballosScreen({super.key});

  @override
  State<CaballosScreen> createState() => _CaballosScreenState();
}

class _CaballosScreenState extends State<CaballosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CaballoProvider>().cargar();
      context.read<CorralProvider>().cargar();
      context.read<PreparadorProvider>().cargar();
      context.read<HerrajeProvider>().cargar();
    });
  }

  Future<void> _openForm([dynamic caballo]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaballoFormScreen(caballo: caballo)),
    );
    if (mounted) context.read<CaballoProvider>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaballoProvider>();
    final corrales = context.watch<CorralProvider>().items;
    final preparadores = context.watch<PreparadorProvider>().items;
    final herrajes = context.watch<HerrajeProvider>().items;
    final isOwner = context.watch<AuthProvider>().user?.isSystemOwner == true;

    String corralName(int id) {
      final corral = corrales.where((c) => c.idCorral == id).firstOrNull;
      if (corral == null) return 'Corral sin nombre';
      return [corral.nombreCorral, corral.numeroCorral]
          .where((v) => v.trim().isNotEmpty)
          .join(' ');
    }

    String preparadorName(int id) {
      return preparadores
              .where((p) => p.idPreparador == id)
              .map((p) => p.nombreCompleto)
              .firstOrNull ??
          'Preparador sin nombre';
    }

    return AppShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Caballos'), actions: [
          IconButton(
              onPressed: provider.cargar, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add)),
        ]),
        body: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? ErrorState(provider.error!, onRetry: provider.cargar)
                : provider.items.isEmpty
                    ? const EmptyState('Sin registros reales todavia')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.items.length,
                        itemBuilder: (_, index) {
                          final caballo = provider.items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.pets),
                              title: Text(caballo.nombreCaballo),
                              subtitle: Text(
                                '${caballo.edad} anos / ${corralName(caballo.idCorral)} / ${preparadorName(caballo.idPreparador)}',
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CaballoDetailScreen(caballo: caballo),
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openForm(caballo);
                                  } else if (value == 'deactivate') {
                                    _deactivate(caballo.idCaballo);
                                  } else if (value == 'delete') {
                                    _confirmDelete(
                                      caballo.idCaballo,
                                      caballo.nombreCaballo,
                                      isOwner,
                                      herrajes.any((h) =>
                                          h.idCaballo == caballo.idCaballo),
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'deactivate',
                                    child: Text('Desactivar'),
                                  ),
                                  if (isOwner)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Eliminar para siempre'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Future<void> _deactivate(int idCaballo) async {
    final provider = context.read<CaballoProvider>();
    final ok = await provider.desactivar(idCaballo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Caballo desactivado.'
            : provider.error ?? 'No se pudo desactivar el caballo.'),
      ),
    );
  }

  Future<void> _confirmDelete(
    int idCaballo,
    String nombreCaballo,
    bool isOwner,
    bool tieneHistorial,
  ) async {
    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo OWNER abrahambc puede eliminar para siempre.'),
        ),
      );
      return;
    }

    final deleteHistory = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar $nombreCaballo'),
        content: Text(tieneHistorial
            ? 'Este caballo tiene historial. ¿Eliminar también sus herrajes?'
            : '¿Eliminar este caballo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (tieneHistorial)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, cancelar'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, tieneHistorial),
            child: Text(tieneHistorial
                ? 'Eliminar caballo y herrajes'
                : 'Eliminar caballo'),
          ),
        ],
      ),
    );

    if (deleteHistory == null || (tieneHistorial && deleteHistory != true)) {
      return;
    }
    if (!mounted) return;
    final provider = context.read<CaballoProvider>();
    final ok = await provider.eliminarPermanente(
      idCaballo,
      eliminarHistorial: true,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Eliminado correctamente'
            : provider.error ?? 'No se pudo eliminar el caballo.'),
      ),
    );
  }
}
