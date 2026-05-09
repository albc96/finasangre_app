import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/auth_provider.dart';
import '../../providers/aura_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../data/services/offline_cache_service.dart';
import '../../../data/services/ords_client.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/aura/aura_screen.dart';
import '../../screens/caballos/caballos_screen.dart';
import '../../screens/corrales/corrales_screen.dart';
import '../../screens/herrajes/herrajes_screen.dart';
import '../../screens/herradores/herradores_screen.dart';
import '../../screens/ajustes/ajustes_screen.dart';
import '../../screens/preparadores/preparadores_screen.dart';
import '../../screens/reportes/reportes_screen.dart';
import '../../screens/usuarios/usuarios_screen.dart';
import '../../widgets/app_background_scaffold.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/subscription_alert_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> listaAlertas = [];
  bool estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncIfOnline();
      context.read<DashboardProvider>().cargar();
    });
  }

  Future<void> _cargarAlertas() async {
    try {
      final client = context.read<OrdsClient>();
      final result = await client.getList('alertas_herrajes').timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          listaAlertas = result;
          estaCargando = false;
        });
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() => estaCargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error de conexión. Revisa tu internet e intenta nuevamente.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => estaCargando = false);
    }
  }

  void _mostrarDetalleAlertas() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Herrajes Pendientes',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: listaAlertas.isEmpty
                ? const Text("Todos los caballos están al día.",
                    style: TextStyle(color: Colors.white70))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: listaAlertas.length,
                    itemBuilder: (context, index) {
                      final alerta = listaAlertas[index];
                      return Card(
                        color: Colors.white10,
                        child: ListTile(
                          title: Text(
                            (alerta['nombre_caballo'] ?? '')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Preparador: ${alerta['nombre_preparador'] ?? 'Sin asignar'}\n'
                            'Corral: ${alerta['nombre_corral'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${alerta['dias_sin_herraje'] ?? 0}',
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Text('días',
                                  style: TextStyle(
                                      color: Colors.redAccent, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              child: const Text('CERRAR',
                  style: TextStyle(color: Colors.cyanAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            if (!estaCargando) {
              _mostrarDetalleAlertas();
            }
          },
        ),
        if (listaAlertas.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                  minWidth: 16, minHeight: 16),
              child: Text(
                '${listaAlertas.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }

  Future<void> _syncIfOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;
    if (!mounted) return;
    final synced = await context.read<OfflineCacheService>().syncPending(
          context.read<OrdsClient>(),
        );
    if (!mounted || synced == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sincronizados $synced pendientes')),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.user?.isOwnerOrAdmin == true;
    final canConfigure = auth.user?.isOwner == true;

    return AppBackgroundScaffold(
      imagePath: 'assets/images/aura_horse.png',
      overlayOpacity: 0.62,
      appBarActions: [_buildNotificationBell()],
      child: RefreshIndicator(
        onRefresh: dashboard.cargar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dashboard.loading)
              const LinearProgressIndicator(color: AppColors.cyan),
            DashboardVideoHeader(userName: auth.user?.nombreCompleto ?? ''),
            const SizedBox(height: 20),
            DashboardStats(dashboard: dashboard, open: _open),
            const SizedBox(height: 20),
            DashboardActions(
              open: _open,
              logout: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              canManage: canManage,
              canConfigure: canConfigure,
            ),
            const SizedBox(height: 20),
            SubscriptionAlertCard(
              suscripcion: auth.suscripcion,
              canMarkPaid: canManage,
            ),
            const SizedBox(height: 20),
            if (dashboard.error != null)
              ErrorState(dashboard.error!, onRetry: dashboard.cargar)
            else
              DashboardPanels(
                dashboard: dashboard,
                openAura: () => _open(const AuraScreen()),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 520;
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 0 : 16, 12, isMobile ? 0 : 16, 4),
      child: GlassPanel(
        padding: EdgeInsets.all(isMobile ? 18 : 22),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium,
                      color: AppColors.gold, size: 58),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      'FINASANGRE',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Valparaíso Sporting Club',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName.isEmpty
                        ? 'Dashboard operativo'
                        : 'Bienvenido\n$userName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: AppColors.gold, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FINASANGRE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const Text(
                          'Valparaíso Sporting Club',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userName.isEmpty
                              ? 'Dashboard operativo'
                              : 'Bienvenido $userName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class DashboardStats extends StatelessWidget {
  const DashboardStats(
      {super.key, required this.dashboard, required this.open});

  final DashboardProvider dashboard;
  final void Function(Widget screen) open;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 520;
      final cardWidth = isMobile
          ? constraints.maxWidth
          : constraints.maxWidth < 900
              ? (constraints.maxWidth - 12) / 2
              : 210.0;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatCard(
            width: cardWidth,
            title: 'Caballos activos',
            value: '${dashboard.caballosActivos}',
            icon: Icons.pets,
            color: AppColors.purple,
            onTap: () => open(const CaballosScreen()),
          ),
          StatCard(
            width: cardWidth,
            title: 'Herrajes hoy',
            value: '${dashboard.herrajesHoy}',
            icon: Icons.newspaper,
            color: AppColors.gold,
            onTap: () => open(const HerrajesScreen()),
          ),
          StatCard(
            width: cardWidth,
            title: 'Herrajes mes',
            value: '${dashboard.herrajesMes}',
            icon: Icons.calendar_month,
            color: AppColors.pink,
            onTap: () => open(const HerrajesScreen()),
          ),
          StatCard(
            width: cardWidth,
            title: 'Corrales activos',
            value: '${dashboard.corralesActivos}',
            icon: Icons.home_work,
            color: AppColors.cyan,
            onTap: () => open(const CorralesScreen()),
          ),
          StatCard(
            width: cardWidth,
            title: 'Herradores activos',
            value: '${dashboard.herradoresActivos}',
            icon: Icons.engineering,
            color: AppColors.green,
            onTap: () => open(const HerradoresScreen()),
          ),
          StatCard(
            width: cardWidth,
            title: 'Vencidas',
            value: '${dashboard.suscripcionesVencidas}',
            icon: Icons.lock_clock,
            color: AppColors.red,
            onTap: () => open(const HerradoresScreen()),
          ),
        ],
      );
    });
  }
}


class DashboardActions extends StatelessWidget {
  const DashboardActions({
    super.key,
    required this.open,
    required this.logout,
    required this.canManage,
    required this.canConfigure,
  });

  final void Function(Widget screen) open;
  final VoidCallback logout;
  final bool canManage;
  final bool canConfigure;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        NeonButton(
            text: 'Preparadores',
            icon: Icons.person_pin,
            onPressed: () => open(const PreparadoresScreen())),
        NeonButton(
            text: 'Reportes',
            icon: Icons.picture_as_pdf,
            onPressed: () => open(const ReportesScreen())),
        if (canManage)
          NeonButton(
              text: 'Usuarios',
              icon: Icons.group,
              onPressed: () => open(const UsuariosScreen())),
        NeonButton(
            text: 'AURA',
            icon: Icons.smart_toy,
            onPressed: () => open(const AuraScreen())),
        if (canConfigure)
          NeonButton(
              text: 'Ajustes',
              icon: Icons.settings,
              onPressed: () => open(const AjustesScreen())),
        NeonButton(
            text: 'Cerrar sesión', icon: Icons.logout, onPressed: logout),
      ],
    );
  }
}

class DashboardPanels extends StatelessWidget {
  const DashboardPanels({
    super.key,
    required this.dashboard,
    required this.openAura,
  });

  final DashboardProvider dashboard;
  final VoidCallback openAura;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final recent = dashboard.herrajesData.reversed.take(8).toList();
      final auraProvider = context.watch<AuraProvider>();
      final filters = DashboardFilters(dashboard: dashboard);
      final charts = DashboardCharts(dashboard: dashboard);
      final alerts = DashboardAlerts(dashboard: dashboard);
      final latest = GlassPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Últimos herrajes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white12),
          if (recent.isEmpty)
            const EmptyState('Sin herrajes registrados')
          else
            ...recent.map((h) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.hive, color: AppColors.pink),
                  title: Text(
                    '${dashboard.caballoNombre(h.idCaballo)} - ${h.tipoHerraje}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${dashboard.herradorNombre(h.idHerrador)} / ${dashboard.corralNombre(h.idCorral)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
        ]),
      );
      final aura = AuraMiniCard(
        lastMessage: auraProvider.lastAuraResponse,
        summary: dashboard.auraResumen,
        onOpen: openAura,
        onToday: () {
          final aura = context.read<AuraProvider>();
          openAura();
          Future.microtask(() => aura.quick('herrajes de hoy'));
        },
      );
      if (c.maxWidth < 900) {
        return Column(children: [
          filters,
          const SizedBox(height: 16),
          charts,
          const SizedBox(height: 16),
          alerts,
          const SizedBox(height: 16),
          latest,
          const SizedBox(height: 16),
          aura,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              filters,
              const SizedBox(height: 16),
              charts,
              const SizedBox(height: 16),
              latest,
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              alerts,
              const SizedBox(height: 16),
              aura,
            ],
          ),
        ),
      ]);
    });
  }
}

class DashboardFilters extends StatelessWidget {
  const DashboardFilters({super.key, required this.dashboard});

  final DashboardProvider dashboard;

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => i + 1);
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 3 + i);
    return GlassPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _FilterBox(
            width: 120,
            child: DropdownButtonFormField<int>(
              initialValue: dashboard.selectedMonth,
              decoration: const InputDecoration(labelText: 'Mes'),
              items: months
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                  .toList(),
              onChanged: (v) =>
                  context.read<DashboardProvider>().setFilters(month: v),
            ),
          ),
          _FilterBox(
            width: 130,
            child: DropdownButtonFormField<int>(
              initialValue: dashboard.selectedYear,
              decoration: const InputDecoration(labelText: 'Año'),
              items: years
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (v) =>
                  context.read<DashboardProvider>().setFilters(year: v),
            ),
          ),
          _FilterBox(
            width: 210,
            child: DropdownButtonFormField<int?>(
              initialValue: dashboard.selectedHerradorId,
              decoration: const InputDecoration(labelText: 'Herrador'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...dashboard.herradoresData.map(
                  (h) => DropdownMenuItem(
                    value: h.idHerrador,
                    child: Text(
                      h.nombreCompleto,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => context
                  .read<DashboardProvider>()
                  .setFilters(herradorId: v, clearHerrador: v == null),
            ),
          ),
          _FilterBox(
            width: 210,
            child: DropdownButtonFormField<int?>(
              initialValue: dashboard.selectedCorralId,
              decoration: const InputDecoration(labelText: 'Corral'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...dashboard.corralesData.map(
                  (c) => DropdownMenuItem(
                    value: c.idCorral,
                    child: Text(
                      dashboard.corralNombre(c.idCorral),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => context
                  .read<DashboardProvider>()
                  .setFilters(corralId: v, clearCorral: v == null),
            ),
          ),
          _FilterBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: dashboard.selectedTipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const ['TODOS', 'COMPLETO', 'MANOS', 'PATAS']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) =>
                  context.read<DashboardProvider>().setFilters(tipo: v),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardVideoHeader extends StatefulWidget {
  const DashboardVideoHeader({super.key, required this.userName});

  final String userName;

  @override
  State<DashboardVideoHeader> createState() => _DashboardVideoHeaderState();
}

class _DashboardVideoHeaderState extends State<DashboardVideoHeader> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/dashboard_finasangre.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller
      ..setLooping(true)
      ..setVolume(0);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((_) {
      if (mounted) setState(() => _ready = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 520;
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 0 : 16, 12, isMobile ? 0 : 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: isMobile ? 250 : 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              else
                Image.asset('assets/images/aura_horse.png', fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF050B18).withValues(alpha: .92),
                      const Color(0xFF050B18).withValues(alpha: .70),
                      const Color(0xFF050B18).withValues(alpha: .28),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: .28),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 18 : 24),
                child: Align(
                  alignment:
                      isMobile ? Alignment.center : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: isMobile
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: AppColors.gold,
                          size: 48,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'FINASANGRE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Valparaiso Sporting Club',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.userName.isEmpty
                              ? 'Dashboard operativo'
                              : isMobile
                                  ? 'Bienvenido\n${widget.userName}'
                                  : 'Bienvenido ${widget.userName}',
                          textAlign:
                              isMobile ? TextAlign.center : TextAlign.start,
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 20,
                            height: 1.15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  const _FilterBox({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key, required this.dashboard});

  final DashboardProvider dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final twoCols = c.maxWidth >= 760;
      final chartWidth = twoCols ? (c.maxWidth - 16) / 2 : c.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _ChartPanel(
            width: chartWidth,
            title: 'Herrajes por día del mes',
            child: LineChart(_lineData(dashboard)),
          ),
          _ChartPanel(
            width: chartWidth,
            title: 'COMPLETO / MANOS / PATAS',
            child: PieChart(_pieData(dashboard)),
          ),
          _ChartPanel(
            width: chartWidth,
            title: 'Ranking por herrador',
            child: BarChart(_barData(dashboard.rankingHerrador)),
          ),
          _ChartPanel(
            width: chartWidth,
            title: 'Actividad por corral',
            child: BarChart(_barData(dashboard.actividadCorral)),
          ),
        ],
      );
    });
  }

  LineChartData _lineData(DashboardProvider d) {
    final spots = d.herrajesPorDia.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    final maxY = d.herrajesPorDia.values.fold<int>(1, (a, b) => b > a ? b : a);
    return LineChartData(
      minY: 0,
      maxY: maxY + 1,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: _titles(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.cyan,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.cyan.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }

  PieChartData _pieData(DashboardProvider d) {
    final data = d.distribucionTipo;
    final colors = [AppColors.cyan, AppColors.pink, AppColors.gold];
    var i = 0;
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 34,
      sections: data.entries.map((e) {
        final color = colors[i++ % colors.length];
        return PieChartSectionData(
          value: e.value.toDouble(),
          title: '${e.key}\n${e.value}',
          color: color,
          radius: 68,
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        );
      }).toList(),
    );
  }

  BarChartData _barData(Map<String, int> values) {
    final entries = values.entries.toList();
    final maxY = entries.fold<int>(1, (a, e) => e.value > a ? e.value : a);
    return BarChartData(
      maxY: maxY + 1,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: _titles(showBottom: false),
      barGroups: [
        for (var i = 0; i < entries.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: i.isEven ? AppColors.pink : AppColors.cyan,
                width: 18,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
      ],
    );
  }

  FlTitlesData _titles({bool showBottom = true}) => FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: showBottom, reservedSize: 24),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      );
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.width,
    required this.title,
    required this.child,
  });

  final double width;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 230, child: child),
          ],
        ),
      ),
    );
  }
}

class DashboardAlerts extends StatelessWidget {
  const DashboardAlerts({super.key, required this.dashboard});

  final DashboardProvider dashboard;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertas operativas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white12),
          _AlertLine(
            icon: Icons.warning_amber,
            color: AppColors.gold,
            text:
                '${dashboard.caballosSinHerraje30Dias.length} caballos sin herraje hace 30 días',
          ),
          _AlertLine(
            icon: Icons.lock_clock,
            color: AppColors.red,
            text: '${dashboard.suscripcionesVencidas} suscripciones vencidas',
          ),
          _AlertLine(
            icon: Icons.block,
            color: AppColors.pink,
            text:
                '${dashboard.herradoresBloqueados.length} herradores bloqueados',
          ),
        ],
      ),
    );
  }
}

class _AlertLine extends StatelessWidget {
  const _AlertLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 2),
            ),
          ],
        ),
      );
}

class AuraMiniCard extends StatelessWidget {
  const AuraMiniCard({
    super.key,
    required this.lastMessage,
    required this.summary,
    required this.onOpen,
    required this.onToday,
  });

  final String? lastMessage;
  final String summary;
  final VoidCallback onOpen;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(
          children: [
            Icon(Icons.smart_toy, color: AppColors.cyan),
            SizedBox(width: 10),
            Text(
              'AURA IA',
              style:
                  TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          lastMessage ?? summary,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          NeonButton(
            text: 'Hablar con AURA',
            icon: Icons.forum,
            onPressed: onOpen,
          ),
          NeonButton(
            text: 'Herrajes de hoy',
            icon: Icons.today,
            onPressed: onToday,
          ),
        ]),
      ]),
    );
  }
}
