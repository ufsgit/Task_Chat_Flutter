import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../area_model.dart';
import '../area_view_model.dart';
import 'lead_form_card.dart';

/// A dropdown selector widget for Areas/Districts built with MVVM architecture.
/// Displays an elegant selector box that opens the dropdown menu directly *below*
/// the box with uniform padding, margins, and the app's 'Helvetica Neue' typography.
class AreaSelectorDropdown extends StatelessWidget {
  final AreaViewModel viewModel;
  final ValueChanged<AreaItem?>? onAreaSelected;
  final String label;
  final double labelWidth;

  const AreaSelectorDropdown({
    super.key,
    required this.viewModel,
    this.onAreaSelected,
    this.label = 'Area',
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

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
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
      },
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
    if (viewModel.isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.whatsappGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading areas...',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 14.5,
              color: placeholderColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (viewModel.errorMessage != null && viewModel.areas.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
                color: Color(0xFFEF4444),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.whatsappGreen,
            tooltip: 'Retry',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => viewModel.fetchAreas(),
          ),
        ],
      );
    }

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
          child: PopupMenuButton<AreaItem>(
            key: const Key('area_selector_dropdown'),
            position: PopupMenuPosition.under,
            offset: const Offset(0, 10),
            constraints: BoxConstraints(
              minWidth: menuWidth,
              maxWidth: menuWidth,
              maxHeight: 280,
            ),
            padding: EdgeInsets.zero,
            onSelected: (AreaItem area) {
              viewModel.selectArea(area);
              if (onAreaSelected != null) {
                onAreaSelected!(area);
              }
            },
            itemBuilder: (BuildContext popupContext) {
              if (viewModel.areas.isEmpty) {
                return [
                  PopupMenuItem<AreaItem>(
                    enabled: false,
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'No areas available',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 14,
                        color: placeholderColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ];
              }

              return viewModel.areas.map((AreaItem area) {
                final isSelected = viewModel.selectedArea?.id == area.id;

                return PopupMenuItem<AreaItem>(
                  value: area,
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
                            area.name,
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
                    viewModel.selectedArea != null
                        ? viewModel.selectedArea!.name
                        : 'Select $label',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 15,
                      fontWeight: viewModel.selectedArea != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: viewModel.selectedArea != null
                          ? primaryTextColor
                          : placeholderColor,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (viewModel.selectedArea != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      viewModel.clearSelection();
                      if (onAreaSelected != null) {
                        onAreaSelected!(null);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: placeholderColor,
                      ),
                    ),
                  ),
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
