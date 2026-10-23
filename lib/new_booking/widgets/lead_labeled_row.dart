import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

/// Reusable form row containing a fixed-width label and an input field.
class LeadLabeledRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final double labelWidth;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const LeadLabeledRow({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.labelWidth = 80,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppDarkColors.textPrimary : const Color(0xFF0F172A),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppDarkColors.textPrimary : const Color(0xFF334155),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              counterText: '',
              hintStyle: TextStyle(
                color: isDark
                    ? AppDarkColors.textPlaceholder
                    : const Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
