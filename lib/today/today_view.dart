import 'package:flutter/material.dart';
import 'package:task_chat/new_booking/add_booking_view.dart';
import '../core/theme.dart';
import 'today_model.dart';
import 'today_view_model.dart';
import 'widgets/chat_list_item_tile.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/search_input_field.dart';
import 'widgets/today_filter_bottom_sheet.dart';
import 'widgets/today_skeleton_loading.dart';
import '../core/slide_up_route.dart';
import '../core/widgets/fitmate_app_bar_title.dart';
import '../customer_details/customer_details_model.dart';
import '../customer_details/customer_details_view.dart';
import '../notification_page/notification_page.dart';
import '../update_status/status_update_result.dart';

class TodayPage extends StatefulWidget {
  final TodayViewModel? viewModel;

  const TodayPage({super.key, this.viewModel});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late final TodayViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const ['All', 'Unread', 'Pending'];
  final List<String> _statusOptions = const [
    'All',
    'New',
    'Scheduled',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? TodayViewModel();
    _viewModel.fetchBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.viewModel == null) {
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
        statusOptions: _statusOptions,
        selectedDateFrom: _viewModel.dateFrom,
        selectedDateTo: _viewModel.dateTo,
        onApply: (status) {
          _viewModel.setStatusFilter(status);
        },
        onApplyAdvanced: ({
          required String status,
          String? districtId,
          String? dateFrom,
          String? dateTo,
          String? filterRole,
        }) {
          _viewModel.applyFilters(
            status: status,
            dateFrom: dateFrom,
            dateTo: dateTo,
          );
        },
        onReset: () {
          _viewModel.resetFilters();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : Colors.black87;
    final iconBtnBg = isDark
        ? AppDarkColors.surfaceGrey
        : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        toolbarHeight: 68,
        title: const FitmateAppBarTitle(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await Navigator.of(context, rootNavigator: true)
                          .push(SlideUpRoute(page: const add_booking(isCoordinator: false)));
                      if (mounted) {
                        _viewModel.fetchBookings();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBtnBg,
                        borderRadius: BorderRadius.circular(20),
                        border: isDark
                            ? Border.all(color: AppDarkColors.border, width: 1)
                            : null,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: primaryTextColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await Navigator.of(context).push(
                      SlideUpRoute(
                        page: const NotificationPage(showBottomBar: false),
                      ),
                    );
                    if (mounted) {
                      _viewModel.fetchBookings();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBtnBg,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark
                          ? Border.all(color: AppDarkColors.border, width: 1)
                          : null,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: primaryTextColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Field & Filter Option Row
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
                      onClear: () =>
                          _viewModel.setSearchQuery('', immediate: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      final hasActiveFilters = _viewModel.hasActiveFilters;
                      return Material(
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
                      );
                    },
                  ),
                ],
              ),
            ),

            // Content Area (Active Filters, Chips Bar, and List) scoped with ListenableBuilder
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  final filtered = _viewModel.filteredChatItems;
                  final hasActiveFilters = _viewModel.hasActiveFilters;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasActiveFilters)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 6.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_viewModel.selectedStatusFilter != 'All') ...[
                                  _buildActiveFilterChip(
                                    label:
                                        'Status: ${_viewModel.selectedStatusFilter}',
                                    isDark: isDark,
                                    onDeleted: () {
                                      _viewModel.setStatusFilter('All');
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if ((_viewModel.dateFrom != null &&
                                        _viewModel.dateFrom!.isNotEmpty) ||
                                    (_viewModel.dateTo != null &&
                                        _viewModel.dateTo!.isNotEmpty)) ...[
                                  _buildActiveFilterChip(
                                    label:
                                        'Date: ${formatDateToDayMonthYear(_viewModel.dateFrom)} - ${formatDateToDayMonthYear(_viewModel.dateTo)}',
                                    isDark: isDark,
                                    onDeleted: () {
                                      _viewModel.setDateRange(
                                          from: null, to: null);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                _buildActiveFilterChip(
                                  label: 'Clear All',
                                  isDark: isDark,
                                  onDeleted: () {
                                    _viewModel.resetFilters();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Reusable Horizontal Filter Chips Bar
                      FilterChipsBar(
                        filters: _filters,
                        selectedIndex: _viewModel.selectedFilterIndex,
                        onSelected: (index) {
                          _viewModel.setFilterIndex(index);
                        },
                      ),

                      const SizedBox(height: 4),

                      // Leads / Task List with Pull-to-refresh
                      Expanded(
                        child: RefreshIndicator(
                    onRefresh: _viewModel.fetchBookings,
                    color: AppColors.primaryGreen,
                    child: _viewModel.isLoading && filtered.isEmpty
                        ? const TodaySkeletonLoading()
                        : filtered.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'No tasks or leads found',
                                      style: TextStyle(
                                        color: AppColors.textSubtitle,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Container(
                                    height: 1.0,
                                    color: isDark
                                        ? AppDarkColors.divider
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ChatListItemTile(
                                    title: item['title'] ?? '',
                                    avatarLetter: item['avatarLetter'] ?? '',
                                    avatarBgColor: item['avatarBgColor'] ??
                                        AppColors.surfaceGrey,
                                    avatarTextColor: item['avatarTextColor'] ??
                                        AppColors.textSecondary,
                                    avatarBorderColor:
                                        item['avatarBorderColor'],
                                    hasVerifiedBadge:
                                        item['hasVerifiedBadge'] ?? false,
                                    date: formatDateToDayMonthYear(
                                        item['date']?.toString() ?? ''),
                                    tagText: item['tagText'] ?? '',
                                    tagBgColor: item['tagBgColor'] ??
                                        AppColors.completedBg,
                                    tagTextColor: item['tagTextColor'] ??
                                        AppColors.completedText,
                                    location: item['location'] ?? '',
                                    onTap: () async {
                                      final booking = item['booking'] as BookingModel?;
                                      final customer = booking != null
                                          ? CustomerDetailsData(
                                              id: booking.id.toString(),
                                              name: booking.name,
                                              inquiry: booking.notes.isNotEmpty
                                                  ? booking.notes
                                                  : 'Steel door enquiry',
                                              status: booking.status.isNotEmpty
                                                  ? '${booking.status[0].toUpperCase()}${booking.status.substring(1).toLowerCase()}'
                                                  : 'New',
                                              phoneNumber: booking.mobile,
                                              addressLine1: booking.address,
                                              addressLine2: [
                                                booking.areaName,
                                                booking.districtName,
                                                booking.stateName,
                                              ]
                                                  .where((s) => s.isNotEmpty)
                                                  .join(', '),
                                              notes: booking.notes,
                                              documents: booking.documents,
                                              hasBeenScheduled: booking.status
                                                          .toLowerCase() ==
                                                      'scheduled' ||
                                                  booking.status
                                                          .toLowerCase() ==
                                                      'completed',
                                              branchHeadId: booking.branchHeadId,
                                              branchHeadName: booking.branchHeadName ??
                                                  item['branchManager']?.toString(),
                                              scheduleDate: booking.scheduleDate,
                                            )
                                          : CustomerDetailsData.fromChatInfo(
                                              name: item['title']?.toString() ??
                                                  'Customer',
                                              location: item['location']
                                                  ?.toString(),
                                              tagText: item['tagText']
                                                  ?.toString(),
                                              id: item['id']?.toString(),
                                              scheduleDate: item['scheduleDate']?.toString() ??
                                                  item['date']?.toString(),
                                              phoneNumber: item['mobile']?.toString() ??
                                                  item['phoneNumber']?.toString(),
                                              notes: item['notes']?.toString(),
                                              documents: item['documents'] is List
                                                  ? (item['documents'] as List)
                                                      .map((e) => e.toString())
                                                      .toList()
                                                  : null,
                                              branchHeadId: item['branchHeadId'] is int
                                                  ? item['branchHeadId'] as int
                                                  : null,
                                              branchHeadName: item['branchManager']?.toString() ??
                                                  item['branchHeadName']?.toString(),
                                            );

                                      final updatedStatus =
                                          await Navigator.of(context).push(
                                        SlideRightRoute(
                                          page: CustomerDetailsPage(
                                            customer: customer,
                                          ),
                                        ),
                                      );

                                      if (mounted) {
                                        if (updatedStatus is StatusUpdateResult) {
                                          _viewModel.updateStatus(
                                            item['title'] ?? '',
                                            updatedStatus.status,
                                            newDate: updatedStatus.scheduleDate,
                                          );
                                        } else if (updatedStatus is String) {
                                          _viewModel.updateStatus(
                                            item['title'] ?? '',
                                            updatedStatus,
                                          );
                                        }
                                        _viewModel.fetchBookings();
                                      }
                                    },
                                  );
                                },
                              ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  ),
),
);
}
}

/// Backward compatibility / MVVM alias for TodayPage.
typedef TodayView = TodayPage;