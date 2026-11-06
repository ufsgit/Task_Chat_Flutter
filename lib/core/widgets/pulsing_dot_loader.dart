import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A sleek, customizable pulsing dot loader widget.
///
/// Displays a row of dots that smoothly pulse in size and opacity
/// in a continuous wave pattern. Ideal for button loading states.
class PulsingDotLoader extends StatefulWidget {
  final Color color;
  final double size;
  final double spacing;
  final int count;
  final Duration duration;

  const PulsingDotLoader({
    super.key,
    this.color = Colors.white,
    this.size = 8.0,
    this.spacing = 6.0,
    this.count = 3,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<PulsingDotLoader> createState() => _PulsingDotLoaderState();
}

class _PulsingDotLoaderState extends State<PulsingDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.count, (index) {
            // Wave offset per dot
            final double phase = (_controller.value * 2 * math.pi) -
                (index * (math.pi / (widget.count <= 1 ? 1 : widget.count - 0.5)));
            // Sine wave normalized between 0.0 and 1.0
            final double wave = (math.sin(phase) + 1.0) / 2.0;
            final double scale = 0.45 + (0.55 * wave);
            final double opacity = 0.35 + (0.65 * wave);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

