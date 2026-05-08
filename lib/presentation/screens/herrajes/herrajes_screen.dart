import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/caballo_provider.dart';
import '../../providers/corral_provider.dart';
import '../../providers/herraje_provider.dart';
import '../../providers/herrador_provider.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import 'herraje_detail_screen.dart';
import 'herraje_form_screen.dart';

class HerrajesScreen extends StatefulWidget {
  const HerrajesScreen({super.key});

  @override
  State<HerrajesScreen> createState() => _HerrajesScreenState();
}

class _HerrajesScreenState extends State<HerrajesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HerrajeProvider>().cargar();
      context.read<CaballoProvider>().cargar();
      context.read<HerradorProvider>().cargar();
      context.read<CorralProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HerrajeProvider>();
    final caballos = context.watch<CaballoProvider>().items;
    final herradores = context.watch<HerradorProvider>().items;
    final corrales = context.watch<CorralProvider>().items;

    String caballoName(int id) =>
        caballos
            .where((c) => c.idCaballo == id)
            .map((c) => c.nombreCaballo)
            .firstOrNull ??
        'Caballo sin nombre';
    String herradorName(int id) =>
        herradores
            .where((h) => h.idHerrador == id)
            .map((h) => h.nombreCompleto)
            .firstOrNull ??
        'Herrador sin nombre';
    String corralName(int id) {
      final corral = corrales.where((c) => c.idCorral == id).firstOrNull;
      if (corral == null) return 'Corral sin nombre';
      return [corral.nombreCorral, corral.numeroCorral]
          .where((v) => v.trim().isNotEmpty)
          .join(' ');
    }

    return AppShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Herrajes'), actions: [
          IconButton(
              onPressed: provider.cargar, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HerrajeFormScreen()),
            ),
            icon: const Icon(Icons.add),
          ),
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
                          final herraje = provider.items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.hive),
                              title: Text(
                                '${caballoName(herraje.idCaballo)} - ${herraje.tipoHerraje}',
                              ),
                              subtitle: Text(
                                '${herradorName(herraje.idHerrador)} / ${corralName(herraje.idCorral)} / ${herraje.hora}',
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HerrajeDetailScreen(herraje: herraje),
                                ),
                              ),
                              trailing: Wrap(children: [
                                IconButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HerrajeFormScreen(herraje: herraje),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _delete(provider, herraje.idHerraje),
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

  Future<void> _delete(HerrajeProvider provider, int id) async {
    final ok = await provider.eliminar(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Eliminado correctamente'
          : provider.error ?? 'No se pudo eliminar'),
    ));
  }
}
