import 'package:flutter/material.dart';

class CinematicHorseHero extends StatefulWidget {
  const CinematicHorseHero({
    super.key,
    this.imagePath,
    this.width = 240,
    this.height = 180,
  });

  final String? imagePath;
  final double width;
  final double height;

  @override
  State<CinematicHorseHero> createState() => _CinematicHorseHeroState();
}

class _CinematicHorseHeroState extends State<CinematicHorseHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_controller.value);
            return Transform.translate(
              offset: Offset(-6 + (t * 12), 2 - (t * 4)),
              child: Transform.scale(
                scale: 0.985 + (t * 0.03),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF)
                            .withValues(alpha: 0.25 + (t * 0.30)),
                        blurRadius: 44,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF8B5CF6)
                            .withValues(alpha: 0.18 + (t * 0.22)),
                        blurRadius: 64,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: widget.imagePath == null
              ? const SizedBox.shrink()
              : Image.asset(
                  widget.imagePath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}
