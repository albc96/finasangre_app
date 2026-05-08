import 'package:flutter/material.dart';

import '../common/app_colors.dart';

class AuraAvatar extends StatelessWidget {
  const AuraAvatar({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.purple, AppColors.cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.pets,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}

