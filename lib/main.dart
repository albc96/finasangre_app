import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'data/repositories/caballo_repository.dart';
import 'data/repositories/aura_repository.dart';
import 'data/repositories/corral_repository.dart';
import 'data/repositories/herrador_repository.dart';
import 'data/repositories/herraje_repository.dart';
import 'data/repositories/preparador_repository.dart';
import 'data/repositories/reporte_repository.dart';
import 'data/repositories/suscripcion_repository.dart';
import 'data/repositories/usuario_repository.dart';
import 'data/services/biometric_service.dart';
import 'data/services/audit_service.dart';
import 'data/services/aura_brain.dart';
import 'data/services/notification_service.dart';
import 'data/services/offline_cache_service.dart';
import 'data/services/ords_client.dart';
import 'presentation/providers/aura_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/caballo_provider.dart';
import 'presentation/providers/corral_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/herrador_provider.dart';
import 'presentation/providers/herraje_provider.dart';
import 'presentation/providers/preparador_provider.dart';
import 'presentation/providers/reporte_provider.dart';
import 'presentation/providers/suscripcion_provider.dart';
import 'presentation/providers/usuario_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/suscripcion/blocked_screen.dart';
import 'presentation/widgets/common/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinaSangreApp());
}

class FinaSangreApp extends StatelessWidget {
  const FinaSangreApp({super.key, this.ordsClient});

  final OrdsClient? ordsClient;

  @override
  Widget build(BuildContext context) {
    final client = ordsClient ?? OrdsClient();
    final offlineCache = OfflineCacheService();
    final auditService = AuditService(client, offlineCache: offlineCache);
    final auraRepository = AuraRepository(client, offlineCache: offlineCache);
    final auraBrain = AuraBrain(client);
    final caballoRepository =
        CaballoRepository(client, offlineCache: offlineCache);
    final corralRepository =
        CorralRepository(client, offlineCache: offlineCache);
    final preparadorRepository =
        PreparadorRepository(client, offlineCache: offlineCache);
    final herradorRepository =
        HerradorRepository(client, offlineCache: offlineCache);
    final herrajeRepository =
        HerrajeRepository(client, offlineCache: offlineCache);
    final reporteRepository =
        ReporteRepository(client, offlineCache: offlineCache);
    final suscripcionRepository =
        SuscripcionRepository(client, offlineCache: offlineCache);
    final usuarioRepository =
        UsuarioRepository(client, offlineCache: offlineCache);
    final notificationService = NotificationService(
      caballos: caballoRepository,
      herrajes: herrajeRepository,
    );

    return MultiProvider(
      providers: [
        Provider<OrdsClient>.value(value: client),
        Provider<OfflineCacheService>.value(value: offlineCache),
        Provider<AuditService>.value(value: auditService),
        Provider<AuraRepository>.value(value: auraRepository),
        Provider<CaballoRepository>.value(value: caballoRepository),
        Provider<CorralRepository>.value(value: corralRepository),
        Provider<PreparadorRepository>.value(value: preparadorRepository),
        Provider<HerradorRepository>.value(value: herradorRepository),
        Provider<HerrajeRepository>.value(value: herrajeRepository),
        Provider<ReporteRepository>.value(value: reporteRepository),
        Provider<SuscripcionRepository>.value(value: suscripcionRepository),
        Provider<UsuarioRepository>.value(value: usuarioRepository),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(client, BiometricService(), auditService),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            caballos: caballoRepository,
            corrales: corralRepository,
            herradores: herradorRepository,
            herrajes: herrajeRepository,
            preparadores: preparadorRepository,
            suscripciones: suscripcionRepository,
          ),
        ),
        ChangeNotifierProvider(
            create: (_) => CaballoProvider(caballoRepository, auditService)),
        ChangeNotifierProvider(create: (_) => CorralProvider(corralRepository)),
        ChangeNotifierProvider(
          create: (_) => PreparadorProvider(preparadorRepository),
        ),
        ChangeNotifierProvider(
            create: (_) => HerradorProvider(herradorRepository)),
        ChangeNotifierProvider(
            create: (_) => HerrajeProvider(herrajeRepository, auditService)),
        ChangeNotifierProvider(
            create: (_) => ReporteProvider(reporteRepository)),
        ChangeNotifierProvider(
          create: (_) => SuscripcionProvider(suscripcionRepository),
        ),
        ChangeNotifierProvider(
            create: (_) => UsuarioProvider(usuarioRepository)),
        ChangeNotifierProvider(
          create: (_) => AuraProvider(
            repository: auraRepository,
            brain: auraBrain,
            auditService: auditService,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FINASANGRE',
        locale: const Locale('es', 'CL'),
        supportedLocales: const [
          Locale('es', 'CL'),
          Locale('es'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: _theme(),
        home: const RootGate(),
      ),
    );
  }

  ThemeData _theme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme)
          .apply(bodyColor: Colors.white, displayColor: Colors.white),
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.purple,
        surface: AppColors.panel,
        error: AppColors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.panel,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ink,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.cyan.withValues(alpha: .35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.cyan.withValues(alpha: .35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.4),
        ),
      ),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final notifications = context.read<NotificationService>();
        await auth.restore();
        if (auth.loggedIn) {
          await notifications.init();
          await notifications.checkAndNotify();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }
    if (!auth.loggedIn) return const LoginScreen();
    if (auth.blocked) return const BlockedScreen();
    return const DashboardScreen();
  }
}
