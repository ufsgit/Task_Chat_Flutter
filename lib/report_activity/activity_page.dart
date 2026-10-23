import 'package:flutter/material.dart';
import '../core/widgets/circular_back_button.dart';
import '../core/theme.dart';
import '../today/widgets/filter_chips_bar.dart';
import '../today/widgets/search_input_field.dart';
import '../today/widgets/today_filter_bottom_sheet.dart';
import 'activity_data.dart';
import 'widgets/activity_item_card.dart';

/// Activity history screen matching the Today page reference design.
/// Includes the same SearchInputField, Filter button & TodayFilterBottomSheet,
/// and horizontal FilterChipsBar (All, Unread, Pending, Scheduled, Done).
class ActivityPage extends StatefulWidget {
  final VoidCallback? onBack;

  const ActivityPage({super.key, this.onBack});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final TextEditingController _searchController = TextEditingController();

  // Time filter chips ('Today', 'This Week', 'This Month')
  int _selectedFilterIndex = 0;
  final List<String> _filters = activityTimeFilters;

  // Status bottom sheet filter matching Today page
  String _selectedStatusFilter = 'All';
  final List<String> _statusOptions = const [
    'All',
    'New',
    'Scheduled',
    'Completed',
    'Cancelled',
  ];

  bool get _hasActiveFilters => _selectedStatusFilter != 'All';

  void _openFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppDarkColors.surfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TodayFilterBottomSheet(
        selectedStatus: _selectedStatusFilter,
        statusOptions: _statusOptions,
        onApply: (status) {
          setState(() {
            _selectedStatusFilter = status;
          });
        },
        onReset: () {
          setState(() {
            _selectedStatusFilter = 'All';
          });
        },
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDeleted,
    required bool isDark,
  }) {
    final bg = isDark ? AppColors.whatsappGreen : AppColors.chipPendingBg;
    final fg = isDark ? Colors.white : AppColors.chipPendingText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(Icons.close_rounded, size: 14, color: fg),
          ),
        ],
      ),
    );
  }

  List<ActivityItemData> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return defaultActivityItems.where((item) {
      // 1. Status Filter from bottom sheet
      if (_selectedStatusFilter != 'All') {
        final status = item.statusTag ?? '';
        if (status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }

      // 2. Horizontal Time Filter Chips ('Today', 'This Week', 'This Month')
      final selectedTimeFilter = _filters[_selectedFilterIndex];
      if (selectedTimeFilter == 'Today' && item.timeFilter != 'Today') {
        return false;
      } else if (selectedTimeFilter == 'This Week' &&
          item.timeFilter != 'Today' &&
          item.timeFilter != 'This Week') {
        return false;
      } else if (selectedTimeFilter == 'This Month' &&
          item.timeFilter != 'Today' &&
          item.timeFilter != 'This Week' &&
          item.timeFilter != 'This Month') {
        return false;
      }

      // 3. Search query
      if (query.isNotEmpty) {
        final title = item.title.toLowerCase();
        final note = item.noteText?.toLowerCase() ?? '';
        final subtitle = item.subtitleHighlight?.toLowerCase() ?? '';
        final status = item.statusTag?.toLowerCase() ?? '';
        return title.contains(query) ||
            note.contains(query) ||
            subtitle.contains(query) ||
            status.contains(query);
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final iconBtnBg = isDark
        ? AppDarkColors.surfaceCard
        : AppColors.surfaceGrey;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: CircularBackButton(
              onBack: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        titleSpacing: 8,
        title: Text(
          'Activity',
          style: TextStyle(
            color: isDark ? AppDarkColors.whatsappGreen : AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Input Field & Filter Option Row (Matching Today page)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SearchInputField(
                      controller: _searchController,
                      padding: EdgeInsets.zero,
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _openFilterBottomSheet,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? (isDark
                                    ? AppDarkColors.chipPendingBg
                                    : AppColors.chipPendingBg)
                              : iconBtnBg,
                          borderRadius: BorderRadius.circular(24),
                          border: _hasActiveFilters
                              ? Border.all(
                                  color: isDark
                                      ? AppDarkColors.primaryGreen
                                      : AppColors.brandGreen,
                                  width: 1.5,
                                )
                              : (isDark
                                    ? Border.all(
                                        color: AppDarkColors.border,
                                        width: 1,
                                      )
                                    : null),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 22,
                              color: _hasActiveFilters
                                  ? (isDark
                                        ? AppDarkColors.primaryGreen
                                        : AppColors.brandGreen)
                                  : (isDark
                                        ? AppDarkColors.textSubtitle
                                        : AppColors.textSecondary),
                            ),
                            if (_hasActiveFilters)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Filter Chip Row (if status filter is selected)
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildActiveFilterChip(
                      label: 'Status: $_selectedStatusFilter',
                      isDark: isDark,
                      onDeleted: () {
                        setState(() {
                          _selectedStatusFilter = 'All';
                        });
                      },
                    ),
                  ],
                ),
              ),

            // 2. Horizontal Filter Chips Bar (All, Unread, Pending, Scheduled, Done)
            FilterChipsBar(
              filters: _filters,
              selectedIndex: _selectedFilterIndex,
              onSelected: (index) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
            ),

            const SizedBox(height: 6),

            // 3. Activity List
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No activities found',
                        style: TextStyle(
                          color: AppColors.textSubtitle,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return ActivityItemCard(item: items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
