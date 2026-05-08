import 'package:flutter/material.dart';

import 'speed_lines_painter.dart';

class AnimatedRacingBackground extends StatefulWidget {
  const AnimatedRacingBackground({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/aura_horse.png',
    this.overlayOpacity = 0.62,
    this.imageAlignment = Alignment.center,
    this.enableSpeedLines = true,
  });

  final Widget child;
  final String imagePath;
  final double overlayOpacity;
  final Alignment imageAlignment;
  final bool enableSpeedLines;

  @override
  State<AnimatedRacingBackground> createState() =>
      _AnimatedRacingBackgroundState();
}

class _AnimatedRacingBackgroundState extends State<AnimatedRacingBackground>
    with TickerProviderStateMixin {
  late final AnimationController _zoomController;
  late final AnimationController _parallaxController;
  late final AnimationController _linesController;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _linesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _parallaxController.dispose();
    _linesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlayOpacity.clamp(0.0, 1.0);

    return ColoredBox(
      color: const Color(0xFF050B18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_zoomController, _parallaxController]),
              builder: (context, _) {
                final scale = 1 + (_zoomController.value * 0.04);
                final dx = -10 + (_parallaxController.value * 20);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.scale(
                    scale: scale,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 950),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Image.asset(
                        widget.imagePath,
                        key: ValueKey(widget.imagePath),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const _RacingFallback(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1F000000),
                  Color(0x2E000000),
                  Color(0x8C000000),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
          if (overlay > 0)
              ColoredBox(color: Colors.black.withValues(alpha: overlay * 0.55)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          if (widget.enableSpeedLines)
            IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _linesController,
                  builder: (context, _) => CustomPaint(
                    painter:
                        SpeedLinesPainter(progress: _linesController.value),
                  ),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _RacingFallback extends StatelessWidget {
  const _RacingFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050B18),
            Color(0xFF071A2E),
            Color(0xFF120A24),
          ],
        ),
      ),
    );
  }
}
