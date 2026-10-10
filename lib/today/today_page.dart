import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'today_data.dart';
import 'widgets/chat_list_item_tile.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/search_input_field.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'TaskChat',
          style: TextStyle(
            color: Color(0xFF00A859),
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
                  MaterialPageRoute(
                    builder: (_) => const CreateLeadPage(),
                  ),
                );
              },
              child: CustomPaint(
                painter: DashedCirclePainter(
                  color: const Color(0xFF4C82FB),
                  strokeWidth: 1.2,
                  dashWidth: 4.0,
                  dashSpace: 3.0,
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
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
                            color: Color(0xFF64748B), fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 0.6,
                        color: Color(0xFFF1F5F9),
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ChatListItemTile(
                          title: item['title'] ?? '',
                          avatarLetter: item['avatarLetter'] ?? '',
                          avatarBgColor: item['avatarBgColor'] ??
                              const Color(0xFFF1F5F9),
                          avatarTextColor: item['avatarTextColor'] ??
                              const Color(0xFF334155),
                          avatarBorderColor: item['avatarBorderColor'],
                          hasVerifiedBadge:
                              item['hasVerifiedBadge'] ?? false,
                          indicatorColor: item['indicatorColor'] ??
                              const Color(0xFF22C55E),
                          date: item['date'] ?? '',
                          tagText: item['tagText'] ?? '',
                          tagBgColor: item['tagBgColor'] ??
                              const Color(0xFFDCFCE7),
                          tagTextColor: item['tagTextColor'] ??
                              const Color(0xFF15803D),
                          location: item['location'] ?? '',
                          onTap: () {
                            // Action on tap
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

/// Custom painter for a subtle dashed circular border.
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final totalDashLength = dashWidth + dashSpace;
    final dashCount = (circumference / totalDashLength).floor();
    final adjustedDashAngle = (2 * math.pi) / dashCount;
    final dashAngle = adjustedDashAngle * (dashWidth / totalDashLength);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * adjustedDashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}

