import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Shimmering skeleton card placeholder for BookingHistoryPage.
class HistorySkeletonLoading extends StatefulWidget {
  const HistorySkeletonLoading({super.key});

  @override
  State<HistorySkeletonLoading> createState() => _HistorySkeletonLoadingState();
}

class _HistorySkeletonLoadingState extends State<HistorySkeletonLoading>
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
    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBox({
    required Color color,
    required double width,
    required double height,
    double borderRadius = 6,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final borderColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);
    final baseColor = isDark
        ? const Color(0xFF232830)
        : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedColor = baseColor.withValues(alpha: _animation.value);

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Accordion Header Skeleton
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Circular Clock Icon placeholder
                        _buildBox(
                          color: animatedColor,
                          width: 40,
                          height: 40,
                          shape: BoxShape.circle,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildBox(
                                    color: animatedColor,
                                    width: 130,
                                    height: 18,
                                    borderRadius: 4,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildBox(
                                    color: animatedColor,
                                    width: 45,
                                    height: 14,
                                    borderRadius: 4,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildBox(
                                color: animatedColor,
                                width: 85,
                                height: 12,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        _buildBox(
                          color: animatedColor,
                          width: 75,
                          height: 24,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(height: 1, thickness: 1, color: borderColor),

                  // 2. Timeline Event Skeletons (3 events)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      children: List.generate(3, (index) {
                        return _buildTimelineEventSkeleton(
                          animatedColor: animatedColor,
                          borderColor: borderColor,
                          isLast: index == 2,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineEventSkeleton({
    required Color animatedColor,
    required Color borderColor,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (Dot + Line)
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildBox(
                  color: animatedColor,
                  width: 12,
                  height: 12,
                  shape: BoxShape.circle,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: borderColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Event Card Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Title + Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBox(
                        color: animatedColor,
                        width: 120,
                        height: 15,
                        borderRadius: 4,
                      ),
                      _buildBox(
                        color: animatedColor,
                        width: 60,
                        height: 20,
                        borderRadius: 10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date & Actor Subtitle
                  _buildBox(
                    color: animatedColor,
                    width: 140,
                    height: 11,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 10),

                  // Diff box placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBox(
                          color: animatedColor,
                          width: 55,
                          height: 9,
                          borderRadius: 3,
                        ),
                        const SizedBox(height: 6),
                        _buildBox(
                          color: animatedColor,
                          width: 150,
                          height: 13,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
