import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/dashboard/stat_card.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajustes')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          GlassPanel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.user?.nombreCompleto ?? 'Sin usuario',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(auth.user?.email ?? ''),
              const SizedBox(height: 16),
              NeonButton(
                text: 'Cerrar sesión',
                icon: Icons.logout,
                onPressed: () => auth.logout(),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
