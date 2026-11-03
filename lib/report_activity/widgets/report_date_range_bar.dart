import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Date range filter bar displaying From Date and To Date pickers.
/// Allows users to filter the booking report graph by a custom date range.
class ReportDateRangeBar extends StatelessWidget {
  final String? dateFrom;
  final String? dateTo;
  final void Function(String from, String to) onDateRangeChanged;
  final VoidCallback? onClear;

  const ReportDateRangeBar({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.onDateRangeChanged,
    this.onClear,
  });

  String _formatDisplayDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Select date';
    final parts = isoDate.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return isoDate;
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (isFrom && dateFrom != null && dateFrom!.isNotEmpty) {
      initial = DateTime.tryParse(dateFrom!) ?? now;
    } else if (!isFrom && dateTo != null && dateTo!.isNotEmpty) {
      initial = DateTime.tryParse(dateTo!) ?? now;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      if (isFrom) {
        final effectiveTo = dateTo ?? formatted;
        onDateRangeChanged(formatted, effectiveTo);
      } else {
        final effectiveFrom = dateFrom ?? formatted;
        onDateRangeChanged(effectiveFrom, formatted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131722) : AppColors.surfaceWhite;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final primaryTextColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle;
    final hasActiveFilter = (dateFrom != null && dateFrom!.isNotEmpty) ||
        (dateTo != null && dateTo!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveFilter
              ? (isDark ? AppDarkColors.primaryGreen : AppColors.brandGreen)
              : borderColor,
          width: hasActiveFilter ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. From Date Button
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pickDate(context, true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: isDark
                              ? AppDarkColors.whatsappGreen
                              : AppColors.brandGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'From',
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDisplayDate(dateFrom),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dateFrom != null
                            ? primaryTextColor
                            : subtitleColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Arrow Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: subtitleColor.withValues(alpha: 0.6),
            ),
          ),

          // 2. To Date Button
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pickDate(context, false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 12,
                          color: isDark
                              ? AppDarkColors.whatsappGreen
                              : AppColors.brandGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'To',
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDisplayDate(dateTo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dateTo != null
                            ? primaryTextColor
                            : subtitleColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Clear button if filter active
          if (hasActiveFilter && onClear != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: subtitleColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

