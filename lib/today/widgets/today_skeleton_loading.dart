import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Skeleton loading placeholder matching the ChatListItemTile layout.
class TodaySkeletonLoading extends StatefulWidget {
  final int itemCount;

  const TodaySkeletonLoading({super.key, this.itemCount = 6});

  @override
  State<TodaySkeletonLoading> createState() => _TodaySkeletonLoadingState();
}

class _TodaySkeletonLoadingState extends State<TodaySkeletonLoading>
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

  Widget _buildBox({
    required double width,
    required double height,
    double borderRadius = 6,
    BoxShape shape = BoxShape.rectangle,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF232830) : const Color(0xFFE2E8F0);
    final dividerColor =
        isDark ? AppDarkColors.divider : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedColor = baseColor.withValues(alpha: _animation.value);

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.itemCount,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 1.0,
              color: dividerColor,
            ),
          ),
          itemBuilder: (context, index) {
            final titleWidth = (index % 3 == 0)
                ? 130.0
                : (index % 3 == 1)
                    ? 100.0
                    : 115.0;
            final locationWidth = (index % 2 == 0) ? 90.0 : 120.0;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Avatar Skeleton
                  _buildBox(
                    width: 44,
                    height: 44,
                    shape: BoxShape.circle,
                    color: animatedColor,
                  ),
                  const SizedBox(width: 14),

                  // Middle Content Skeleton
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: Title + Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBox(
                              width: titleWidth,
                              height: 15,
                              color: animatedColor,
                            ),
                            _buildBox(
                              width: 55,
                              height: 12,
                              color: animatedColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Bottom row: Tag + Location
                        Row(
                          children: [
                            _buildBox(
                              width: 65,
                              height: 18,
                              borderRadius: 10,
                              color: animatedColor,
                            ),
                            const SizedBox(width: 8),
                            _buildBox(
                              width: locationWidth,
                              height: 13,
                              color: animatedColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
