import 'package:flutter/material.dart';

import 'app_colors.dart';

class NeonCard extends StatelessWidget {
  const NeonCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.panel2,
                AppColors.panel,
                AppColors.pink.withValues(alpha: .08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cyan.withValues(alpha: .24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: .08),
                blurRadius: 18,
              ),
              BoxShadow(
                color: AppColors.pink.withValues(alpha: .07),
                blurRadius: 22,
              ),
            ],
          ),
          child: child,
        ),
      );
}
