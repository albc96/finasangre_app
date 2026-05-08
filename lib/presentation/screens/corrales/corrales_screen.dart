import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/corral_provider.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import 'corral_form_screen.dart';

class CorralesScreen extends StatefulWidget {
  const CorralesScreen({super.key});
  @override
  State<CorralesScreen> createState() => _CorralesScreenState();
}

class _CorralesScreenState extends State<CorralesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CorralProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CorralProvider>();
    return AppShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Corrales'), actions: [
          IconButton(onPressed: p.cargar, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add)),
        ]),
        body: p.loading
            ? const Center(child: CircularProgressIndicator())
            : p.error != null
                ? ErrorState(p.error!, onRetry: p.cargar)
                : p.items.isEmpty
                    ? const EmptyState('Sin corrales')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: p.items.length,
                        itemBuilder: (_, index) {
                          final c = p.items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.home_work),
                              title: Text('${c.numeroCorral} ${c.nombreCorral}'),
                              subtitle: Text(
                                '${c.ubicacion} / capacidad ${c.capacidad}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Wrap(children: [
                                IconButton(
                                  onPressed: () => _openForm(c),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () => _delete(p, c.idCorral),
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

  Future<void> _openForm([dynamic corral]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CorralFormScreen(corral: corral)),
    );
    if (mounted) context.read<CorralProvider>().cargar();
  }

  Future<void> _delete(CorralProvider provider, int id) async {
    final ok = await provider.eliminar(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Eliminado correctamente'
          : provider.error ?? 'No se pudo eliminar'),
    ));
  }
}
