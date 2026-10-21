import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable search input field styled to match the Fitmate theme.
class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final EdgeInsetsGeometry? padding;

  const SearchInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search',
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchBg = isDark
        ? AppDarkColors.surfaceGrey
        : const Color(0xFFF0F2F5);
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final hintColor = isDark
        ? AppDarkColors.textSubtitle
        : AppColors.textSubtitle;

    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: searchBg,
          borderRadius: BorderRadius.circular(21),
          border: isDark
              ? Border.all(color: AppDarkColors.border, width: 1)
              : null,
        ),
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Helvetica Neue',
              color: hintColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.search_rounded, color: hintColor, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: hintColor,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                      },
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(right: 14),
          ),
        ),
      ),
    );
  }
}
