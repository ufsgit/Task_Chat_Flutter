import 'package:flutter/material.dart';

/// Reusable search input field styled to match the TaskChat theme.
class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const SearchInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
