import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/herrador_provider.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import 'herrador_form_screen.dart';

class HerradoresScreen extends StatefulWidget {
  const HerradoresScreen({super.key});
  @override
  State<HerradoresScreen> createState() => _HerradoresScreenState();
}

class _HerradoresScreenState extends State<HerradoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HerradorProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HerradorProvider>();
    return AppShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Herradores'), actions: [
          IconButton(onPressed: p.cargar, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add)),
        ]),
        body: p.loading
            ? const Center(child: CircularProgressIndicator())
            : p.error != null
                ? ErrorState(p.error!, onRetry: p.cargar)
                : p.items.isEmpty
                    ? const EmptyState('Sin herradores')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: p.items.length,
                        itemBuilder: (_, index) {
                          final item = p.items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.engineering),
                              title: Text(item.nombreCompleto),
                              subtitle: Text(
                                '${item.codigoHerrador} / ${item.telefono}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Wrap(children: [
                                IconButton(
                                  onPressed: () => _openForm(item),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () => _delete(p, item.idHerrador),
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

  Future<void> _openForm([dynamic herrador]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HerradorFormScreen(herrador: herrador)),
    );
    if (mounted) context.read<HerradorProvider>().cargar();
  }

  Future<void> _delete(HerradorProvider provider, int id) async {
    final ok = await provider.eliminar(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Eliminado correctamente'
          : provider.error ?? 'No se pudo eliminar'),
    ));
  }
}
