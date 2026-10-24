import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../today_model.dart';

/// Modal bottom sheet widget for filtering leads and tasks on the Today page.
class TodayFilterBottomSheet extends StatefulWidget {
  final String selectedStatus;
  final List<String> statusOptions;
  final String? selectedDistrictId;
  final String? selectedDateFrom;
  final String? selectedDateTo;
  final String? selectedFilterRole;
  final void Function(String status) onApply;
  final void Function({
    required String status,
    String? districtId,
    String? dateFrom,
    String? dateTo,
    String? filterRole,
  })? onApplyAdvanced;
  final VoidCallback? onReset;

  const TodayFilterBottomSheet({
    super.key,
    required this.selectedStatus,
    required this.statusOptions,
    this.selectedDistrictId,
    this.selectedDateFrom,
    this.selectedDateTo,
    this.selectedFilterRole,
    required this.onApply,
    this.onApplyAdvanced,
    this.onReset,
  });

  @override
  State<TodayFilterBottomSheet> createState() => _TodayFilterBottomSheetState();
}

class _TodayFilterBottomSheetState extends State<TodayFilterBottomSheet> {
  late String _tempStatus;
  late String? _tempDateFrom;
  late String? _tempDateTo;

  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempStatus = widget.selectedStatus;
    _tempDateFrom = widget.selectedDateFrom;
    _tempDateTo = widget.selectedDateTo;

    if (_tempDateFrom != null && _tempDateFrom!.isNotEmpty) {
      _dateFromController.text = formatDateToDayMonthYear(_tempDateFrom!);
    }
    if (_tempDateTo != null && _tempDateTo!.isNotEmpty) {
      _dateToController.text = formatDateToDayMonthYear(_tempDateTo!);
    }
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller, bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final apiFormat =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final displayFormat =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        controller.text = displayFormat;
        if (isFrom) {
          _tempDateFrom = apiFormat;
        } else {
          _tempDateTo = apiFormat;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final subtitleTextColor = isDark
        ? AppDarkColors.textSubtitle
        : AppColors.textSecondary;
    final dividerColor = isDark ? AppDarkColors.divider : AppColors.divider;
    final handleColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
    final cardBg = isDark ? AppDarkColors.surfaceGrey : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  if (widget.onReset != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempStatus = 'All';
                          _tempDateFrom = null;
                          _tempDateTo = null;
                          _dateFromController.clear();
                          _dateToController.clear();
                        });
                        widget.onReset?.call();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Reset All',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),
              Divider(color: dividerColor, height: 20, thickness: 0.6),

              // Status Section
              Text(
                'Status',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: subtitleTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: widget.statusOptions.map((status) {
                  final isSelected = _tempStatus == status;
                  return AppFilterChip(
                    label: status,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _tempStatus = status;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Date Range Section (date/month/year format: DD/MM/YYYY)
              Text(
                'Date Range (DD/MM/YYYY)',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: subtitleTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(_dateFromController, true),
                      child: IgnorePointer(
                        child: TextField(
                          controller: _dateFromController,
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 13,
                            color: primaryTextColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Date From',
                            hintStyle: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            filled: true,
                            fillColor: cardBg,
                            prefixIcon: Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: subtitleTextColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(_dateToController, false),
                      child: IgnorePointer(
                        child: TextField(
                          controller: _dateToController,
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 13,
                            color: primaryTextColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Date To',
                            hintStyle: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            filled: true,
                            fillColor: cardBg,
                            prefixIcon: Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: subtitleTextColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final from = _tempDateFrom ?? '';
                    final to = _tempDateTo ?? '';

                    if (widget.onApplyAdvanced != null) {
                      widget.onApplyAdvanced!(
                        status: _tempStatus,
                        dateFrom: from.isNotEmpty ? from : null,
                        dateTo: to.isNotEmpty ? to : null,
                      );
                    } else {
                      widget.onApply(_tempStatus);
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsappGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
