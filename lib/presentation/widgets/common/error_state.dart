import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app_colors.dart';

class ErrorState extends StatelessWidget {
  const ErrorState(
    this.message, {
    super.key,
    this.title = 'Error de conexion ORDS',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  String get _safeMessage {
    final trimmed = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.toLowerCase().contains('<!doctype html') ||
        trimmed.toLowerCase().contains('<html')) {
      return 'No se pudo cargar la informacion. Revisa endpoint o conexion.';
    }
    return trimmed.isEmpty
        ? 'No se pudo cargar la informacion. Revisa endpoint o conexion.'
        : trimmed;
  }

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'No se pudo cargar la informacion. Revisa endpoint o conexion.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (kDebugMode && _safeMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _safeMessage,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .62),
                  fontSize: 12,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ]),
        ),
      );
}
