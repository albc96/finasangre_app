import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/glass_panel.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          color: AppColors.bg,
          child: Center(
            child: GlassPanel(
              width: 460,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock, color: AppColors.red, size: 54),
                const SizedBox(height: 12),
                const Text('ACCESO SUSPENDIDO',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Acceso suspendido por mensualidad pendiente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: 'admin@finasangre.cl',
                      queryParameters: {
                        'subject': 'FINASANGRE - Reactivar acceso',
                        'body':
                            'Hola, necesito regularizar mi mensualidad para reactivar FINASANGRE.',
                      },
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contactar dueño'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ]),
            ),
          ),
        ),
      );
}
