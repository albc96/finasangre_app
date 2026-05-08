import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/herraje_model.dart';
import '../../providers/caballo_provider.dart';
import '../../providers/corral_provider.dart';
import '../../providers/herrador_provider.dart';

class HerrajeDetailScreen extends StatelessWidget {
  const HerrajeDetailScreen({super.key, required this.herraje});
  final HerrajeModel herraje;

  @override
  Widget build(BuildContext context) {
    final caballos = context.watch<CaballoProvider>().items;
    final herradores = context.watch<HerradorProvider>().items;
    final corrales = context.watch<CorralProvider>().items;
    final caballo =
        caballos.where((c) => c.idCaballo == herraje.idCaballo).firstOrNull;
    final herrador =
        herradores.where((h) => h.idHerrador == herraje.idHerrador).firstOrNull;
    final corral =
        corrales.where((c) => c.idCorral == herraje.idCorral).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text('Herraje ${herraje.idHerraje}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
            title: const Text('Caballo'),
            subtitle: Text(caballo?.nombreCaballo ?? 'Caballo sin nombre')),
        ListTile(
            title: const Text('Herrador'),
            subtitle: Text(herrador?.nombreCompleto ?? 'Herrador sin nombre')),
        ListTile(
            title: const Text('Corral'),
            subtitle: Text(corral == null
                ? 'Corral sin nombre'
                : [corral.nombreCorral, corral.numeroCorral]
                    .where((v) => v.trim().isNotEmpty)
                    .join(' '))),
        ListTile(
            title: const Text('Tipo'), subtitle: Text(herraje.tipoHerraje)),
        ListTile(title: const Text('Hora'), subtitle: Text(herraje.hora)),
      ]),
    );
  }
}
