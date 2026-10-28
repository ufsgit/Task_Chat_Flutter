import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

/// Formatter that allows typing only numeric digits and keeps slashes permanent.
/// As the user types digits, it automatically inserts '/' after MM and DD.
/// When deleting over a '/', it cleanly removes the preceding digit.
class PermanentSlashDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text == newValue.text) return newValue;

    final isDeleting = oldValue.text.length > newValue.text.length;
    String rawDigits;

    if (isDeleting) {
      final oldSelectionEnd = oldValue.selection.end;
      // If cursor was directly after a slash (index 3 or 6) and backspace was pressed
      if (oldSelectionEnd > 0 &&
          oldSelectionEnd <= oldValue.text.length &&
          oldValue.text[oldSelectionEnd - 1] == '/') {
        final beforeSlash = oldValue.text.substring(0, oldSelectionEnd - 1);
        final afterSlash = oldValue.text.substring(oldSelectionEnd);
        final trimmedBefore = beforeSlash.isNotEmpty
            ? beforeSlash.substring(0, beforeSlash.length - 1)
            : '';
        rawDigits = (trimmedBefore + afterSlash).replaceAll(RegExp(r'\D'), '');
      } else {
        rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
      }
    } else {
      rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    }

    if (rawDigits.length > 8) {
      rawDigits = rawDigits.substring(0, 8);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < rawDigits.length; i++) {
      buffer.write(rawDigits[i]);
      if (i == 1 || i == 3) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();

    // Compute appropriate cursor position
    int selectionIndex;
    if (!isDeleting && (formatted.length == 3 || formatted.length == 6)) {
      selectionIndex = formatted.length;
    } else if (newValue.selection.end <= formatted.length) {
      int digitsCount = 0;
      final targetDigits = newValue.text
          .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
          .replaceAll(RegExp(r'\D'), '')
          .length;
      int idx = 0;
      while (idx < formatted.length && digitsCount < targetDigits) {
        if (formatted[idx] != '/') {
          digitsCount++;
        }
        idx++;
      }
      if (!isDeleting && idx < formatted.length && formatted[idx] == '/') {
        idx++;
      }
      selectionIndex = idx;
    } else {
      selectionIndex = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: selectionIndex.clamp(0, formatted.length),
      ),
    );
  }
}

/// Custom date range picker dialog matching the clean modal card design with permanent slashes.
class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDateRangePickerDialog({
    super.key,
    this.initialDateRange,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState
    extends State<CustomDateRangePickerDialog> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  String? _errorMessage;

  static const List<String> _months = [
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

  @override
  void initState() {
    super.initState();
    final start = widget.initialDateRange?.start ?? DateTime.now();
    final end = widget.initialDateRange?.end ?? DateTime.now();

    _startController = TextEditingController(text: _formatDate(start));
    _endController = TextEditingController(text: _formatDate(end));

    _startController.addListener(_onTextChanged);
    _endController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _startController.removeListener(_onTextChanged);
    _endController.removeListener(_onTextChanged);
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  static String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m/$day/${d.year}';
  }

  DateTime? _parseDate(String str) {
    final parts = str.trim().split('/');
    if (parts.length != 3) return null;
    final p0 = int.tryParse(parts[0]);
    final p1 = int.tryParse(parts[1]);
    final p2 = int.tryParse(parts[2]);
    if (p0 == null || p1 == null || p2 == null) return null;
    if (parts[2].length != 4) return null;

    int month = p0;
    int day = p1;
    final year = p2;

    // Handle DD/MM/YYYY if day is in first position
    if (p0 > 12 && p1 <= 12) {
      day = p0;
      month = p1;
    }

    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    if (year < 1970 || year > 2100) return null;

    try {
      final date = DateTime(year, month, day);
      if (date.month != month || date.day != day) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  String _buildHeaderTitle() {
    final start = _parseDate(_startController.text);
    final end = _parseDate(_endController.text);

    if (start == null && end == null) return 'Select range';
    if (start != null && end == null) {
      return '${_months[start.month - 1]} ${start.day}, ${start.year} – End Date';
    }
    if (start == null && end != null) {
      return 'Start Date – ${_months[end.month - 1]} ${end.day}, ${end.year}';
    }
    if (start!.year == end!.year) {
      return '${_months[start.month - 1]} ${start.day} – ${_months[end.month - 1]} ${end.day}, ${start.year}';
    }
    return '${_months[start.month - 1]} ${start.day}, ${start.year} – ${_months[end.month - 1]} ${end.day}, ${end.year}';
  }

  void _onConfirm() {
    final start = _parseDate(_startController.text);
    final end = _parseDate(_endController.text);

    if (start == null || end == null) {
      setState(() {
        _errorMessage = 'Please enter valid dates (MM/DD/YYYY)';
      });
      return;
    }

    if (start.isAfter(end)) {
      setState(() {
        _errorMessage = 'Start date must be before end date';
      });
      return;
    }

    if (widget.firstDate != null && start.isBefore(widget.firstDate!)) {
      setState(() {
        _errorMessage = 'Date cannot be before ${_formatDate(widget.firstDate!)}';
      });
      return;
    }

    if (widget.lastDate != null && end.isAfter(widget.lastDate!)) {
      setState(() {
        _errorMessage = 'Date cannot be after ${_formatDate(widget.lastDate!)}';
      });
      return;
    }

    Navigator.of(context).pop(DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final borderInactive =
        isDark ? const Color(0xFF3E3E48) : const Color(0xFF79747E);

    return Dialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top label: "Select range"
              Text(
                'Select range',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Large headline title (e.g. "Oct 6, 2023 – Oct 28, 2026")
              Text(
                _buildHeaderTitle(),
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),

              // Input Row: Start Date & End Date
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      controller: _startController,
                      label: 'Start Date',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      borderInactive: borderInactive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      controller: _endController,
                      label: 'End Date',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      borderInactive: borderInactive,
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Action buttons: Cancel / OK
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      textStyle: const TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _onConfirm,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      textStyle: const TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    required Color textPrimary,
    required Color borderInactive,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
        PermanentSlashDateInputFormatter(),
      ],
      style: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'MM/DD/YYYY',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderInactive),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderInactive),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Helper function to open the clean date range picker dialog.
Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierDismissible: true,
    builder: (context) => CustomDateRangePickerDialog(
      initialDateRange: initialDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}
