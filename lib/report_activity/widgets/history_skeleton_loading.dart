import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Shimmering skeleton card placeholder matching the current BookingHistoryPage UI.
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
            // 1. First Group: Expanded History Card with Timeline Events
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              animatedColor: animatedColor,
              isExpanded: true,
              eventCount: 3,
            ),

            // 2. Second Group: Collapsed History Card
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              animatedColor: animatedColor,
              isExpanded: false,
              eventCount: 0,
            ),

            // 3. Third Group: Collapsed History Card
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              animatedColor: animatedColor,
              isExpanded: false,
              eventCount: 0,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupCard({
    required Color cardBg,
    required Color borderColor,
    required Color animatedColor,
    required bool isExpanded,
    required int eventCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Accordion Header Skeleton matching current BookingHistoryPage
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Clock / History Icon placeholder (40x40 circle)
                _buildBox(
                  color: animatedColor,
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 12),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Client Name + Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBox(
                            color: animatedColor,
                            width: 130,
                            height: 16,
                            borderRadius: 4,
                          ),
                          _buildBox(
                            color: animatedColor,
                            width: 55,
                            height: 12,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Subtitle Row: Status Pill + #ID + · + Updates count
                      Row(
                        children: [
                          _buildBox(
                            color: animatedColor,
                            width: 56,
                            height: 18,
                            borderRadius: 12,
                          ),
                          const SizedBox(width: 8),
                          _buildBox(
                            color: animatedColor,
                            width: 40,
                            height: 12,
                            borderRadius: 4,
                          ),
                          const SizedBox(width: 4),
                          _buildBox(
                            color: animatedColor,
                            width: 4,
                            height: 4,
                            shape: BoxShape.circle,
                          ),
                          const SizedBox(width: 4),
                          _buildBox(
                            color: animatedColor,
                            width: 52,
                            height: 12,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Accordion Chevron Arrow placeholder
                _buildBox(
                  color: animatedColor,
                  width: 18,
                  height: 18,
                  borderRadius: 4,
                ),
              ],
            ),
          ),

          // Expanded Timeline Area
          if (isExpanded) ...[
            Divider(height: 1, thickness: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: List.generate(eventCount, (index) {
                  return _buildTimelineEventSkeleton(
                    animatedColor: animatedColor,
                    borderColor: borderColor,
                    isFirst: index == 0,
                    isLast: index == eventCount - 1,
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineEventSkeleton({
    required Color animatedColor,
    required Color borderColor,
    required bool isFirst,
    required bool isLast,
  }) {
    return Stack(
      children: [
        // Vertical connecting line running behind the dot node
        Positioned(
          top: isFirst ? 14 : 0,
          bottom: isLast ? null : 0,
          height: isLast ? 14 : null,
          left: 11, // Centered inside the 24px wide node column: (24 - 2) / 2
          width: 2,
          child: Container(color: borderColor),
        ),

        // Main row containing Dot Node and Event Content
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Milestone Dot Node (rounded square 14x14)
            SizedBox(
              width: 24,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: animatedColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Event Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Status Badge Pill + Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBox(
                          color: animatedColor,
                          width: 68,
                          height: 20,
                          borderRadius: 10,
                        ),
                        _buildBox(
                          color: animatedColor,
                          width: 48,
                          height: 12,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Action Title (e.g. "Status Updated")
                    _buildBox(
                      color: animatedColor,
                      width: 110,
                      height: 15,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle: Date + by Actor
                    _buildBox(
                      color: animatedColor,
                      width: 150,
                      height: 11,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 10),

                    // Diff Box placeholder
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
                            width: 60,
                            height: 10,
                            borderRadius: 3,
                          ),
                          const SizedBox(height: 6),
                          _buildBox(
                            color: animatedColor,
                            width: 160,
                            height: 14,
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
      ],
    );
  }
}
