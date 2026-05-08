import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpeedLinesPainter extends CustomPainter {
  SpeedLinesPainter({required this.progress});

  final double progress;

  static const _colors = [
    Color(0xFF00E5FF),
    Color(0xFF8B5CF6),
    Color(0xFFEAB308),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final diagonal =
        math.sqrt(size.width * size.width + size.height * size.height);
    final drift = progress * 220;

    for (var i = 0; i < 18; i++) {
      final paint = Paint()
        ..color = _colors[i % _colors.length]
            .withValues(alpha: i.isEven ? 0.10 : 0.055)
        ..strokeWidth = i.isEven ? 1.2 : 0.8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final y = ((i * 86.0) + drift) % (size.height + 260) - 130;
      final x = (i * 73.0) % (size.width + 180) - 90;
      final length = diagonal * (i.isEven ? 0.22 : 0.14);
      final start = Offset(x, y);
      final end = start + Offset(length, -length * 0.34);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedLinesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
