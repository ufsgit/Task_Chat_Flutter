import 'package:flutter/material.dart';
import '../../api/api.dart';
import '../../core/theme.dart';
import '../../core/widgets/circular_back_button.dart';
import '../../today/widgets/filter_chips_bar.dart';
import '../../today/widgets/search_input_field.dart';
import '../../today/widgets/today_filter_bottom_sheet.dart';
import '../widgets/activity_item_card.dart';
import '../widgets/activity_skeleton_loading.dart';
import 'activity_model.dart';
import 'activity_view_model.dart';
import 'booking_history_page.dart';

/// Activity section / page displaying live activity history from /api/booking-history.
class ActivityView extends StatefulWidget {
  final ActivityViewModel? viewModel;
  final VoidCallback? onBack;
  final bool embedSection;

  const ActivityView({
    super.key,
    this.viewModel,
    this.onBack,
    this.embedSection = false,
  });

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  late final ActivityViewModel _viewModel;
  late final bool _isLocalViewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isLocalViewModel = false;
    } else {
      _viewModel = ActivityViewModel();
      _isLocalViewModel = true;
    }

    // Immediate fetch from backend API
    debugPrint('>>> [ActivityView] initState -> calling fetchHistory() on ${ApiConfig.history_list}');
    _viewModel.fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

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
        selectedStatus: _viewModel.selectedStatusFilter,
        statusOptions: _viewModel.statusOptions,
        onApply: (status) {
          _viewModel.setStatusFilter(status);
        },
        onReset: () {
          _viewModel.setStatusFilter('All');
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

  Widget _buildBody(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final items = _viewModel.filteredActivities;
        final hasActiveFilters = _viewModel.hasActiveFilters;
        final iconBtnBg =
            isDark ? AppDarkColors.surfaceCard : AppColors.surfaceGrey;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Input Field & Filter Option Row
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
                      onChanged: (val) => _viewModel.setSearchQuery(val),
                      onClear: () => _viewModel.setSearchQuery(''),
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
                          color: hasActiveFilters
                              ? (isDark
                                  ? AppDarkColors.chipPendingBg
                                  : AppColors.chipPendingBg)
                              : iconBtnBg,
                          borderRadius: BorderRadius.circular(24),
                          border: hasActiveFilters
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
                              color: hasActiveFilters
                                  ? (isDark
                                      ? AppDarkColors.primaryGreen
                                      : AppColors.brandGreen)
                                  : (isDark
                                      ? AppDarkColors.textSubtitle
                                      : AppColors.textSecondary),
                            ),
                            if (hasActiveFilters)
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

            // Active Filter Chip Row
            if (hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildActiveFilterChip(
                      label: 'Status: ${_viewModel.selectedStatusFilter}',
                      isDark: isDark,
                      onDeleted: () => _viewModel.setStatusFilter('All'),
                    ),
                  ],
                ),
              ),

            // 2. Horizontal Filter Chips Bar ('Today', 'This Week', 'This Month')
            FilterChipsBar(
              filters: _viewModel.filters,
              selectedIndex: _viewModel.selectedFilterIndex,
              onSelected: (index) => _viewModel.setFilterIndex(index),
            ),

            const SizedBox(height: 6),

            // 3. Activity List / Loading / Error / Empty states
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: () => _viewModel.fetchHistory(force: true),
                child: _buildListContent(items, isDark),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListContent(List<ActivityModel> items, bool isDark) {
    if (_viewModel.isLoading && _viewModel.activities.isEmpty) {
      return const ActivitySkeletonLoading();
    }

    if (_viewModel.errorMessage != null && items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: isDark
                        ? AppDarkColors.textSubtitle
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _viewModel.fetchHistory(force: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: isDark
                      ? AppDarkColors.textSubtitle
                      : AppColors.textSubtitle,
                ),
                const SizedBox(height: 12),
                Text(
                  'No activities found',
                  style: TextStyle(
                    color: isDark
                        ? AppDarkColors.textSubtitle
                        : AppColors.textSubtitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pull down to refresh from server',
                  style: TextStyle(
                    color: isDark
                        ? AppDarkColors.textSubtitle
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activityItem = items[index];
        return ActivityItemCard(
          item: activityItem,
          onTap: () {
            debugPrint(
              '>>> [ActivityView] Tapped item: ${activityItem.title} -> opening BookingHistoryPage for this user only',
            );
            // Filter to only include activities belonging to this specific user / booking
            final userOnlyActivities = _viewModel.activities
                .where((act) =>
                    (activityItem.bookingId != null &&
                        act.bookingId == activityItem.bookingId) ||
                    act.title.trim().toLowerCase() ==
                        activityItem.title.trim().toLowerCase())
                .toList();

            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => BookingHistoryPage(
                  initialBooking: activityItem,
                  allActivities: userOnlyActivities.isNotEmpty
                      ? userOnlyActivities
                      : [activityItem],
                  onRefresh: () => _viewModel.fetchHistory(force: true),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    if (widget.embedSection) {
      return _buildBody(context, isDark);
    }

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
        child: _buildBody(context, isDark),
      ),
    );
  }
}
