import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/suscripcion_provider.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/app_shell.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/glass_panel.dart';

class SuscripcionesScreen extends StatefulWidget {
  const SuscripcionesScreen({super.key});

  @override
  State<SuscripcionesScreen> createState() => _SuscripcionesScreenState();
}

class _SuscripcionesScreenState extends State<SuscripcionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SuscripcionProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<SuscripcionProvider>();
    final allowed = user?.isSystemOwner == true;

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Suscripciones'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: provider.cargar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: !allowed
            ? const Center(
                child: GlassPanel(
                  width: 480,
                  child: Text('Solo el dueño puede administrar mensualidades.'),
                ),
              )
            : provider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan))
                : provider.error != null
                    ? ErrorState(provider.error!, onRetry: provider.cargar)
                    : provider.items.isEmpty
                        ? const EmptyState('Sin mensualidades registradas')
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final s = provider.items[index];
                              final paid = s.pagado || s.estado == 'PAGADA';
                              return GlassPanel(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final compact = constraints.maxWidth < 760;
                                    final info = Row(
                                      children: [
                                        Icon(
                                          paid
                                              ? Icons.verified
                                              : Icons.warning_amber,
                                          color: paid
                                              ? AppColors.green
                                              : AppColors.gold,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Usuario ${s.idUsuario} - ${s.mes}/${s.anio}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        Chip(
                                          label:
                                              Text(paid ? 'PAGADA' : s.estado),
                                          backgroundColor: (paid
                                                  ? AppColors.green
                                                  : AppColors.red)
                                              .withValues(alpha: .12),
                                          side: BorderSide(
                                            color: (paid
                                                    ? AppColors.green
                                                    : AppColors.red)
                                                .withValues(alpha: .32),
                                          ),
                                        ),
                                      ],
                                    );
                                    final actions = Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        FilledButton.tonalIcon(
                                          onPressed: () =>
                                              provider.marcarPagado(s),
                                          icon: const Icon(Icons.payments),
                                          label: const Text('Marcar pagado'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => provider.bloquear(s),
                                          icon: const Icon(Icons.lock),
                                          label: const Text('Bloquear'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              provider.desbloquear(s),
                                          icon: const Icon(Icons.lock_open),
                                          label: const Text('Desbloquear'),
                                        ),
                                      ],
                                    );
                                    if (compact) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          info,
                                          const SizedBox(height: 12),
                                          actions,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: info),
                                        const SizedBox(width: 12),
                                        actions,
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                          ),
      ),
    );
  }
}
