import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../report/report_model.dart';
import 'graph_skeleton_loading.dart';

/// A dedicated graph card displaying activity trends for a single specific booking status.
class StatusActivityGraphCard extends StatefulWidget {
  final String statusTitle;
  final Color statusColor;
  final IconData statusIcon;
  final int Function(BookingReportGraphItem) getCount;
  final List<BookingReportGraphItem> graphData;
  final bool isLoading;
  final String? errorMessage;
  final String? dateFrom;
  final String? dateTo;

  const StatusActivityGraphCard({
    super.key,
    required this.statusTitle,
    required this.statusColor,
    required this.statusIcon,
    required this.getCount,
    required this.graphData,
    this.isLoading = false,
    this.errorMessage,
    this.dateFrom,
    this.dateTo,
  });

  @override
  State<StatusActivityGraphCard> createState() =>
      _StatusActivityGraphCardState();
}

class _StatusActivityGraphCardState extends State<StatusActivityGraphCard> {
  int _selectedDayIndex = 0;

  @override
  void didUpdateWidget(covariant StatusActivityGraphCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.graphData != oldWidget.graphData) {
      if (_selectedDayIndex >= widget.graphData.length) {
        _selectedDayIndex = 0;
      }
    }
  }

  String _buildSubtitle() {
    if (widget.dateFrom != null && widget.dateTo != null) {
      return '${widget.dateFrom} to ${widget.dateTo}';
    } else if (widget.dateFrom != null) {
      return 'From ${widget.dateFrom}';
    } else if (widget.dateTo != null) {
      return 'Until ${widget.dateTo}';
    }
    return 'Daily activity trend';
  }

  int _calculateTotalCount(List<BookingReportGraphItem> data) {
    var sum = 0;
    for (final item in data) {
      sum += widget.getCount(item);
    }
    return sum;
  }

  (int, List<int>) _calculateDynamicYScale(int rawMax) {
    if (rawMax <= 0) {
      return (4, const [0, 1, 2, 3, 4]);
    }
    if (rawMax <= 4) {
      final maxY = math.max(rawMax, 2);
      return (maxY, List<int>.generate(maxY + 1, (i) => i));
    }
    if (rawMax <= 8) {
      if (rawMax == 5) {
        return (5, const [0, 1, 2, 3, 4, 5]);
      }
      return (8, const [0, 2, 4, 6, 8]);
    }
    if (rawMax <= 12) {
      return (12, const [0, 3, 6, 9, 12]);
    }
    if (rawMax <= 20) {
      return (20, const [0, 5, 10, 15, 20]);
    }

    final roughStep = rawMax / 4.0;
    final magnitude =
        math.pow(10, (math.log(roughStep) / math.ln10).floor()).toDouble();
    final norm = roughStep / magnitude;

    double chosenNorm;
    if (norm < 1.5) {
      chosenNorm = 1.0;
    } else if (norm < 3.0) {
      chosenNorm = 2.0;
    } else if (norm < 7.5) {
      chosenNorm = 5.0;
    } else {
      chosenNorm = 10.0;
    }
    final step = math.max(1, (chosenNorm * magnitude).round());
    final maxY = ((rawMax + step - 1) ~/ step) * step;
    final ticks = [for (int i = 0; i <= maxY; i += step) i];
    return (maxY, ticks);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? const Color(0xFF14171D) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? const Color(0xFF282C35) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B);

    final data = widget.graphData;
    final bool hasData = data.isNotEmpty;

    var rawMax = 0;
    for (final item in data) {
      rawMax = math.max(rawMax, widget.getCount(item));
    }

    final yScale = _calculateDynamicYScale(rawMax);
    final maxY = yScale.$1;
    final yTicks = yScale.$2;

    final selectedIndex =
        (_selectedDayIndex >= 0 && _selectedDayIndex < data.length)
            ? _selectedDayIndex
            : 0;

    final totalStatusCount = _calculateTotalCount(data);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Icon, Title, Subtitle, and Total Badge
          _buildHeader(
            primaryColor: primaryTextColor,
            subtitleColor: subtitleTextColor,
            totalCount: totalStatusCount,
            isDark: isDark,
          ),

          const SizedBox(height: 18),

          // Chart Area or Loading / Empty state
          if (widget.isLoading)
            const GraphSkeletonLoading(chartPlotHeight: 200.0)
          else if (!hasData)
            _buildEmptyState(primaryTextColor, subtitleTextColor)
          else ...[
            _buildChartArea(data, maxY, yTicks, isDark, subtitleTextColor),
            const SizedBox(height: 18),
            _buildSelectedDetails(data[selectedIndex], isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader({
    required Color primaryColor,
    required Color subtitleColor,
    required int totalCount,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.statusIcon,
                  size: 20,
                  color: widget.statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.statusTitle,
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildSubtitle(),
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Total: $totalCount',
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 40,
            color: subtitleColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            widget.errorMessage ?? 'No ${widget.statusTitle.toLowerCase()} for this period',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea(
    List<BookingReportGraphItem> data,
    int maxY,
    List<int> yTicks,
    bool isDark,
    Color tickColor,
  ) {
    const double chartPlotHeight = 190.0;
    final gridLineColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFF1F5F9);

    final int maxTickLength =
        yTicks.isNotEmpty ? yTicks.last.toString().length : 2;
    final double yLabelWidth = math.max(24.0, maxTickLength * 8.5);

    final bool isScrollable = data.length > 5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            math.max(0.0, constraints.maxWidth - yLabelWidth - 8.0);
        final double itemWidth = isScrollable
            ? math.max(54.0, availableWidth / 5.2)
            : (data.isNotEmpty ? (availableWidth / data.length) : availableWidth);
        final double totalContentWidth =
            isScrollable ? (itemWidth * data.length) : availableWidth;

        Widget buildBarsRow() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (index) {
              final item = data[index];
              final count = widget.getCount(item);
              final isSelected = _selectedDayIndex == index;

              const double topTextReserve = 22.0;
              final double maxBarHeight = chartPlotHeight - topTextReserve;
              final barHeight =
                  maxY > 0 ? (count / maxY) * maxBarHeight : 0.0;

              final barWidget = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected || count > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? widget.statusColor
                                  : tickColor,
                            ),
                          ),
                        ),
                      Container(
                        width: math.max(12.0, math.min(26.0, itemWidth * 0.45)),
                        height: math.max(count > 0 ? 4.0 : 0.0, barHeight),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.statusColor
                              : widget.statusColor.withValues(alpha: 0.82),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.2,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              return isScrollable
                  ? SizedBox(width: itemWidth, child: barWidget)
                  : Expanded(child: barWidget);
            }),
          );
        }

        Widget buildDayLabelsRow() {
          return Row(
            children: List.generate(data.length, (index) {
              final item = data[index];
              final isSelected = _selectedDayIndex == index;

              final labelWidget = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Text(
                  item.periodLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 12.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? widget.statusColor : tickColor,
                  ),
                ),
              );

              return isScrollable
                  ? SizedBox(width: itemWidth, child: labelWidget)
                  : Expanded(child: labelWidget);
            }),
          );
        }

        Widget buildPlotStack() {
          return SizedBox(
            height: chartPlotHeight,
            width: totalContentWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(yTicks.length, (_) {
                      return Container(
                        height: 1.0,
                        color: gridLineColor,
                      );
                    }),
                  ),
                ),
                Positioned.fill(
                  child: buildBarsRow(),
                ),
              ],
            ),
          );
        }

        final chartContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPlotStack(),
            const SizedBox(height: 10),
            SizedBox(
              width: totalContentWidth,
              child: buildDayLabelsRow(),
            ),
          ],
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                SizedBox(
                  height: chartPlotHeight,
                  width: yLabelWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: yTicks.reversed.map((tick) {
                      return SizedBox(
                        height: 1.0,
                        child: OverflowBox(
                          maxHeight: 18,
                          alignment: Alignment.centerRight,
                          child: Text(
                            tick.toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: tickColor.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(width: 8),
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
        );
      },
    );
  }

  Widget _buildSelectedDetails(BookingReportGraphItem item, bool isDark) {
    final rowBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final rowBorder =
        isDark ? const Color(0xFF282C35) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B);
    final trackColor =
        isDark ? const Color(0xFF282C35) : const Color(0xFFF1F5F9);

    final count = widget.getCount(item);
    final dayTotal = item.totalActivities > 0
        ? item.totalActivities
        : (item.newCount +
            item.scheduledCount +
            item.completedCount +
            item.cancelledCount);

    final double progress =
        dayTotal > 0 ? (count / dayTotal).clamp(0.0, 1.0) : 0.0;
    final double percent = progress * 100.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: widget.statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.periodLabel} (${item.periodDate})',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: widget.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.statusColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percent.toStringAsFixed(1)}% of day',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: subtitleTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
