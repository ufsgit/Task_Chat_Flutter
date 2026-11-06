import 'package:flutter/material.dart';
import '../../api/api.dart';
import '../../core/slide_up_route.dart';
import '../../core/theme.dart';
import '../../core/widgets/circular_back_button.dart';
import '../../today/widgets/search_input_field.dart';
import '../widgets/activity_item_card.dart';
import '../widgets/activity_skeleton_loading.dart';
import 'activity_model.dart';
import 'activity_view_model.dart';
import 'booking_history_page.dart';

/// Activity section / page displaying live activity history from /api/booking-history.
class ActivityView extends StatefulWidget {
  final ActivityViewModel? viewModel;
  final VoidCallback? onBack;
  final bool embedSection;

  const ActivityView({
    super.key,
    this.viewModel,
    this.onBack,
    this.embedSection = false,
  });

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  late final ActivityViewModel _viewModel;
  late final bool _isLocalViewModel;
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isLocalViewModel = false;
    } else {
      _viewModel = ActivityViewModel();
      _isLocalViewModel = true;
    }

    // Immediate fetch from backend API
    debugPrint(
      '>>> [ActivityView] initState -> calling fetchHistory() on ${ApiConfig.history_list}',
    );
    _viewModel.fetchHistory();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    final shouldShow = position.pixels > 250;
    if (shouldShow != _showScrollToTop) {
      setState(() {
        _showScrollToTop = shouldShow;
      });
    }

    if (position.pixels <= 0) return;

    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll - currentScroll <= 250 &&
        !_viewModel.isLoading &&
        !_viewModel.isLoadingMore &&
        _viewModel.hasMore) {
      _viewModel.loadNextPage();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildScrollToTopButton(bool isDark) {
    final btnBg = isDark ? AppDarkColors.whatsappGreen : AppColors.primaryGreen;
    final iconColor = isDark ? const Color(0xFF06140D) : Colors.white;

    return AnimatedScale(
      key: const Key('activity_scroll_to_top_button'),
      scale: _showScrollToTop ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _showScrollToTop ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_showScrollToTop,
          child: Tooltip(
            message: 'Scroll to top',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _scrollToTop,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: btnBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.18,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final items = _viewModel.filteredActivities;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Input Field (Full Width)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SearchInputField(
                    controller: _searchController,
                    padding: EdgeInsets.zero,
                    onChanged: (val) {
                      _viewModel.setSearchQuery(val);
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0.0);
                      }
                    },
                    onClear: () {
                      _viewModel.setSearchQuery('');
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0.0);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 4),

                // 2. Activity List / Loading / Error / Empty states
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => _viewModel.fetchHistory(force: true),
                    child: _buildListContent(items, isDark),
                  ),
                ),
              ],
            ),
            // Floating pop up scroll to top button
            Positioned(
              right: 18,
              bottom: 20,
              child: _buildScrollToTopButton(isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListContent(List<ActivityModel> items, bool isDark) {
    if (_viewModel.isLoading && _viewModel.activities.isEmpty) {
      return const ActivitySkeletonLoading();
    }

    if (_viewModel.errorMessage != null && items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: isDark
                        ? AppDarkColors.textSubtitle
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _viewModel.fetchHistory(force: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: isDark
                      ? AppDarkColors.textSubtitle
                      : AppColors.textSubtitle,
                ),
                const SizedBox(height: 12),
                Text(
                  'No activities found',
                  style: TextStyle(
                    color: isDark
                        ? AppDarkColors.textSubtitle
                        : AppColors.textSubtitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pull down to refresh from server',
                  style: TextStyle(
                    color: isDark
                        ? AppDarkColors.textSubtitle
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + (_viewModel.isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      separatorBuilder: (context, index) {
        if (index >= items.length - 1 && _viewModel.isLoadingMore) {
          return const SizedBox.shrink();
        }
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
          );
        }

        if (index >= items.length - 2 &&
            !_viewModel.isLoading &&
            !_viewModel.isLoadingMore &&
            _viewModel.hasMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                !_viewModel.isLoading &&
                !_viewModel.isLoadingMore &&
                _viewModel.hasMore) {
              _viewModel.loadNextPage();
            }
          });
        }

        final activityItem = items[index];
        return ActivityItemCard(
          item: activityItem,
          onTap: () {
            debugPrint(
              '>>> [ActivityView] Tapped item: ${activityItem.title} -> opening BookingHistoryPage for this user only',
            );
            // Filter to only include activities belonging to this specific user / booking
            final userOnlyActivities = _viewModel.activities
                .where(
                  (act) =>
                      (activityItem.bookingId != null &&
                          act.bookingId == activityItem.bookingId) ||
                      act.title.trim().toLowerCase() ==
                          activityItem.title.trim().toLowerCase(),
                )
                .toList();

            Navigator.of(context, rootNavigator: true).push(
              SlideRightRoute(
                page: BookingHistoryPage(
                  initialBooking: activityItem,
                  allActivities: userOnlyActivities.isNotEmpty
                      ? userOnlyActivities
                      : [activityItem],
                  onRefresh: () => _viewModel.fetchHistory(force: true),
                  viewModel: _viewModel,
                  client: _viewModel.client,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    if (widget.embedSection) {
      return _buildBody(context, isDark);
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: CircularBackButton(
              onBack: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        titleSpacing: 8,
        title: Text(
          'Activity',
          style: TextStyle(
            color: isDark ? AppDarkColors.whatsappGreen : AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context, isDark)),
    );
  }
}
