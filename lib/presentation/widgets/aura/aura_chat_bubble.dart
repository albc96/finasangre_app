import 'package:flutter/material.dart';

import '../common/app_colors.dart';

class AuraChatBubble extends StatelessWidget {
  const AuraChatBubble({super.key, required this.role, required this.text});

  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final user = role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: user
              ? AppColors.purple.withValues(alpha: .25)
              : AppColors.cyan.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text),
      ),
    );
  }
}
