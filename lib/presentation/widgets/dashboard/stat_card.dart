import 'package:flutter/material.dart';

import '../common/app_colors.dart';
import '../common/neon_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.width = 210,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: NeonCard(
          onTap: onTap,
          child: Row(children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900)),
                  ]),
            ),
          ]),
        ),
      );
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label:
              Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyan.withValues(alpha: .16),
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.cyan),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
