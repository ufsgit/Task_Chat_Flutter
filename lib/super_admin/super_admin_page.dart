import 'package:flutter/material.dart';
import 'package:task_chat/new_booking/add_booking_view.dart';
import '../core/slide_up_route.dart';
import '../core/theme.dart';
import '../core/widgets/fitmate_app_bar_title.dart';
import '../customer_details/customer_details_model.dart';
import '../customer_details/customer_details_view.dart';
import '../today/widgets/chat_list_item_tile.dart';
import '../today/widgets/filter_chips_bar.dart';
import '../today/widgets/search_input_field.dart';
import '../update_status/update_status_data.dart';
import 'super_admin_data.dart';
import 'widgets/super_admin_filter_bottom_sheet.dart';

/// Coordinator (formerly Super Admin) screen matching the design.
/// Reuses existing widgets (`SearchInputField`, `FilterChipsBar`, `ChatListItemTile`),
/// keeps data separated in `super_admin_data.dart`, and displays the extra `Branch Manager` role badge.
class CoordinatorPage extends StatefulWidget {
  const CoordinatorPage({super.key});

  @override
  State<CoordinatorPage> createState() => _CoordinatorPageState();
}

/// Backward compatibility alias for CoordinatorPage.
typedef SuperAdminPage = CoordinatorPage;

class _CoordinatorPageState extends State<CoordinatorPage> {
  int _selectedFilterIndex =
      2; // Default to 'Pending' as shown in the screenshot
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const ['All', 'Unread', 'Pending'];
  String _selectedStatusFilter = 'All';
  String _selectedManagerFilter = 'All';

  final List<String> _statusOptions = const [
    'All',
    'New',
    'Scheduled',
    'Completed',
    'Cancelled',
  ];

  List<String> get _branchManagerOptions => ['All', ...availableBranchManagers];

  bool get _hasActiveFilters =>
      _selectedStatusFilter != 'All' || _selectedManagerFilter != 'All';

  List<Map<String, dynamic>> get _filteredChatItems {
    final query = _searchController.text.trim().toLowerCase();
    return coordinatorChatItems.where((item) {
      final unreadCount = (item['unreadCount'] as int?) ?? 0;
      final title = (item['title'] as String?)?.toLowerCase() ?? '';
      final tagText = (item['tagText'] as String?)?.toLowerCase() ?? '';
      final location = (item['location'] as String?)?.toLowerCase() ?? '';
      final date = (item['date'] as String?)?.toLowerCase() ?? '';
      final isPending = (item['isPending'] as bool?) ?? true;
      final branchManager =
          (item['branchManager'] as String?)?.toLowerCase() ?? '';

      if (_selectedFilterIndex == 1 && unreadCount == 0) {
        return false;
      }
      if (_selectedFilterIndex == 2 && !isPending) {
        return false;
      }
      if (_selectedStatusFilter != 'All' &&
          tagText != _selectedStatusFilter.toLowerCase()) {
        return false;
      }
      if (_selectedManagerFilter != 'All' &&
          branchManager != _selectedManagerFilter.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        return title.contains(query) ||
            tagText.contains(query) ||
            location.contains(query) ||
            date.contains(query) ||
            branchManager.contains(query);
      }
      return true;
    }).toList();
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
        selectedStatus: _selectedStatusFilter,
        selectedBranchManager: _selectedManagerFilter,
        statusOptions: _statusOptions,
        branchManagerOptions: _branchManagerOptions,
        onApply: (status, branchManager) {
          setState(() {
            _selectedStatusFilter = status;
            _selectedManagerFilter = branchManager;
          });
        },
        onReset: () {
          setState(() {
            _selectedStatusFilter = 'All';
            _selectedManagerFilter = 'All';
          });
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredChatItems;
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
              onTap: () {
                Navigator.of(
                  context,
                ).push(SlideUpRoute(page: const add_booking()));
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
                              ? AppColors.chipPendingBg
                              : AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(24),
                          border: _hasActiveFilters
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
                              color: _hasActiveFilters
                                  ? AppColors.brandGreen
                                  : AppColors.textSecondary,
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

            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 6.0),
                child: Row(
                  children: [
                    if (_selectedStatusFilter != 'All') ...[
                      _buildActiveFilterChip(
                        label: 'Status: $_selectedStatusFilter',
                        onDeleted: () {
                          setState(() {
                            _selectedStatusFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_selectedManagerFilter != 'All') ...[
                      _buildActiveFilterChip(
                        label: 'Manager: $_selectedManagerFilter',
                        onDeleted: () {
                          setState(() {
                            _selectedManagerFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStatusFilter = 'All';
                          _selectedManagerFilter = 'All';
                        });
                      },
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

            // Filter Chips Bar (All, Unread, Pending)
            FilterChipsBar(
              filters: _filters,
              selectedIndex: _selectedFilterIndex,
              onSelected: (index) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
            ),

            const SizedBox(height: 8),

            // Lead Chat Items List with extra 'Branch Manager' badge
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks found',
                        style: TextStyle(
                          color: AppColors.textSubtitle,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
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
                            final customer = CustomerDetailsData.fromChatInfo(
                              name: item['title']?.toString() ?? 'Customer',
                              location: item['location']?.toString(),
                              tagText: item['tagText']?.toString(),
                              id: item['id']?.toString(),
                            );
                            await Navigator.of(context).push(
                              SlideUpRoute(
                                page: CustomerDetailsPage(
                                  customer: customer,
                                  isCoordinator: true,
                                ),
                              ),
                            );
                            if (mounted) {
                              setState(() {});
                            }
                          },
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
