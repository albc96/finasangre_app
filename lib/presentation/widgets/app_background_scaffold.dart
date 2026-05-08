import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/ajustes/ajustes_screen.dart';
import '../screens/aura/aura_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/caballos/caballos_screen.dart';
import '../screens/corrales/corrales_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/herrajes/herrajes_screen.dart';
import '../screens/herradores/herradores_screen.dart';
import '../screens/preparadores/preparadores_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/suscripcion/suscripciones_screen.dart';
import '../screens/usuarios/usuarios_screen.dart';
import 'animated_racing_background.dart';
import 'common/app_colors.dart';
import 'common/sidebar_menu.dart';
import 'finasangre_background.dart';

class AppBackgroundScaffold extends StatelessWidget {
  const AppBackgroundScaffold({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/aura_horse.png',
    this.showSidebar = true,
    this.overlayOpacity = 0.42,
    this.enableSpeedLines = true,
    this.scrollContent = true,
    this.appBarActions = const [],
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget child;
  final String imagePath;
  final bool showSidebar;
  final double overlayOpacity;
  final bool enableSpeedLines;
  final bool scrollContent;
  final List<Widget> appBarActions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: bottomNavigationBar,
      body: FinasangreBackground(
        child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedRacingBackground(
              imagePath: imagePath,
              overlayOpacity: overlayOpacity.clamp(0.80, 0.95),
              enableSpeedLines: enableSpeedLines,
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;
                if (!showSidebar) {
                  return _BodyFrame(
                    constraints: constraints,
                    padding: const EdgeInsets.all(16),
                    scroll: scrollContent,
                    child: child,
                  );
                }
                if (isMobile) {
                  return Column(
                    children: [
                      MobileTopBar(actions: appBarActions),
                      Expanded(
                        child: Stack(
                          children: [
                            _BodyFrame(
                              constraints: constraints,
                              minHeightOffset: 80,
                              padding: const EdgeInsets.all(16),
                              scroll: scrollContent,
                              child: child,
                            ),
                            if (floatingActionButton != null)
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: floatingActionButton!,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    const SizedBox(width: 260, child: _GlobalSidebar()),
                    Expanded(
                      child: Column(
                        children: [
                          if (appBarActions.isNotEmpty)
                            Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.panel.withValues(alpha: .88),
                                border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.cyan.withValues(alpha: .18))),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'FINASANGRE',
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  ...appBarActions,
                                ],
                              ),
                            ),
                          Expanded(
                            child: Stack(
                              children: [
                                _BodyFrame(
                                  constraints: constraints,
                                  padding: const EdgeInsets.all(20),
                                  scroll: scrollContent,
                                  child: child,
                                ),
                                if (floatingActionButton != null)
                                  Positioned(
                                    right: 20,
                                    bottom: 20,
                                    child: floatingActionButton!,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _BodyFrame extends StatelessWidget {
  const _BodyFrame({
    required this.constraints,
    required this.child,
    required this.padding,
    required this.scroll,
    this.minHeightOffset = 0,
  });

  final BoxConstraints constraints;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scroll;
  final double minHeightOffset;

  @override
  Widget build(BuildContext context) {
    if (!scroll) {
      return Padding(padding: padding, child: child);
    }
    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              (constraints.maxHeight - minHeightOffset).clamp(0.0, double.infinity),
        ),
        child: child,
      ),
    );
  }
}

class MobileTopBar extends StatelessWidget {
  const MobileTopBar({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .88),
        border: Border(bottom: BorderSide(color: AppColors.cyan.withValues(alpha: .18))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu, color: AppColors.cyan),
            onPressed: () => _showMobileMenu(context),
          ),
          const Icon(Icons.workspace_premium, color: AppColors.gold),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'FINASANGRE',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          ...actions,
          IconButton(
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout, color: AppColors.red),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _GlobalSidebar extends StatelessWidget {
  const _GlobalSidebar();

  @override
  Widget build(BuildContext context) {
    return SidebarMenu(items: _items(context), onLogout: () => _logout(context));
  }
}

List<SidebarItem> _items(BuildContext context) {
  final user = context.read<AuthProvider>().user;
  final isOwner = user?.isSystemOwner == true;
  final isAdmin = user?.isAdmin == true;
  final isHerrador = user?.isHerrador == true;
  final isPreparador = user?.isPreparador == true;
  final canManage = isOwner || isAdmin;
  final canConfigure = isOwner;
  if (isHerrador) {
    return [
      SidebarItem('Dashboard', Icons.dashboard, () => _replace(context, const DashboardScreen())),
      SidebarItem('Caballos', Icons.pets, () => _open(context, const CaballosScreen())),
      SidebarItem('Herrajes', Icons.newspaper, () => _open(context, const HerrajesScreen())),
      SidebarItem('Reportes', Icons.picture_as_pdf, () => _open(context, const ReportesScreen())),
      SidebarItem('AURA', Icons.smart_toy, () => _open(context, const AuraScreen())),
    ];
  }
  if (isPreparador) {
    return [
      SidebarItem('Caballos', Icons.pets, () => _open(context, const CaballosScreen())),
      SidebarItem('Corrales', Icons.home_work, () => _open(context, const CorralesScreen())),
      SidebarItem('AURA', Icons.smart_toy, () => _open(context, const AuraScreen())),
    ];
  }
  return [
    SidebarItem('Dashboard', Icons.dashboard, () => _replace(context, const DashboardScreen())),
    SidebarItem('Caballos', Icons.pets, () => _open(context, const CaballosScreen())),
    SidebarItem('Corrales', Icons.home_work, () => _open(context, const CorralesScreen())),
    SidebarItem('Preparadores', Icons.person_pin, () => _open(context, const PreparadoresScreen())),
    SidebarItem('Herradores', Icons.engineering, () => _open(context, const HerradoresScreen())),
    SidebarItem('Herrajes', Icons.newspaper, () => _open(context, const HerrajesScreen())),
    SidebarItem('Reportes', Icons.picture_as_pdf, () => _open(context, const ReportesScreen())),
    if (canManage) SidebarItem('Usuarios', Icons.group, () => _open(context, const UsuariosScreen())),
    if (isOwner) SidebarItem('Suscripciones', Icons.verified_user, () => _open(context, const SuscripcionesScreen())),
    SidebarItem('AURA', Icons.smart_toy, () => _open(context, const AuraScreen())),
    if (canConfigure) SidebarItem('Ajustes', Icons.settings, () => _open(context, const AjustesScreen())),
  ];
}

void _open(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

void _replace(BuildContext context, Widget screen) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}

Future<void> _logout(BuildContext context) async {
  await context.read<AuthProvider>().logout();
  if (!context.mounted) return;
  _replace(context, const LoginScreen());
}

void _showMobileMenu(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.panel,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        children: _items(context)
            .map(
              (item) => ListTile(
                leading: Icon(item.icon, color: AppColors.cyan),
                title: Text(item.label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  item.onTap();
                },
              ),
            )
            .toList(),
      ),
    ),
  );
}
