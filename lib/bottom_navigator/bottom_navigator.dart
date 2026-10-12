import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../dashboard/dashboard_page.dart';
import '../report_activity/main/report_activity.dart';
import '../settings/settings_page.dart';
import '../super_admin/super_admin_page.dart';
import '../today/today_page.dart';

/// Main navigation shell holding the pages and floating bottom navigation bar.
class BottomNavigator extends StatefulWidget {
  final int initialIndex;
  final bool isSuperAdmin;

  const BottomNavigator({
    super.key,
    this.initialIndex = 0,
    this.isSuperAdmin = false,
  });

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  late int _selectedIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      widget.isSuperAdmin ? const SuperAdminPage() : const TodayPage(),
      DashboardPage(onBack: () => _onItemTapped(0)),
      const ReportActivity(),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: FloatingBottomBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

/// Floating pill bottom navigation bar widget with WhatsApp-style draggable scrubbing.
/// You can drag/slide the active pill across the bar, and when released, whichever page
/// it lands on loads.
class FloatingBottomBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<FloatingBottomBar> createState() => _FloatingBottomBarState();
}

class _FloatingBottomBarState extends State<FloatingBottomBar> {
  int? _hoveredIndex;
  bool _isDragging = false;

  int get _activeDisplayIndex =>
      _isDragging ? (_hoveredIndex ?? widget.selectedIndex) : widget.selectedIndex;

  void _handleDragUpdate(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0) return;
    final slotWidth = totalWidth / 4;
    final targetIndex = (localPosition.dx / slotWidth).clamp(0.0, 3.999).floor();

    if (targetIndex != _hoveredIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _hoveredIndex = targetIndex;
      });
    }
  }

  void _handleDragEnd() {
    if (_isDragging && _hoveredIndex != null) {
      final selected = _hoveredIndex!;
      setState(() {
        _isDragging = false;
        _hoveredIndex = null;
      });
      HapticFeedback.lightImpact();
      widget.onTap(selected);
    } else {
      setState(() {
        _isDragging = false;
        _hoveredIndex = null;
      });
    }
  }

  void _handleTapItem(int index) {
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final slotWidth = totalWidth / 4;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _hoveredIndex = widget.selectedIndex;
                  });
                  _handleDragUpdate(details.localPosition, totalWidth);
                },
                onHorizontalDragUpdate: (details) {
                  _handleDragUpdate(details.localPosition, totalWidth);
                },
                onHorizontalDragEnd: (_) {
                  _handleDragEnd();
                },
                onHorizontalDragCancel: () {
                  _handleDragEnd();
                },
                onTapUp: (details) {
                  final index =
                      (details.localPosition.dx / slotWidth).clamp(0.0, 3.999).floor();
                  _handleTapItem(index);
                },
                child: Stack(
                  children: [
                    // Sliding pill background involving both the icon and the label
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      left: _activeDisplayIndex * slotWidth + 4,
                      top: 4,
                      bottom: 4,
                      width: slotWidth - 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.completedBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),

                    // Items layer: Icon on top, Label underneath
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildNavItem(
                              index: 0,
                              icon: Icons.calendar_today_outlined,
                              label: "Today's",
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildNavItem(
                              index: 1,
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Dashboard',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildNavItem(
                              index: 2,
                              icon: Icons.bar_chart_rounded,
                              label: 'Report',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildNavItem(
                              index: 3,
                              icon: Icons.settings,
                              label: 'Settings',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    String? badgeText,
  }) {
    final isSelected = _activeDisplayIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textSubtitle,
              ),
              if (badgeText != null && !isSelected)
                Positioned(top: -4, right: -6, child: _buildBadge(badgeText)),
            ],
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.textSubtitle,
              letterSpacing: -0.2,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
      decoration: const BoxDecoration(
        color: AppColors.verifiedBadge,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}

