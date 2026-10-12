import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'activity_data.dart';
import 'widgets/activity_filter_chips_bar.dart';
import 'widgets/activity_item_card.dart';
import 'widgets/activity_search_bar.dart';

/// Activity history screen matching the reference design.
/// Keeps data decoupled in `activity_data.dart` and UI reusable in `widgets/`.
class ActivityPage extends StatefulWidget {
  final VoidCallback? onBack;

  const ActivityPage({super.key, this.onBack});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  String _selectedFilter = 'Today';
  final TextEditingController _searchController = TextEditingController();

  List<ActivityItemData> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return defaultActivityItems.where((item) {
      if (item.timeFilter != _selectedFilter && _selectedFilter != 'Today') {
        // Allow fallback or matching on timeFilter
        return false;
      }
      if (query.isNotEmpty) {
        final title = item.title.toLowerCase();
        final note = item.noteText?.toLowerCase() ?? '';
        final subtitle = item.subtitleHighlight?.toLowerCase() ?? '';
        return title.contains(query) ||
            note.contains(query) ||
            subtitle.contains(query);
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

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.brandGreen,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 8,
        title: const Text(
          'TaskChat',
          style: TextStyle(
            color: AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // 1. Search Bar
              ActivitySearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              ),
              const SizedBox(height: 14),

              // 2. Filter Chips Bar (Today, This Week, This Month)
              ActivityFilterChipsBar(
                filters: activityTimeFilters,
                selectedFilter: _selectedFilter,
                onSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 16),

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
                        padding: const EdgeInsets.only(bottom: 80),
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
      ),
    );
  }
}
