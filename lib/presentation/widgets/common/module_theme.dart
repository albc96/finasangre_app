import 'package:flutter/material.dart';

import 'app_colors.dart';

enum AppModule {
  dashboard,
  caballos,
  corrales,
  preparadores,
  herradores,
  herrajes,
  reportes,
  usuarios,
  suscripciones,
  aura,
  ajustes,
}

class ModuleTheme {
  final Color primary;
  final Color secondary;
  final Color tint;
  final IconData icon;
  final String label;

  const ModuleTheme({
    required this.primary,
    required this.secondary,
    required this.tint,
    required this.icon,
    required this.label,
  });

  static const dashboard = ModuleTheme(
    primary: AppColors.cyan,
    secondary: AppColors.purple,
    tint: AppColors.panel,
    icon: Icons.dashboard,
    label: 'Dashboard',
  );

  static const caballos = ModuleTheme(
    primary: AppColors.purple,
    secondary: AppColors.pink,
    tint: Color(0xFF1A0D2E),
    icon: Icons.pets,
    label: 'Caballos',
  );

  static const corrales = ModuleTheme(
    primary: AppColors.cyan,
    secondary: AppColors.blue,
    tint: Color(0xFF0D2B4F),
    icon: Icons.home_work,
    label: 'Corrales',
  );

  static const preparadores = ModuleTheme(
    primary: AppColors.green,
    secondary: AppColors.cyan,
    tint: Color(0xFF0F2F1F),
    icon: Icons.person_pin,
    label: 'Preparadores',
  );

  static const herradores = ModuleTheme(
    primary: AppColors.gold,
    secondary: AppColors.gold,
    tint: Color(0xFF2F1F0D),
    icon: Icons.engineering,
    label: 'Herradores',
  );

  static const herrajes = ModuleTheme(
    primary: AppColors.pink,
    secondary: AppColors.purple,
    tint: Color(0xFF2D0F1F),
    icon: Icons.hive,
    label: 'Herrajes',
  );

  static const reportes = ModuleTheme(
    primary: AppColors.cyan,
    secondary: AppColors.pink,
    tint: Color(0xFF0D2B2E),
    icon: Icons.picture_as_pdf,
    label: 'Reportes',
  );

  static const usuarios = ModuleTheme(
    primary: AppColors.blue,
    secondary: AppColors.cyan,
    tint: Color(0xFF0D1F2F),
    icon: Icons.group,
    label: 'Usuarios',
  );

  static const suscripciones = ModuleTheme(
    primary: AppColors.red,
    secondary: AppColors.gold,
    tint: Color(0xFF2F0D0D),
    icon: Icons.subscriptions,
    label: 'Suscripciones',
  );

  static const aura = ModuleTheme(
    primary: AppColors.purple,
    secondary: AppColors.cyan,
    tint: Color(0xFF2D0F3D),
    icon: Icons.smart_toy,
    label: 'AURA',
  );

  static const ajustes = ModuleTheme(
    primary: AppColors.cyan,
    secondary: Colors.grey,
    tint: Color(0xFF1A1A1A),
    icon: Icons.settings,
    label: 'Ajustes',
  );

  static ModuleTheme of(AppModule module) {
    return switch (module) {
      AppModule.dashboard => dashboard,
      AppModule.caballos => caballos,
      AppModule.corrales => corrales,
      AppModule.preparadores => preparadores,
      AppModule.herradores => herradores,
      AppModule.herrajes => herrajes,
      AppModule.reportes => reportes,
      AppModule.usuarios => usuarios,
      AppModule.suscripciones => suscripciones,
      AppModule.aura => aura,
      AppModule.ajustes => ajustes,
    };
  }
}
