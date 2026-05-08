import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/caballo_model.dart';
import '../../providers/corral_provider.dart';
import '../../providers/preparador_provider.dart';

class CaballoDetailScreen extends StatelessWidget {
  const CaballoDetailScreen({super.key, required this.caballo});
  final CaballoModel caballo;

  @override
  Widget build(BuildContext context) {
    final corrales = context.watch<CorralProvider>().items;
    final preparadores = context.watch<PreparadorProvider>().items;
    final corral =
        corrales.where((c) => c.idCorral == caballo.idCorral).firstOrNull;
    final preparador = preparadores
        .where((p) => p.idPreparador == caballo.idPreparador)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(caballo.nombreCaballo)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(title: const Text('Edad'), subtitle: Text('${caballo.edad}')),
        ListTile(
            title: const Text('Corral'),
            subtitle: Text(corral == null
                ? 'Sin corral'
                : [corral.nombreCorral, corral.numeroCorral]
                    .where((v) => v.trim().isNotEmpty)
                    .join(' '))),
        ListTile(
            title: const Text('Preparador'),
            subtitle: Text(preparador?.nombreCompleto ?? 'Sin preparador')),
        ListTile(title: const Text('Sexo'), subtitle: Text(caballo.sexo)),
        ListTile(title: const Text('Color'), subtitle: Text(caballo.color)),
      ]),
    );
  }
}
