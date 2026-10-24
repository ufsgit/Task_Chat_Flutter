import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable Schedule (Calendar) card with interactive inline dropdown calendar.
/// Tapping the schedule card expands/collapses the calendar view directly underneath,
/// matching the custom design with month navigation, Sunday red highlights,
/// selected date circle, Cancel, and 'Set Date' action buttons.
class ScheduleFieldCard extends StatefulWidget {
  final String dateText;
  final ValueChanged<String>? onDateChanged;
  final VoidCallback? onTap;

  const ScheduleFieldCard({
    super.key,
    required this.dateText,
    this.onDateChanged,
    this.onTap,
  });

  @override
  State<ScheduleFieldCard> createState() => _ScheduleFieldCardState();
}

class _ScheduleFieldCardState extends State<ScheduleFieldCard> {
  bool _isExpanded = false;
  late DateTime _confirmedDate;
  late DateTime _tempSelectedDate;
  late DateTime _currentMonthView;

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _confirmedDate = _parseDate(widget.dateText);
    _tempSelectedDate = _confirmedDate;
    _currentMonthView = DateTime(_confirmedDate.year, _confirmedDate.month, 1);
  }

  @override
  void didUpdateWidget(covariant ScheduleFieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateText != widget.dateText) {
      _confirmedDate = _parseDate(widget.dateText);
      _tempSelectedDate = _confirmedDate;
    }
  }

  DateTime _parseDate(String str) {
    try {
      final parts = str.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime(2024, 10, 24);
  }

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$m/$d/${date.year}';
  }

  String _formatSubtitle(DateTime date) {
    final dayName = _weekdays[date.weekday - 1];
    final monthShort = _monthsShort[date.month - 1];
    return '$dayName, $monthShort ${date.day}';
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _tempSelectedDate = _confirmedDate;
        _currentMonthView = DateTime(
          _confirmedDate.year,
          _confirmedDate.month,
          1,
        );
      }
    });
    widget.onTap?.call();
  }

  void _prevMonth() {
    setState(() {
      _currentMonthView = DateTime(
        _currentMonthView.year,
        _currentMonthView.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonthView = DateTime(
        _currentMonthView.year,
        _currentMonthView.month + 1,
        1,
      );
    });
  }

  void _onYearSelected(int year) {
    setState(() {
      _currentMonthView = DateTime(year, _currentMonthView.month, 1);
      final daysInMonth = DateTime(year, _tempSelectedDate.month + 1, 0).day;
      final clampedDay = _tempSelectedDate.day > daysInMonth
          ? daysInMonth
          : _tempSelectedDate.day;
      _tempSelectedDate = DateTime(year, _tempSelectedDate.month, clampedDay);
    });
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _tempSelectedDate = date;
    });
  }

  void _handleCancel() {
    setState(() {
      _tempSelectedDate = _confirmedDate;
      _isExpanded = false;
    });
  }

  void _handleSetDate() {
    setState(() {
      _confirmedDate = _tempSelectedDate;
      _isExpanded = false;
    });
    widget.onDateChanged?.call(_formatDate(_confirmedDate));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // 1. Schedule field card with toggle chevron
        GestureDetector(
          onTap: _toggleExpanded,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? AppDarkColors.surfaceCard
                  : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isExpanded
                    ? (isDark
                          ? AppDarkColors.whatsappGreen
                          : AppColors.primaryGreen)
                    : (isDark ? AppDarkColors.border : AppColors.border),
                width: _isExpanded ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.pillActiveBg
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: isDark
                        ? AppDarkColors.whatsappGreen
                        : AppColors.primaryGreen,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _formatDate(_confirmedDate),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _isExpanded
                      ? (isDark
                            ? AppDarkColors.whatsappGreen
                            : AppColors.primaryGreen)
                      : (isDark
                            ? AppDarkColors.textSubtitle
                            : AppColors.textSubtitle),
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        // 2. Inline Expanded Calendar Card
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          _buildInlineCalendarCard(isDark),
        ],
      ],
    );
  }

  Widget _buildInlineCalendarCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Header: "October 2024" + "Thursday, Oct 24" & Navigation chevrons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _months[_currentMonthView.month - 1],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppDarkColors.textPrimary
                              : AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Dropdown to select year easily when clicked on year
                      PopupMenuButton<int>(
                        tooltip: 'Select Year',
                        initialValue: _currentMonthView.year,
                        onSelected: _onYearSelected,
                        constraints: const BoxConstraints(
                          maxHeight: 180,
                          minWidth: 110,
                          maxWidth: 130,
                        ),
                        color: isDark
                            ? AppDarkColors.surfaceCard
                            : AppColors.surfaceWhite,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? AppDarkColors.border
                                : AppColors.border,
                          ),
                        ),
                        itemBuilder: (context) {
                          final currentYear = DateTime.now().year;
                          final years = List.generate(
                            25,
                            (index) => (currentYear - 12) + index,
                          );
                          return years.map((year) {
                            final isSelected = year == _currentMonthView.year;
                            return PopupMenuItem<int>(
                              value: year,
                              height: 38,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$year',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark
                                                ? AppDarkColors.whatsappGreen
                                                : AppColors.primaryGreen)
                                          : (isDark
                                                ? AppDarkColors.textPrimary
                                                : AppColors.textPrimary),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: isDark
                                          ? AppDarkColors.whatsappGreen
                                          : AppColors.primaryGreen,
                                    ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppDarkColors.surfaceSecondary
                                : AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppDarkColors.border
                                  : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_currentMonthView.year}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppDarkColors.textPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 18,
                                color: isDark
                                    ? AppDarkColors.textSubtitle
                                    : AppColors.textSubtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatSubtitle(_tempSelectedDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppDarkColors.textSubtitle
                          : AppColors.textSubtitle,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _prevMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppDarkColors.surfaceSecondary
                            : AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppDarkColors.surfaceSecondary
                            : AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Days of Week Header: Su, Mo, Tu, We, Th, Fr, Sa
          Row(
            children: const [
              _WeekdayLabel('Su', isSunday: true),
              _WeekdayLabel('Mo'),
              _WeekdayLabel('Tu'),
              _WeekdayLabel('We'),
              _WeekdayLabel('Th'),
              _WeekdayLabel('Fr'),
              _WeekdayLabel('Sa'),
            ],
          ),

          const SizedBox(height: 8),

          // Calendar Days Grid
          _buildDaysGrid(isDark),

          const SizedBox(height: 16),

          // Bottom Actions: Cancel and Set Date
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleCancel,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppDarkColors.textSubtitle
                          : AppColors.textSubtitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleSetDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whatsappGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Set Date',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF0B141B) : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(bool isDark) {
    final year = _currentMonthView.year;
    final month = _currentMonthView.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInCurrentMonth = DateTime(year, month + 1, 0).day;

    // Sunday = 0, Monday = 1 ... Saturday = 6
    final startWeekdayOffset = firstDayOfMonth.weekday % 7;

    final daysInPrevMonth = DateTime(year, month, 0).day;

    final totalGridCells = 35 <= (startWeekdayOffset + daysInCurrentMonth)
        ? 42
        : 35;

    return Column(
      children: List.generate((totalGridCells / 7).ceil(), (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;

              int displayDay;
              bool isCurrentMonth = true;
              DateTime cellDate;

              if (cellIndex < startWeekdayOffset) {
                // Previous month day
                isCurrentMonth = false;
                displayDay =
                    daysInPrevMonth - (startWeekdayOffset - cellIndex - 1);
                cellDate = DateTime(year, month - 1, displayDay);
              } else if (cellIndex >= startWeekdayOffset + daysInCurrentMonth) {
                // Next month day
                isCurrentMonth = false;
                displayDay =
                    cellIndex - (startWeekdayOffset + daysInCurrentMonth) + 1;
                cellDate = DateTime(year, month + 1, displayDay);
              } else {
                // Current month day
                displayDay = cellIndex - startWeekdayOffset + 1;
                cellDate = DateTime(year, month, displayDay);
              }

              final isSelected =
                  isCurrentMonth &&
                  cellDate.year == _tempSelectedDate.year &&
                  cellDate.month == _tempSelectedDate.month &&
                  cellDate.day == _tempSelectedDate.day;

              final isSunday = colIndex == 0;

              Color textColor;
              if (isSelected) {
                textColor = isDark ? const Color(0xFF0B141B) : Colors.white;
              } else if (!isCurrentMonth) {
                textColor = isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1);
              } else if (isSunday) {
                textColor = const Color(0xFFEF4444);
              } else {
                textColor = isDark
                    ? AppDarkColors.textPrimary
                    : AppColors.textPrimary;
              }

              return Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _onDaySelected(cellDate);
                      if (!isCurrentMonth) {
                        setState(() {
                          _currentMonthView = DateTime(
                            cellDate.year,
                            cellDate.month,
                            1,
                          );
                        });
                      }
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.whatsappGreen
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        displayDay.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final bool isSunday;

  const _WeekdayLabel(this.label, {this.isSunday = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSunday
                ? const Color(0xFFEF4444)
                : (isDark
                      ? AppDarkColors.textSubtitle
                      : AppColors.textSubtitle),
          ),
        ),
      ),
    );
  }
}
