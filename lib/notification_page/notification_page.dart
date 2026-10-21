import 'package:flutter/material.dart';
import '../bottom_navigator/bottom_navigator.dart';
import '../core/circular_back_button.dart';
import '../core/theme.dart';
import '../customer_details/customer_details_model.dart';
import '../customer_details/customer_details_view.dart';
import 'notification_data.dart';
import 'widgets/notification_filter_chips.dart';
import 'widgets/notification_item_tile.dart';
import 'widgets/notification_section_header.dart';

/// Notifications screen reproducing the design faithfully in both Light and WhatsApp Dark mode.
class NotificationPage extends StatefulWidget {
  final bool showBottomBar;

  const NotificationPage({
    super.key,
    this.showBottomBar = true,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  NotificationFilter _selectedFilter = NotificationFilter.all;

  void _handleItemTap(NotificationItem item) {
    // Open CustomerDetailsPage with matching customer data
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailsPage(
          customer: CustomerDetailsData.fromChatInfo(
            name: item.name,
            location: item.location,
            tagText: item.tag,
            id: item.id,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryTextColor =
        isDark ? AppDarkColors.textPrimary : const Color(0xFF0F172A);

    final filteredSections = filterNotificationSections(
      defaultNotificationSections,
      _selectedFilter,
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: CircularBackButton(
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            letterSpacing: -0.3,
          ),
        ),
        titleSpacing: 12,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills: "All" and "Pending"
            NotificationFilterChips(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),

            const SizedBox(height: 4),

            // Notification Sections List
            Expanded(
              child: filteredSections.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications found',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppDarkColors.textSubtitle
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredSections.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = filteredSections[sectionIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Banner: TODAY, THIS WEEK, EARLIER
                            NotificationSectionHeader(title: section.title),

                            // Items in this section
                            ...section.items.map(
                              (item) => NotificationItemTile(
                                item: item,
                                onTap: () => _handleItemTap(item),
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
      bottomNavigationBar: widget.showBottomBar
          ? FloatingBottomBar(
              selectedIndex: 0,
              onTap: (index) {
                Navigator.of(context).pop(index);
              },
              backgroundColor: scaffoldBg,
            )
          : null,
    );
  }
}
