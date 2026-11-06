import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/status_color_service.dart';
import '../../core/theme.dart';
import '../report/report_model.dart';
import 'graph_skeleton_loading.dart';

export 'graph_skeleton_loading.dart';

/// Card displaying weekly activity grouped bar chart by booking status:
/// - New (Blue)
/// - Scheduled (Orange/Amber)
/// - Completed (Green)
/// - Cancelled (Red)
class WeeklyActivityGraphCard extends StatefulWidget {
  final List<BookingReportGraphItem> graphData;
  final bool isLoading;
  final String? errorMessage;
  final String? dateFrom;
  final String? dateTo;
  final VoidCallback? onRefresh;

  const WeeklyActivityGraphCard({
    super.key,
    required this.graphData,
    this.isLoading = false,
    this.errorMessage,
    this.dateFrom,
    this.dateTo,
    this.onRefresh,
  });

  @override
  State<WeeklyActivityGraphCard> createState() =>
      _WeeklyActivityGraphCardState();
}

class _WeeklyActivityGraphCardState extends State<WeeklyActivityGraphCard> {
  int _selectedDayIndex = 0;

  static Color get colorNew => StatusColorService.getColor('New');
  static Color get colorScheduled => StatusColorService.getColor('Scheduled');
  static Color get colorCompleted => StatusColorService.getColor('Completed');
  static Color get colorCancelled => StatusColorService.getColor('Cancelled');

  @override
  void initState() {
    super.initState();
    _selectMondayDefault();
  }

  @override
  void didUpdateWidget(WeeklyActivityGraphCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graphData != widget.graphData) {
      if (_selectedDayIndex >= widget.graphData.length) {
        _selectMondayDefault();
      }
    }
  }

  void _selectMondayDefault() {
    if (widget.graphData.isEmpty) {
      _selectedDayIndex = 0;
      return;
    }
    final mondayIndex = widget.graphData.indexWhere(
      (item) => item.periodLabel.trim().toLowerCase().startsWith('mon'),
    );
    _selectedDayIndex = mondayIndex != -1 ? mondayIndex : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subtitleTextColor =
        isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle;
    final cardBg =
        isDark ? const Color(0xFF131722) : AppColors.surfaceWhite;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final data = widget.graphData;
    final hasData = data.isNotEmpty;

    // Calculate maximum Y value from live data dynamically
    int rawMax = 0;
    for (final item in data) {
      rawMax = math.max(rawMax, item.newCount);
      rawMax = math.max(rawMax, item.scheduledCount);
      rawMax = math.max(rawMax, item.completedCount);
      rawMax = math.max(rawMax, item.cancelledCount);
    }
    final yScale = _calculateDynamicYScale(rawMax);
    final maxY = yScale.$1;
    final yTicks = yScale.$2;

    final selectedIndex = (_selectedDayIndex >= 0 && _selectedDayIndex < data.length)
        ? _selectedDayIndex
        : 0;

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
          // 1. Header: Title, Subtitle, and Legend + Options Menu
          _buildHeader(primaryTextColor, subtitleTextColor, isDark),

          const SizedBox(height: 18),

          // 2. Chart Area or Loading / Empty state
          if (widget.isLoading)
            const GraphSkeletonLoading(chartPlotHeight: 260.0)
          else if (!hasData)
            _buildEmptyState(primaryTextColor, subtitleTextColor)
          else ...[
            _buildChartArea(data, maxY, yTicks, isDark, subtitleTextColor),
            const SizedBox(height: 18),
            // 3. Information Card (Below Graph, Default Monday)
            _buildSelectedDetails(data[selectedIndex], isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 44,
            color: subtitleColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            widget.errorMessage ?? 'No booking activity for this period',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a date range above to load activity data',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 12,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    Color primaryColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final subtitleText = (widget.dateFrom != null && widget.dateTo != null)
        ? '${widget.dateFrom} to ${widget.dateTo}'
        : 'Mon to Sun, by status';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly activity',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            // Refresh / Reload button
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 21,
                color: subtitleColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
              onPressed: () {
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Legend Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _LegendItem(color: colorNew, label: 'New'),
              const SizedBox(width: 16),
              _LegendItem(color: colorScheduled, label: 'Scheduled'),
              const SizedBox(width: 16),
              _LegendItem(color: colorCompleted, label: 'Completed'),
              const SizedBox(width: 16),
              _LegendItem(color: colorCancelled, label: 'Cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartArea(
    List<BookingReportGraphItem> data,
    int maxY,
    List<int> yTicks,
    bool isDark,
    Color tickColor,
  ) {
    const double chartPlotHeight = 260.0;
    final gridLineColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFF1F5F9);

    final int maxTickLength =
        yTicks.isNotEmpty ? yTicks.last.toString().length : 2;
    final double yLabelWidth = math.max(26.0, maxTickLength * 9.0);

    // If data to be shown is more than 3, enable horizontal scrolling
    final bool isScrollable = data.length > 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            math.max(0.0, constraints.maxWidth - yLabelWidth - 8.0);
        final double itemWidth = isScrollable
            ? math.max(85.0, availableWidth / 3.2)
            : (data.isNotEmpty ? (availableWidth / data.length) : availableWidth);
        final double totalContentWidth =
            isScrollable ? (itemWidth * data.length) : availableWidth;

        Widget buildBarsRow() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (index) {
              final item = data[index];
              final isSelected = _selectedDayIndex == index;

              final barGroup = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _DayGroupBars(
                    item: item,
                    maxY: maxY,
                    chartHeight: chartPlotHeight,
                    isSelected: isSelected,
                    isDark: isDark,
                  ),
                ),
              );

              return isScrollable
                  ? SizedBox(width: itemWidth, child: barGroup)
                  : Expanded(child: barGroup);
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
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? (isDark
                            ? AppDarkColors.whatsappGreen
                            : AppColors.brandGreen)
                        : tickColor,
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
                // Horizontal Gridlines across totalContentWidth
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
                // Bars Layer
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
            const SizedBox(height: 12),
            SizedBox(
              width: totalContentWidth,
              child: buildDayLabelsRow(),
            ),
          ],
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fixed Y-Axis Labels Column on the left
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
                          maxHeight: 20,
                          alignment: Alignment.centerRight,
                          child: Text(
                            tick.toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: tickColor.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Bottom spacing matching day labels height
                const SizedBox(height: 18),
              ],
            ),
            const SizedBox(width: 8),

            // 2. Chart Body (Scrollable if data.length > 3, otherwise flexible)
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
    final cardBg =
        isDark ? const Color(0xFF14171D) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? const Color(0xFF282C35) : const Color(0xFFE2E8F0);
    final primaryTextColor =
        isDark ? Colors.white : AppColors.textPrimary;
    final totalBg =
        isDark ? const Color(0xFF232730) : const Color(0xFFE2E8F0);
    final totalTextColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    final total = item.totalActivities > 0
        ? item.totalActivities
        : (item.newCount +
            item.scheduledCount +
            item.completedCount +
            item.cancelledCount);

    final maxCount = math.max(
      item.newCount,
      math.max(
        item.scheduledCount,
        math.max(item.completedCount, item.cancelledCount),
      ),
    );

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
          // Header: Calendar Icon, Day + Date, and Total badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.periodLabel} (${item.periodDate})',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: totalBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Total: $total',
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: totalTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4 Stacked Status Cards: New, Scheduled, Completed, Cancelled
          _buildStatusRow(
            label: 'New',
            count: item.newCount,
            total: total,
            maxCount: maxCount,
            dotColor: _WeeklyActivityGraphCardState.colorNew,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildStatusRow(
            label: 'Scheduled',
            count: item.scheduledCount,
            total: total,
            maxCount: maxCount,
            dotColor: _WeeklyActivityGraphCardState.colorScheduled,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildStatusRow(
            label: 'Completed',
            count: item.completedCount,
            total: total,
            maxCount: maxCount,
            dotColor: _WeeklyActivityGraphCardState.colorCompleted,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildStatusRow(
            label: 'Cancelled',
            count: item.cancelledCount,
            total: total,
            maxCount: maxCount,
            dotColor: _WeeklyActivityGraphCardState.colorCancelled,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required int count,
    required int total,
    required int maxCount,
    required Color dotColor,
    required bool isDark,
  }) {
    final rowBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final rowBorder =
        isDark ? const Color(0xFF282C35) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rowBorder, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Line 1: Status Title
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                // Line 2: Vertically placed progress bar + count (like iOS Screen Time)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    final double maxBarWidth =
                        math.max(40.0, availableWidth - 65.0);
                    final double ratio = maxCount > 0
                        ? (count / maxCount).clamp(0.0, 1.0)
                        : 0.0;
                    final double barWidth =
                        count > 0 ? math.max(8.0, ratio * maxBarWidth) : 0.0;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (count > 0)
                          Container(
                            width: barWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )
                        else
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF333842)
                                  : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: count > 0
                                ? primaryTextColor
                                : subtitleTextColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      final maxY = ((rawMax + 1) ~/ 2) * 2;
      return (maxY, [for (int i = 0; i <= maxY; i += 2) i]);
    }
    if (rawMax <= 12) {
      final step = (rawMax % 3 == 0) ? 3 : 2;
      final maxY = ((rawMax + step - 1) ~/ step) * step;
      return (maxY, [for (int i = 0; i <= maxY; i += step) i]);
    }
    if (rawMax <= 20) {
      int step;
      if (rawMax == 20) {
        step = 2; // Matches standard [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
      } else if (rawMax % 5 == 0) {
        step = 5;
      } else if (rawMax % 2 == 0) {
        step = 2;
      } else if (rawMax % 3 == 0) {
        step = 3;
      } else {
        step = 2;
      }
      final maxY = ((rawMax + step - 1) ~/ step) * step;
      return (maxY, [for (int i = 0; i <= maxY; i += step) i]);
    }

    // For rawMax > 20, choose dynamic step targeting 4 to 6 intervals
    final double roughStep = rawMax / 5.0;
    final double exp = (math.log(roughStep) / math.ln10).floorToDouble();
    final double magnitude = math.pow(10, exp).toDouble();
    final double norm = roughStep / magnitude;

    double chosenNorm;
    if (norm < 1.5) {
      chosenNorm = 1.0;
    } else if (norm < 3.5) {
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
}

/// A day group displaying 4 grouped vertical bars.
class _DayGroupBars extends StatelessWidget {
  final BookingReportGraphItem item;
  final int maxY;
  final double chartHeight;
  final bool isSelected;
  final bool isDark;

  const _DayGroupBars({
    required this.item,
    required this.maxY,
    required this.chartHeight,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final double barWidth =
            math.max(3.5, math.min(14.0, (availableWidth - 8) / 4));
        const double barSpacing = 2.0;

        return Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(item.newCount, _WeeklyActivityGraphCardState.colorNew,
                  barWidth),
              const SizedBox(width: barSpacing),
              _buildBar(item.scheduledCount,
                  _WeeklyActivityGraphCardState.colorScheduled, barWidth),
              const SizedBox(width: barSpacing),
              _buildBar(item.completedCount,
                  _WeeklyActivityGraphCardState.colorCompleted, barWidth),
              const SizedBox(width: barSpacing),
              _buildBar(item.cancelledCount,
                  _WeeklyActivityGraphCardState.colorCancelled, barWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(int count, Color color, double width) {
    final double safeMax = maxY > 0 ? maxY.toDouble() : 1.0;
    final double ratio = math.min(1.0, count / safeMax);
    final double barHeight = ratio * (chartHeight - 12);

    return Container(
      width: width,
      height: math.max(1.5, barHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
      ),
    );
  }
}

/// Single legend item with colored square and label.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
