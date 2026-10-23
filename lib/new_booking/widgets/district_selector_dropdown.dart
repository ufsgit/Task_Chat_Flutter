import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../district_model.dart';
import 'lead_form_card.dart';

/// Available hardcoded districts for Coordinator role as fallback.
const List<String> defaultHardcodedDistricts = [
  'Ernakulam',
  'Thiruvananthapuram',
  'Kozhikode',
  'Thrissur',
  'Kannur',
];

/// A dropdown selector widget for District selection displayed for Coordinator role.
/// Consistent with [AreaSelectorDropdown] and the app's 'Helvetica Neue' typography.
class DistrictSelectorDropdown extends StatelessWidget {
  final String? selectedDistrict;
  final List<String> districts;
  final List<DistrictItem>? districtItems;
  final ValueChanged<String>? onDistrictSelected;
  final ValueChanged<DistrictItem>? onDistrictItemSelected;
  final bool isLoading;
  final String label;
  final double labelWidth;

  const DistrictSelectorDropdown({
    super.key,
    this.selectedDistrict,
    this.districts = defaultHardcodedDistricts,
    this.districtItems,
    this.onDistrictSelected,
    this.onDistrictItemSelected,
    this.isLoading = false,
    this.label = 'District',
    this.labelWidth = 80,
  });

  static const String _fontFamily = 'Helvetica Neue';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : const Color(0xFF0F172A);
    final placeholderColor = isDark
        ? AppDarkColors.textPlaceholder
        : const Color(0xFF94A3B8);
    final cardBgColor = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final borderColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);

    return LeadFormCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Expanded(
            child: _buildSelectorBox(
              context: context,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              placeholderColor: placeholderColor,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorBox({
    required BuildContext context,
    required bool isDark,
    required Color primaryTextColor,
    required Color placeholderColor,
    required Color cardBgColor,
    required Color borderColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth;

        return Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: cardBgColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: borderColor, width: 1),
              ),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.12),
            ),
          ),
          child: PopupMenuButton<String>(
            key: const Key('district_selector_dropdown'),
            position: PopupMenuPosition.under,
            offset: const Offset(0, 10),
            constraints: BoxConstraints(
              minWidth: menuWidth,
              maxWidth: menuWidth,
              maxHeight: 240,
            ),
            padding: EdgeInsets.zero,
            onSelected: (String districtName) {
              if (onDistrictSelected != null) {
                onDistrictSelected!(districtName);
              }
              if (onDistrictItemSelected != null && districtItems != null) {
                final match = districtItems!
                    .where((d) => d.name == districtName)
                    .firstOrNull;
                if (match != null) {
                  onDistrictItemSelected!(match);
                }
              }
            },
            itemBuilder: (BuildContext popupContext) {
              final items = districtItems != null && districtItems!.isNotEmpty
                  ? districtItems!
                  : districts
                      .map((name) => DistrictItem(id: 0, name: name))
                      .toList();

              return items.map((districtItem) {
                final isSelected = selectedDistrict != null &&
                    selectedDistrict!.toLowerCase() ==
                        districtItem.name.toLowerCase();

                return PopupMenuItem<String>(
                  value: districtItem.name,
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Container(
                    decoration: isSelected
                        ? BoxDecoration(
                            color: AppColors.whatsappGreen.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            districtItem.name,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 14.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.whatsappGreen
                                  : primaryTextColor,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.whatsappGreen,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList();
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDistrict != null && selectedDistrict!.isNotEmpty
                        ? selectedDistrict!
                        : 'Select $label',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 15,
                      fontWeight: selectedDistrict != null &&
                              selectedDistrict!.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: selectedDistrict != null &&
                              selectedDistrict!.isNotEmpty
                          ? primaryTextColor
                          : placeholderColor,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.whatsappGreen,
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: placeholderColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
