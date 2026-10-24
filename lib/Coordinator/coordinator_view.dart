import 'package:flutter/material.dart';
import 'package:task_chat/new_booking/add_booking_view.dart';
import '../core/slide_up_route.dart';
import '../core/theme.dart';
import '../core/widgets/fitmate_app_bar_title.dart';
import '../customer_details/customer_details_model.dart';
import '../customer_details/customer_details_view.dart';
import '../today/today_model.dart';
import '../update_status/status_update_result.dart';
import '../today/widgets/chat_list_item_tile.dart';
import '../today/widgets/filter_chips_bar.dart';
import '../today/widgets/search_input_field.dart';
import '../today/widgets/today_skeleton_loading.dart';
import 'coordinator_view_model.dart';
import 'widgets/super_admin_filter_bottom_sheet.dart';

/// Coordinator (formerly Super Admin) screen built with MVVM/MVVC architecture.
/// Displays filtered leads with assigned Branch Manager badges and status filtering.
class CoordinatorView extends StatefulWidget {
  final CoordinatorViewModel? viewModel;

  const CoordinatorView({super.key, this.viewModel});

  @override
  State<CoordinatorView> createState() => _CoordinatorViewState();
}

/// Backward compatibility alias for CoordinatorView.
typedef CoordinatorPage = CoordinatorView;

/// Backward compatibility alias for SuperAdminPage.
typedef SuperAdminPage = CoordinatorView;

class _CoordinatorViewState extends State<CoordinatorView> {
  late final CoordinatorViewModel _viewModel;
  late final bool _internalViewModel;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _internalViewModel = false;
    } else {
      _viewModel = CoordinatorViewModel();
      _internalViewModel = true;
    }
    _viewModel.fetchBookings();
  }

  @override
  void dispose() {
    if (_internalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CoordinatorFilterBottomSheet(
        selectedStatus: _viewModel.selectedStatusFilter,
        selectedBranchManager: _viewModel.selectedManagerFilter,
        statusOptions: _viewModel.statusOptions,
        branchManagerOptions: _viewModel.branchManagerOptions,
        onApply: (status, branchManager) {
          _viewModel.applyFilters(status, branchManager);
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipPendingBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.chipPendingText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.chipPendingText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

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
            padding: const EdgeInsets.only(right: 18.0),
            child: GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  SlideUpRoute(page: const add_booking(isCoordinator: true)),
                );
                if (mounted) {
                  _viewModel.fetchBookings();
                }
              },
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.surfaceGrey,
                ),
                child: const Icon(Icons.add, color: Colors.black87, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field & Filter Option Row (Not rebuilt on list updates)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SearchInputField(
                      controller: _viewModel.searchController,
                      padding: EdgeInsets.zero,
                      onChanged: (val) => _viewModel.onSearchChanged(val),
                      onClear: () => _viewModel.clearSearch(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _openFilterBottomSheet,
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _viewModel.hasActiveFilters
                                ? AppColors.chipPendingBg
                                : AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(24),
                            border: _viewModel.hasActiveFilters
                                ? Border.all(
                                    color: AppColors.brandGreen,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 22,
                                color: _viewModel.hasActiveFilters
                                    ? AppColors.brandGreen
                                    : AppColors.textSecondary,
                              ),
                              if (_viewModel.hasActiveFilters)
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
                  ),
                ],
              ),
            ),

            // Scoped Content Area (Filter badges, tabs, list)
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  final filtered = _viewModel.filteredChatItems;

                  return Column(
                    children: [

                // Active Filter Badges
                if (_viewModel.hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 6.0),
                    child: Row(
                      children: [
                        if (_viewModel.selectedStatusFilter != 'All') ...[
                          _buildActiveFilterChip(
                            label: 'Status: ${_viewModel.selectedStatusFilter}',
                            onDeleted: () => _viewModel.setStatusFilter('All'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_viewModel.selectedManagerFilter != 'All') ...[
                          _buildActiveFilterChip(
                            label: 'Manager: ${_viewModel.selectedManagerFilter}',
                            onDeleted: () => _viewModel.setManagerFilter('All'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _viewModel.resetFilters(),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(
                              color: AppColors.brandGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick Filter Chips Bar (All, Unread, Pending)
                FilterChipsBar(
                  filters: _viewModel.filters,
                  selectedIndex: _viewModel.selectedFilterIndex,
                  onSelected: (index) => _viewModel.setFilterIndex(index),
                ),

                const SizedBox(height: 8),

                // Lead Chat Items List with extra 'Branch Manager' badge & Pull-to-refresh
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
                                      'No tasks found',
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
                                separatorBuilder: (context, index) => const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.divider,
                                  indent: 78,
                                ),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ChatListItemTile(
                                    title: item['title'] ?? '',
                                    avatarLetter: item['avatarLetter'] ?? '',
                                    avatarBgColor:
                                        item['avatarBgColor'] ?? AppColors.surfaceGrey,
                                    avatarTextColor:
                                        item['avatarTextColor'] ??
                                        AppColors.textSecondary,
                                    avatarBorderColor: item['avatarBorderColor'],
                                    hasVerifiedBadge: item['hasVerifiedBadge'] ?? false,
                                    date: item['date'] ?? '',
                                    tagText: item['tagText'] ?? '',
                                    tagBgColor:
                                        item['tagBgColor'] ?? AppColors.completedBg,
                                    tagTextColor:
                                        item['tagTextColor'] ?? AppColors.completedText,
                                    location: item['location'] ?? '',
                                    extraBadgeText:
                                        item['branchManager'] ??
                                        item['role'] ??
                                        'Branch Manager',
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
                                      final updatedStatus = await Navigator.of(context).push(
                                        SlideRightRoute(
                                          page: CustomerDetailsPage(
                                            customer: customer,
                                            isCoordinator: true,
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