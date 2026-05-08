import 'package:flutter/material.dart';

class AuraQuickActions extends StatelessWidget {
  const AuraQuickActions({super.key, required this.onAction});
  final void Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      'Buscar caballo',
      'Herrajes de hoy',
      'Reporte mensual',
      'Revisar suscripcion',
      'Ver corrales',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions
          .map((a) => ActionChip(label: Text(a), onPressed: () => onAction(a)))
          .toList(),
    );
  }
}
