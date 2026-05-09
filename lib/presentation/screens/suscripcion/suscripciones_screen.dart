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
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.panel.withValues(alpha: .62),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cyan.withValues(alpha: .22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: AppColors.gold),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Suscripciones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: provider.cargar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _SuscripcionesBody(
              allowed: allowed,
              provider: provider,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuscripcionesBody extends StatelessWidget {
  const _SuscripcionesBody({
    required this.allowed,
    required this.provider,
  });

  final bool allowed;
  final SuscripcionProvider provider;

  @override
  Widget build(BuildContext context) {
    if (!allowed) {
      return const Center(
        child: GlassPanel(
          width: 480,
          child: Text('Solo el dueno puede administrar mensualidades.'),
        ),
      );
    }

    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      );
    }

    if (provider.error != null) {
      return ErrorState(provider.error!, onRetry: provider.cargar);
    }

    if (provider.items.isEmpty) {
      return const EmptyState('Sin mensualidades registradas');
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: provider.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                    paid ? Icons.verified : Icons.warning_amber,
                    color: paid ? AppColors.green : AppColors.gold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Usuario ${s.idUsuario} - ${s.mes}/${s.anio}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Chip(
                    label: Text(paid ? 'PAGADA' : s.estado),
                    backgroundColor: (paid ? AppColors.green : AppColors.red)
                        .withValues(alpha: .12),
                    side: BorderSide(
                      color: (paid ? AppColors.green : AppColors.red)
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
                    onPressed: () => provider.marcarPagado(s),
                    icon: const Icon(Icons.payments),
                    label: const Text('Marcar pagado'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => provider.bloquear(s),
                    icon: const Icon(Icons.lock),
                    label: const Text('Bloquear'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => provider.desbloquear(s),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Desbloquear'),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
