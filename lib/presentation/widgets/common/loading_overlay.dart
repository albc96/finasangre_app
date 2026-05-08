import 'package:flutter/material.dart';

import 'app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.loading, required this.child});

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(children: [
        child,
        if (loading)
          Container(
            color: Colors.black.withValues(alpha: .35),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          ),
      ]);
}
