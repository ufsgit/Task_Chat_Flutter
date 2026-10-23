import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../coordinators/coordinator_update_status_logic.dart';

/// Reusable Branch Manager dropdown selection card for Super Admin.
class BranchManagerFieldCard extends StatelessWidget {
  final String selectedManager;
  final ValueChanged<String> onManagerChanged;
  final List<String>? managers;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const BranchManagerFieldCard({
    super.key,
    required this.selectedManager,
    required this.onManagerChanged,
    this.managers,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branch Manager',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final list = (managers != null && managers!.isNotEmpty)
                ? managers!
                : availableBranchManagers;

            return Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: isDark
                      ? AppDarkColors.surfaceCard
                      : AppColors.dropdownBackground,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppDarkColors.border : AppColors.border,
                      width: 1,
                    ),
                  ),
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                ),
              ),
              child: PopupMenuButton<String>(
                enabled: !isLoading,
                position: PopupMenuPosition.under,
                offset: const Offset(0, 8),
                constraints: BoxConstraints(
                  minWidth: cardWidth,
                  maxWidth: cardWidth,
                  maxHeight: 280,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Select Branch Manager',
                onSelected: onManagerChanged,
                itemBuilder: (context) {
                  return list.map((name) {
                    final isSelected = name == selectedManager;
                    return PopupMenuItem<String>(
                      value: name,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13.5,
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
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
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
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.surfaceCard
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppDarkColors.border : AppColors.border,
                      width: 1,
                    ),
                  ),
                  padding:
                      padding ?? const EdgeInsets.symmetric(horizontal: 14),
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
                          Icons.person_outline,
                          color: isDark
                              ? AppDarkColors.whatsappGreen
                              : AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BRANCH MANAGER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppDarkColors.textSubtitle
                                    : AppColors.textSubtitle,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedManager,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppDarkColors.textPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        )
                      else
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? AppDarkColors.textSubtitle
                              : AppColors.textSubtitle,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
