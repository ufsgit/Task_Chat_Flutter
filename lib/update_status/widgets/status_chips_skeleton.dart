import 'package:flutter/material.dart';

/// Shimmering skeleton placeholder for the status selector chips.
class StatusChipsSkeleton extends StatefulWidget {
  final int count;
  const StatusChipsSkeleton({super.key, this.count = 3});

  @override
  State<StatusChipsSkeleton> createState() => _StatusChipsSkeletonState();
}

class _StatusChipsSkeletonState extends State<StatusChipsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF232830) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor = baseColor.withValues(alpha: _animation.value);

        return Row(
          children: List.generate(widget.count, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(20),
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
