import 'package:flutter/material.dart';

/// Reusable form row containing a fixed-width label and an input field.
class LeadLabeledRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final double labelWidth;

  const LeadLabeledRow({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.labelWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
