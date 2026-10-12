import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../task_report_data.dart';

/// Stacked Bar Chart widget for Task Report.
/// Displays daily breakdown with stacked segments (Completed, Pending, In Progress),
/// average reference dashed line, and day labels.
class TaskBarChart extends StatelessWidget {
  final List<DayTaskBarItem> data;
  final double maxY;
  final double averageLine;
  final double chartHeight;

  const TaskBarChart({
    super.key,
    required this.data,
    this.maxY = 20.0,
    this.averageLine = 14.0,
    this.chartHeight = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart plotting area
        SizedBox(
          height: chartHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Dashed Average Reference Line & Avg Label
              Positioned(
                top: _getYPosition(averageLine, chartHeight),
                left: 0,
                right: 32,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          color: const Color(0xFF5EEAD4),
                          dashWidth: 4,
                          dashSpace: 3,
                        ),
                        child: const SizedBox(height: 1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'avg 14',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Y-Axis labels on the right
              Positioned(
                top: 0,
                right: 0,
                child: Text(
                  maxY.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ),
              const Positioned(
                bottom: 0,
                right: 0,
                child: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ),

              // 3. Bars Row
              Positioned.fill(
                right: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _buildStackedBar(item, chartHeight),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 4. Day Labels Row
        Padding(
          padding: const EdgeInsets.only(right: 36),
          child: Row(
            children: data.map((item) {
              return Expanded(
                child: Center(
                  child: item.isCurrentDay
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.day,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        )
                      : Text(
                          item.day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSubtitle,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  double _getYPosition(double value, double totalHeight) {
    final ratio = (value / maxY).clamp(0.0, 1.0);
    return totalHeight * (1.0 - ratio);
  }

  Widget _buildStackedBar(DayTaskBarItem item, double totalHeight) {
    if (item.total <= 0) {
      return const SizedBox();
    }

    final barHeight = ((item.total / maxY) * totalHeight).clamp(0.0, totalHeight);
    final completedFlex = (item.completed * 1000).round();
    final pendingFlex = (item.pending * 1000).round();
    final inProgressFlex = (item.inProgress * 1000).round();

    final completedColor = item.isPartial
        ? const Color(0xFF99F6E4)
        : AppColors.primaryGreen;

    final pendingColor = item.isPartial
        ? const Color(0xFFFED7AA)
        : const Color(0xFFF97316);

    const inProgressColor = Color(0xFF0284C7);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: barHeight,
        width: 24,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          border: item.isCurrentDay
              ? Border.all(color: const Color(0xFF0284C7), width: 1.2)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          verticalDirection: VerticalDirection.up,
          children: [
            // Completed (Bottom)
            if (completedFlex > 0)
              Expanded(
                flex: completedFlex,
                child: Container(color: completedColor),
              ),
            // Pending (Middle)
            if (pendingFlex > 0)
              Expanded(
                flex: pendingFlex,
                child: Container(color: pendingColor),
              ),
            // In Progress (Top)
            if (inProgressFlex > 0)
              Expanded(
                flex: inProgressFlex,
                child: Container(color: inProgressColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for dashed reference lines.
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
