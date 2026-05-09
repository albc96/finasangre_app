import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/herrador_model.dart';
import '../../../data/models/suscripcion_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/herrador_provider.dart';
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
      if (!mounted) return;
      context.read<SuscripcionProvider>().cargar();
      context.read<HerradorProvider>().cargar();
    });
  }

  Future<void> _openCreateDialog() async {
    final provider = context.read<SuscripcionProvider>();
    final herradoresProvider = context.read<HerradorProvider>();
    final herradores = herradoresProvider.items
        .where((h) => h.idUsuario > 0 && h.activo.toUpperCase() != 'NO')
        .toList()
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    if (herradores.isEmpty) {
      _message('No hay herradores activos con usuario asociado.');
      return;
    }

    final now = DateTime.now();
    final result = await showDialog<_NuevaSuscripcionData>(
      context: context,
      builder: (_) => _NuevaSuscripcionDialog(
        herradores: herradores,
        initialMonth: now.month,
        initialYear: now.year,
      ),
    );
    if (result == null) return;

    final item = SuscripcionModel(
      id: 0,
      idUsuario: result.herrador.idUsuario,
      mes: result.month,
      anio: result.year,
      estado: result.estado,
      fechaLimitePago: DateTime(result.year, result.month, 7),
      pagado: result.estado == 'PAGADA',
    );
    final ok = await provider.crear(item);
    _message(ok
        ? 'Suscripcion creada para ${result.herrador.nombreCompleto}.'
        : provider.error ?? 'No se pudo crear la suscripcion.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
                if (allowed)
                  IconButton(
                    tooltip: 'Agregar suscripcion',
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _SuscripcionesBody(
              allowed: allowed,
              provider: provider,
              herradores: context.watch<HerradorProvider>().items,
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
    required this.herradores,
  });

  final bool allowed;
  final SuscripcionProvider provider;
  final List<HerradorModel> herradores;

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
        final herrador = herradores
            .where((h) => h.idUsuario == s.idUsuario)
            .cast<HerradorModel?>()
            .firstWhere((h) => h != null, orElse: () => null);
        final nombre = herrador?.nombreCompleto ?? 'Usuario ${s.idUsuario}';
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
                      '$nombre - ${s.mes}/${s.anio}',
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

class _NuevaSuscripcionData {
  const _NuevaSuscripcionData({
    required this.herrador,
    required this.month,
    required this.year,
    required this.estado,
  });

  final HerradorModel herrador;
  final int month;
  final int year;
  final String estado;
}

class _NuevaSuscripcionDialog extends StatefulWidget {
  const _NuevaSuscripcionDialog({
    required this.herradores,
    required this.initialMonth,
    required this.initialYear,
  });

  final List<HerradorModel> herradores;
  final int initialMonth;
  final int initialYear;

  @override
  State<_NuevaSuscripcionDialog> createState() =>
      _NuevaSuscripcionDialogState();
}

class _NuevaSuscripcionDialogState extends State<_NuevaSuscripcionDialog> {
  HerradorModel? _herrador;
  late int _month;
  late int _year;
  String _estado = 'GRACIA';

  @override
  void initState() {
    super.initState();
    _herrador = widget.herradores.first;
    _month = widget.initialMonth;
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(5, (i) => DateTime.now().year - 1 + i);
    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: const Text('Nueva suscripcion'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<HerradorModel>(
              initialValue: _herrador,
              decoration: const InputDecoration(labelText: 'Herrador'),
              items: widget.herradores
                  .map(
                    (h) => DropdownMenuItem(
                      value: h,
                      child: Text(
                        h.nombreCompleto,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _herrador = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Mes'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m'),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _month = value ?? _month),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Ano'),
                    items: years
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _year = value ?? _year),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _estado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const ['GRACIA', 'PAGADA', 'BLOQUEADA']
                  .map((estado) => DropdownMenuItem(
                        value: estado,
                        child: Text(estado),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _estado = value ?? _estado),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _herrador == null
              ? null
              : () => Navigator.of(context).pop(
                    _NuevaSuscripcionData(
                      herrador: _herrador!,
                      month: _month,
                      year: _year,
                      estado: _estado,
                    ),
                  ),
          icon: const Icon(Icons.add),
          label: const Text('Crear'),
        ),
      ],
    );
  }
}
