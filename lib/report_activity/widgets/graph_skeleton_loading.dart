import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shimmering skeleton placeholder for the weekly activity graph and status breakdown card.
class GraphSkeletonLoading extends StatefulWidget {
  final double chartPlotHeight;
  final int dayCount;

  const GraphSkeletonLoading({
    super.key,
    this.chartPlotHeight = 260.0,
    this.dayCount = 7,
  });

  @override
  State<GraphSkeletonLoading> createState() => _GraphSkeletonLoadingState();
}

class _GraphSkeletonLoadingState extends State<GraphSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  // Realistic simulated bar heights for the 7 days
  static const List<List<double>> _simulatedDayHeights = [
    [130, 85, 55, 20],
    [165, 110, 80, 25],
    [100, 145, 115, 15],
    [185, 130, 95, 35],
    [210, 160, 135, 30],
    [85, 60, 45, 15],
    [40, 30, 20, 10],
  ];

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF232830)
        : const Color(0xFFE2E8F0);
    final gridLineColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFF1F5F9);

    const double yLabelWidth = 26.0;
    final bool isScrollable = widget.dayCount > 3;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedColor = baseColor.withValues(alpha: _animation.value);

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth =
                math.max(0.0, constraints.maxWidth - yLabelWidth - 8.0);
            final double itemWidth = isScrollable
                ? math.max(85.0, availableWidth / 3.2)
                : (widget.dayCount > 0
                    ? (availableWidth / widget.dayCount)
                    : availableWidth);
            final double totalContentWidth =
                isScrollable ? (itemWidth * widget.dayCount) : availableWidth;

            final chartContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: widget.chartPlotHeight,
                  width: totalContentWidth,
                  child: Stack(
                    children: [
                      // Horizontal Gridlines
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (_) {
                            return Container(
                              height: 1.0,
                              color: gridLineColor,
                            );
                          }),
                        ),
                      ),

                      // Bars
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(widget.dayCount, (index) {
                            final heights = _simulatedDayHeights[
                                index % _simulatedDayHeights.length];
                            final barWidget = Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: _SkeletonDayBars(
                                heights: heights,
                                animatedColor: animatedColor,
                              ),
                            );

                            return isScrollable
                                ? SizedBox(width: itemWidth, child: barWidget)
                                : Expanded(child: barWidget);
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: totalContentWidth,
                  child: Row(
                    children: List.generate(widget.dayCount, (index) {
                      final labelWidget = Center(
                        child: Container(
                          width: 26,
                          height: 12,
                          decoration: BoxDecoration(
                            color: animatedColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );

                      return isScrollable
                          ? SizedBox(width: itemWidth, child: labelWidget)
                          : Expanded(child: labelWidget);
                    }),
                  ),
                ),
              ],
            );

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed Y-Axis placeholder column
                    Column(
                      children: [
                        SizedBox(
                          height: widget.chartPlotHeight,
                          width: yLabelWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (_) {
                              return SizedBox(
                                height: 1.0,
                                child: OverflowBox(
                                  maxHeight: 14,
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 24,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: animatedColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 18),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // Scrollable chart body
                    Expanded(
                      child: isScrollable
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: chartContent,
                            )
                          : chartContent,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildDetailsSkeleton(animatedColor, isDark),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailsSkeleton(Color animatedColor, bool isDark) {
    final cardBg = isDark ? const Color(0xFF14171D) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF282C35)
        : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Calendar placeholder + Date pill + Total badge placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: animatedColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 125,
                    height: 15,
                    decoration: BoxDecoration(
                      color: animatedColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 22,
                decoration: BoxDecoration(
                  color: animatedColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4 Stacked Status Cards Skeleton (New, Scheduled, Completed, Cancelled)
          ...List.generate(4, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: animatedColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: animatedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 70,
                          height: 14,
                          decoration: BoxDecoration(
                            color: animatedColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 20,
                      height: 16,
                      decoration: BoxDecoration(
                        color: animatedColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Helper widget rendering 4 vertical skeleton bars for a single day group.
class _SkeletonDayBars extends StatelessWidget {
  final List<double> heights;
  final Color animatedColor;

  const _SkeletonDayBars({required this.heights, required this.animatedColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final double barWidth = math.max(
          3.5,
          math.min(14.0, (availableWidth - 8) / 4),
        );
        const double barSpacing = 2.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: heights.map((h) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: barSpacing / 2),
              child: Container(
                width: barWidth,
                height: h,
                decoration: BoxDecoration(
                  color: animatedColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
