import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable Branch Manager dropdown selection card for Super Admin.
class BranchManagerFieldCard extends StatefulWidget {
  final String selectedManager;
  final ValueChanged<String> onManagerChanged;
  final List<String>? managers;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final EdgeInsetsGeometry? padding;

  const BranchManagerFieldCard({
    super.key,
    required this.selectedManager,
    required this.onManagerChanged,
    this.managers,
    this.isLoading = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.padding,
  });

  @override
  State<BranchManagerFieldCard> createState() => _BranchManagerFieldCardState();
}

class _MenuData {
  final List<String> managers;
  final bool hasMore;
  final bool isLoadingMore;
  final String selectedManager;

  const _MenuData({
    required this.managers,
    required this.hasMore,
    required this.isLoadingMore,
    required this.selectedManager,
  });
}

class _BranchManagerFieldCardState extends State<BranchManagerFieldCard> {
  late final ValueNotifier<_MenuData> _menuDataNotifier;

  @override
  void initState() {
    super.initState();
    _menuDataNotifier = ValueNotifier<_MenuData>(
      _MenuData(
        managers: widget.managers ?? const [],
        hasMore: widget.hasMore,
        isLoadingMore: widget.isLoadingMore,
        selectedManager: widget.selectedManager,
      ),
    );
  }

  @override
  void didUpdateWidget(BranchManagerFieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _menuDataNotifier.value = _MenuData(
          managers: widget.managers ?? const [],
          hasMore: widget.hasMore,
          isLoadingMore: widget.isLoadingMore,
          selectedManager: widget.selectedManager,
        );
      }
    });
  }

  @override
  void dispose() {
    _menuDataNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branch Manager',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final list = (widget.managers != null && widget.managers!.isNotEmpty)
                ? widget.managers!
                : const <String>[];
            final hasSelection =
                list.isNotEmpty && widget.selectedManager.isNotEmpty;
            final displayText = list.isEmpty
                ? 'No branch managers available'
                : (widget.selectedManager.isNotEmpty
                    ? widget.selectedManager
                    : 'Select Branch Manager');

            return Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: isDark
                      ? AppDarkColors.surfaceCard
                      : AppColors.dropdownBackground,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppDarkColors.border : AppColors.border,
                      width: 1,
                    ),
                  ),
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                ),
              ),
              child: PopupMenuButton<String>(
                enabled: !widget.isLoading,
                position: PopupMenuPosition.under,
                offset: const Offset(0, 8),
                constraints: BoxConstraints(
                  minWidth: cardWidth,
                  maxWidth: cardWidth,
                  maxHeight: 280,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Select Branch Manager',
                onSelected: (val) {
                  widget.onManagerChanged(val);
                },
                itemBuilder: (context) {
                  return [
                    _DynamicBranchManagerMenuEntry(
                      menuDataNotifier: _menuDataNotifier,
                      onSelected: (val) {
                        Navigator.of(context).pop();
                        widget.onManagerChanged(val);
                      },
                      onLoadMore: widget.onLoadMore,
                    ),
                  ];
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDarkColors.surfaceCard
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppDarkColors.border : AppColors.border,
                      width: 1,
                    ),
                  ),
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppDarkColors.pillActiveBg
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: isDark
                              ? AppDarkColors.whatsappGreen
                              : AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BRANCH MANAGER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppDarkColors.textSubtitle
                                    : AppColors.textSubtitle,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: hasSelection
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: hasSelection
                                    ? (isDark
                                        ? AppDarkColors.textPrimary
                                        : AppColors.textPrimary)
                                    : (isDark
                                        ? AppDarkColors.textSubtitle
                                        : AppColors.textSubtitle),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        )
                      else
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? AppDarkColors.textSubtitle
                              : AppColors.textSubtitle,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Dynamic popup menu entry that listens to the popup menu's scroll position
/// and automatically updates its list and triggers [onLoadMore] on scroll.
class _DynamicBranchManagerMenuEntry extends PopupMenuEntry<String> {
  final ValueNotifier<_MenuData> menuDataNotifier;
  final ValueChanged<String> onSelected;
  final VoidCallback? onLoadMore;

  const _DynamicBranchManagerMenuEntry({
    required this.menuDataNotifier,
    required this.onSelected,
    this.onLoadMore,
  });

  @override
  double get height => 48.0;

  @override
  bool represents(String? value) => false;

  @override
  State<_DynamicBranchManagerMenuEntry> createState() =>
      _DynamicBranchManagerMenuEntryState();
}

class _DynamicBranchManagerMenuEntryState
    extends State<_DynamicBranchManagerMenuEntry> {
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachScrollListener();
    });
  }

  void _attachScrollListener() {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && scrollable.position != _scrollPosition) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = scrollable.position;
      _scrollPosition?.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final pos = _scrollPosition;
    if (pos == null) return;
    // When user scrolls within 180 pixels of the bottom, trigger onLoadMore automatically
    if (pos.pixels >= pos.maxScrollExtent - 180) {
      final data = widget.menuDataNotifier.value;
      if (data.hasMore && !data.isLoadingMore) {
        widget.onLoadMore?.call();
      }
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<_MenuData>(
      valueListenable: widget.menuDataNotifier,
      builder: (context, data, _) {
        final list = data.managers;

        if (list.isEmpty) {
          return const SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'No branch managers available',
                  style: TextStyle(fontSize: 13.5),
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final name in list)
              _buildItem(
                context: context,
                name: name,
                isSelected: name == data.selectedManager,
                isDark: isDark,
              ),
            if (data.hasMore || data.isLoadingMore)
              _buildLoader(isDark: isDark, isLoading: data.isLoadingMore),
          ],
        );
      },
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required String name,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => widget.onSelected(name),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark
                            ? AppDarkColors.whatsappGreen
                            : AppColors.primaryGreen)
                      : (isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimary),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 18,
                color: isDark
                    ? AppDarkColors.whatsappGreen
                    : AppColors.primaryGreen,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader({required bool isDark, required bool isLoading}) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            )
          : InkWell(
              onTap: widget.onLoadMore,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: isDark
                          ? AppDarkColors.whatsappGreen
                          : AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Load more...',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppDarkColors.whatsappGreen
                            : AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
