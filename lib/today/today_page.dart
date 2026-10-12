import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'today_data.dart';
import 'widgets/chat_list_item_tile.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/search_input_field.dart';
import '../core/slide_up_route.dart';
import '../customer_details/customer_details_data.dart';
import '../customer_details/customer_details_page.dart';
import '../new_lead/create_lead_page.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  int _selectedFilterIndex = 2; // Default to 'Pending' as shown in redesign
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const ['All', 'Unread', 'Pending'];

  List<Map<String, dynamic>> get _filteredChatItems {
    final query = _searchController.text.trim().toLowerCase();
    return todayChatItems.where((item) {
      final unreadCount = (item['unreadCount'] as int?) ?? 0;
      final title = (item['title'] as String?)?.toLowerCase() ?? '';
      final tagText = (item['tagText'] as String?)?.toLowerCase() ?? '';
      final location = (item['location'] as String?)?.toLowerCase() ?? '';
      final date = (item['date'] as String?)?.toLowerCase() ?? '';
      final isPending = (item['isPending'] as bool?) ?? true;

      if (_selectedFilterIndex == 1 && unreadCount == 0) {
        return false;
      }
      if (_selectedFilterIndex == 2 && !isPending) {
        return false;
      }
      if (query.isNotEmpty) {
        return title.contains(query) ||
            tagText.contains(query) ||
            location.contains(query) ||
            date.contains(query);
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
    final filtered = _filteredChatItems;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'TaskChat',
          style: TextStyle(
            color: AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  SlideUpRoute(page: const CreateLeadPage()),
                );
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
            // Reusable Search Input Field
            SearchInputField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onClear: () => setState(() {}),
            ),

            // Reusable Horizontal Filter Chips Bar
            FilterChipsBar(
              filters: _filters,
              selectedIndex: _selectedFilterIndex,
              onSelected: (index) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
            ),

            const SizedBox(height: 4),

            // Leads / Task List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks or leads found',
                        style: TextStyle(
                          color: AppColors.textSubtitle,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 0.6,
                        color: AppColors.divider,
                        indent: 16,
                        endIndent: 16,
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
                          indicatorColor:
                              item['indicatorColor'] ??
                              (item['tagText']?.toString().toLowerCase() ==
                                      'new'
                                  ? const Color(0xFFEF4444)
                                  : Colors.transparent),
                          date: item['date'] ?? '',
                          tagText: item['tagText'] ?? '',
                          tagBgColor:
                              item['tagBgColor'] ?? AppColors.completedBg,
                          tagTextColor:
                              item['tagTextColor'] ?? AppColors.completedText,
                          location: item['location'] ?? '',
                          onTap: () async {
                            final customer = CustomerDetailsData.fromChatInfo(
                              name: item['title']?.toString() ?? 'Customer',
                              location: item['location']?.toString(),
                              tagText: item['tagText']?.toString(),
                              id: item['id']?.toString(),
                            );
                            await Navigator.of(context).push(
                              SlideUpRoute(
                                page: CustomerDetailsPage(customer: customer),
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
