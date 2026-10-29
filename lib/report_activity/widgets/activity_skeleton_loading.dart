import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Shimmering skeleton card matching the ActivityItemCard layout.
class ActivityCardSkeleton extends StatelessWidget {
  final Color animatedColor;

  const ActivityCardSkeleton({super.key, required this.animatedColor});

  Widget _buildBox({
    required double width,
    required double height,
    double borderRadius = 6,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: animatedColor,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.border,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Circular Avatar Skeleton (46x46)
          _buildBox(
            width: 46,
            height: 46,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 14),

          // 2. Main Content Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBox(
                      width: 120,
                      height: 16,
                      borderRadius: 4,
                    ),
                    _buildBox(
                      width: 55,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Subtitle Placeholder (e.g. Branch Manager: Anas Kabeer)
                _buildBox(
                  width: 170,
                  height: 12,
                  borderRadius: 4,
                ),
                const SizedBox(height: 10),

                // Status Tag Pill (e.g. New / Completed)
                _buildBox(
                  width: 70,
                  height: 20,
                  borderRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering skeleton list loading placeholder for the Activity page.
class ActivitySkeletonLoading extends StatefulWidget {
  final int itemCount;

  const ActivitySkeletonLoading({super.key, this.itemCount = 5});

  @override
  State<ActivitySkeletonLoading> createState() =>
      _ActivitySkeletonLoadingState();
}

class _ActivitySkeletonLoadingState extends State<ActivitySkeletonLoading>
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
        final animatedColor = baseColor.withValues(alpha: _animation.value);

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          itemCount: widget.itemCount,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return ActivityCardSkeleton(animatedColor: animatedColor);
          },
        );
      },
    );
  }
}
