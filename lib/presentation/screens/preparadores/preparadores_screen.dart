import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/preparador_provider.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import 'preparador_form_screen.dart';

class PreparadoresScreen extends StatefulWidget {
  const PreparadoresScreen({super.key});
  @override
  State<PreparadoresScreen> createState() => _PreparadoresScreenState();
}

class _PreparadoresScreenState extends State<PreparadoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreparadorProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PreparadorProvider>();
    return AppShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Preparadores'), actions: [
          IconButton(onPressed: p.cargar, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add)),
        ]),
        body: p.loading
            ? const Center(child: CircularProgressIndicator())
            : p.error != null
                ? ErrorState(p.error!, onRetry: p.cargar)
                : p.items.isEmpty
                    ? const EmptyState('Sin preparadores')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: p.items.length,
                        itemBuilder: (_, index) {
                          final item = p.items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.person_pin),
                              title: Text(item.nombreCompleto),
                              subtitle: Text(
                                '${item.telefono} / ${item.email}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Wrap(children: [
                                IconButton(
                                  onPressed: () => _openForm(item),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _delete(p, item.idPreparador),
                                  icon: const Icon(Icons.delete),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Future<void> _openForm([dynamic preparador]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreparadorFormScreen(preparador: preparador),
      ),
    );
    if (mounted) context.read<PreparadorProvider>().cargar();
  }

  Future<void> _delete(PreparadorProvider provider, int id) async {
    final ok = await provider.eliminar(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Eliminado correctamente'
          : provider.error ?? 'No se pudo eliminar'),
    ));
  }
}
