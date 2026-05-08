import 'package:flutter/material.dart';

import '../../../data/models/suscripcion_model.dart';
import '../common/app_colors.dart';
import '../common/glass_panel.dart';

class SubscriptionAlertCard extends StatelessWidget {
  const SubscriptionAlertCard({
    super.key,
    required this.suscripcion,
    this.canMarkPaid = false,
    this.onMarkPaid,
  });

  final SuscripcionModel? suscripcion;
  final bool canMarkPaid;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final estado = suscripcion?.estado ??
        (DateTime.now().day <= 7 ? 'GRACIA' : 'BLOQUEADA');
    final color = estado == 'PAGADA'
        ? AppColors.green
        : estado == 'BLOQUEADA'
            ? AppColors.red
            : AppColors.gold;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      final button = canMarkPaid && estado != 'PAGADA'
          ? FilledButton.icon(
              onPressed: onMarkPaid ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Selecciona un herrador en Suscripciones para marcar pago.'),
                      ),
                    );
                  },
              icon: const Icon(Icons.payments),
              label: const Text('Marcar como pagado'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.bg,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null;

      final content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, color: color, size: compact ? 34 : 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suscripción $estado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Día 1 al 7: gracia. Día 8 sin pago: bloqueo.',
                  softWrap: true,
                  style: TextStyle(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      );

      return GlassPanel(
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  if (button != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(height: 46, child: button),
                  ],
                ],
              )
            : Row(
                children: [
                  Expanded(child: content),
                  if (button != null) ...[
                    const SizedBox(width: 12),
                    button,
                  ],
                ],
              ),
      );
    });
  }
}
