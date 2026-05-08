import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'module_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding, this.width, this.tintColor, this.module});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final Color? tintColor;
  final AppModule? module;

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? (module != null ? ModuleTheme.of(module!).tint : null);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tint != null
                  ? [
                      tint.withValues(alpha: .70),
                      tint.withValues(alpha: .50),
                      AppColors.pink.withValues(alpha: .08),
                    ]
                  : [
                      AppColors.panel.withValues(alpha: .88),
                      AppColors.panel2.withValues(alpha: .78),
                      AppColors.pink.withValues(alpha: .08),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: tint?.withValues(alpha: .50) ??
                    AppColors.cyan.withValues(alpha: .30)),
            boxShadow: [
              BoxShadow(
                color: tint?.withValues(alpha: .20) ??
                    AppColors.cyan.withValues(alpha: .10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.pink.withValues(alpha: .08),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
