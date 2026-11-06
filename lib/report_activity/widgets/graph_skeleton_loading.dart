import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shimmering skeleton placeholder for the status activity graph card.
class GraphSkeletonLoading extends StatefulWidget {
  final double chartPlotHeight;
  final int dayCount;

  const GraphSkeletonLoading({
    super.key,
    this.chartPlotHeight = 190.0,
    this.dayCount = 7,
  });

  @override
  State<GraphSkeletonLoading> createState() => _GraphSkeletonLoadingState();
}

class _GraphSkeletonLoadingState extends State<GraphSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  // Realistic simulated single bar heights matching the single-status activity trend
  static const List<double> _simulatedBarHeights = [
    120,
    65,
    145,
    85,
    160,
    50,
    25,
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
    final bool isScrollable = widget.dayCount > 5;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedColor = baseColor.withValues(alpha: _animation.value);

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth =
                math.max(0.0, constraints.maxWidth - yLabelWidth - 8.0);
            final double itemWidth = isScrollable
                ? math.max(54.0, availableWidth / 5.2)
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
                          children: List.generate(5, (_) {
                            return Container(
                              height: 1.0,
                              color: gridLineColor,
                            );
                          }),
                        ),
                      ),

                      // Single vertical bars matching StatusActivityGraphCard
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(widget.dayCount, (index) {
                            final rawHeight = _simulatedBarHeights[
                                index % _simulatedBarHeights.length];
                            final barHeight = math.min(
                              rawHeight,
                              widget.chartPlotHeight - 26,
                            );
                            final double barWidth = math.max(
                              12.0,
                              math.min(26.0, itemWidth * 0.45),
                            );

                            final barWidget = Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Top value label placeholder
                                Container(
                                  width: 14,
                                  height: 9,
                                  margin: const EdgeInsets.only(bottom: 4.0),
                                  decoration: BoxDecoration(
                                    color: animatedColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Container(
                                  width: barWidth,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: animatedColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5.0),
                                    ),
                                  ),
                                ),
                              ],
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
                const SizedBox(height: 10),
                SizedBox(
                  width: totalContentWidth,
                  child: Row(
                    children: List.generate(widget.dayCount, (index) {
                      final labelWidget = Center(
                        child: Container(
                          width: 26,
                          height: 11,
                          decoration: BoxDecoration(
                            color: animatedColor,
                            borderRadius: BorderRadius.circular(3),
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
                            children: List.generate(5, (_) {
                              return SizedBox(
                                height: 1.0,
                                child: OverflowBox(
                                  maxHeight: 14,
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 20,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: animatedColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 14),
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

                // Selected Details Card matching StatusActivityGraphCard
                _buildSelectedDetailsSkeleton(animatedColor, isDark),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedDetailsSkeleton(Color animatedColor, bool isDark) {
    final rowBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final rowBorder =
        isDark ? const Color(0xFF282C35) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rowBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Calendar placeholder + Date text + Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: animatedColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: animatedColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 28,
                height: 17,
                decoration: BoxDecoration(
                  color: animatedColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linear Progress Bar track placeholder
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: animatedColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 12,
                decoration: BoxDecoration(
                  color: animatedColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
