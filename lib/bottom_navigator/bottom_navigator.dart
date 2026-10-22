import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../dashboard/dashboard_page.dart';
import '../report_activity/main/report_activity.dart';
import '../login_page/login_model.dart';
import '../settings/settings_model.dart';
import '../settings/settings_view.dart';
import '../super_admin/super_admin_page.dart';
import '../today/today_view.dart';
import '../today/today_view_model.dart';

/// Backwards-compatible alias for navigation routing.
typedef HomePage = BottomNavigator;

/// Main navigation shell holding the pages and floating bottom navigation bar.
class BottomNavigator extends StatefulWidget {
  final int initialIndex;
  final bool isCoordinator;
  final UserModel? user;
  final TodayViewModel? todayViewModel;

  const BottomNavigator({
    super.key,
    this.initialIndex = 0,
    bool? isCoordinator,
    bool? isSuperAdmin,
    this.user,
    this.todayViewModel,
  }) : isCoordinator = isCoordinator ?? isSuperAdmin ?? false;

  bool get isSuperAdmin => isCoordinator;

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  late int _selectedIndex;
  late final List<Widget> _pages;
  late final TodayViewModel _todayViewModel;
  bool _isLocalTodayViewModel = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (widget.todayViewModel != null) {
      _todayViewModel = widget.todayViewModel!;
      _isLocalTodayViewModel = false;
    } else {
      _todayViewModel = TodayViewModel();
      _isLocalTodayViewModel = true;
    }

    final profile = widget.user != null
        ? UserProfileData.fromUserModel(widget.user!)
        : null;
    _pages = [
      widget.isCoordinator
          ? const CoordinatorPage()
          : TodayPage(viewModel: _todayViewModel),
      DashboardPage(onBack: () => _onItemTapped(0)),
      const ReportActivity(),
      SettingsPage(profile: profile),
    ];
  }

  @override
  void dispose() {
    if (_isLocalTodayViewModel) {
      _todayViewModel.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0 && !widget.isCoordinator) {
      _todayViewModel.fetchBookings();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: currentBgColor,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: FloatingBottomBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: currentBgColor,
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
  final Color? backgroundColor;

  const FloatingBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  State<FloatingBottomBar> createState() => _FloatingBottomBarState();
}

class _FloatingBottomBarState extends State<FloatingBottomBar> {
  int? _hoveredIndex;
  bool _isDragging = false;

  int get _activeDisplayIndex => _isDragging
      ? (_hoveredIndex ?? widget.selectedIndex)
      : widget.selectedIndex;

  void _handleDragUpdate(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0) return;
    final slotWidth = totalWidth / 4;
    final targetIndex = (localPosition.dx / slotWidth)
        .clamp(0.0, 3.999)
        .floor();

    if (targetIndex != _hoveredIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _hoveredIndex = targetIndex;
      });
    }
  }

  void _handleDragEnd() {
    if (!_isDragging) return;
    final selected = _hoveredIndex;
    setState(() {
      _isDragging = false;
      _hoveredIndex = null;
    });
    if (selected != null) {
      HapticFeedback.lightImpact();
      widget.onTap(selected);
    }
  }

  void _handleTapItem(int index) {
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerBg =
        widget.backgroundColor ??
        (isDark ? AppDarkColors.scaffoldBackground : AppColors.surfaceWhite);
    final barBg = isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite;
    final barBorder = isDark ? AppDarkColors.border : AppColors.border;
    final activePillDecoration = isDark
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          )
        : BoxDecoration(
            color: AppColors.completedBg,
            borderRadius: BorderRadius.circular(22),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: outerBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: barBg,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: barBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
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
                  onHorizontalDragEnd: (_) => _handleDragEnd(),
                  onHorizontalDragCancel: _handleDragEnd,
                  onTapUp: (details) {
                    final index = (details.localPosition.dx / slotWidth)
                        .clamp(0.0, 3.999)
                        .floor();
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
                        child: isDark
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: Container(
                                    decoration: activePillDecoration,
                                  ),
                                ),
                              )
                            : Container(decoration: activePillDecoration),
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
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _activeDisplayIndex == index;
    final activeColor = isDark
        ? AppDarkColors.primaryGreen
        : AppColors.primaryGreen;
    final inactiveColor = isDark
        ? AppDarkColors.textSubtitle
        : AppColors.textSubtitle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : activeColor)
                  : inactiveColor,
              letterSpacing: -0.2,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
