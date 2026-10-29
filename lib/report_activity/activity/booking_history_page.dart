import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'activity_model.dart';

/// Model representing an individual change diff within a timeline event.
class TimelineDiffField {
  final String label;
  final String oldValue;
  final String newValue;
  final bool multiline;

  const TimelineDiffField({
    required this.label,
    required this.oldValue,
    required this.newValue,
    this.multiline = false,
  });
}

/// Model representing a single point in the booking history timeline.
class TimelineHistoryEvent {
  final String actionTitle;
  final String time;
  final String date;
  final String actor;
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeTextColor;
  final bool isCurrent;
  final Color dotColor;
  final List<TimelineDiffField> diffs;

  const TimelineHistoryEvent({
    required this.actionTitle,
    required this.time,
    required this.date,
    required this.actor,
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeTextColor,
    this.isCurrent = false,
    required this.dotColor,
    this.diffs = const [],
  });
}

/// Data class grouping multiple timeline events under a single booking.
class BookingHistoryGroup {
  final String bookingId;
  final String bookingName;
  final String date;
  final String status;
  final Color statusBg;
  final Color statusTextColor;
  final List<TimelineHistoryEvent> events;

  const BookingHistoryGroup({
    required this.bookingId,
    required this.bookingName,
    required this.date,
    required this.status,
    required this.statusBg,
    required this.statusTextColor,
    required this.events,
  });
}

/// Full History Timeline Page demonstrating changes in:
/// - Status
/// - Notes
/// - Branch Head
/// - Schedule Date
class BookingHistoryPage extends StatefulWidget {
  final ActivityModel initialBooking;
  final List<ActivityModel> allActivities;
  final Future<void> Function()? onRefresh;

  const BookingHistoryPage({
    super.key,
    required this.initialBooking,
    this.allActivities = const [],
    this.onRefresh,
  });

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  // Track which booking accordion cards are expanded
  final Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // Expand initial booking by default
    final initialKey = _getGroupKey(widget.initialBooking);
    _expandedGroups[initialKey] = true;
  }

  String _getGroupKey(ActivityModel item) {
    if (item.bookingId != null) return 'group_${item.bookingId}';
    if (item.id.isNotEmpty) return 'group_${item.id}';
    return 'group_${item.title}';
  }

  /// Builds timeline events demonstrating lifecycle changes
  /// in status, notes, branch head, and schedule date.
  List<TimelineHistoryEvent> _buildTimelineEventsForBooking(
    ActivityModel booking,
  ) {
    final actor =
        (booking.actionByName != null &&
            booking.actionByName!.trim().isNotEmpty)
        ? booking.actionByName!.trim()
        : (booking.subtitleHighlight ?? 'SteelGuard Executive Board');

    final displayDate = booking.date.isNotEmpty ? booking.date : '29/10/2026';
    final notesText =
        (booking.notes != null && booking.notes!.trim().isNotEmpty)
        ? booking.notes!.trim()
        : 'Call 30 min before arriving, use the side gate';

    final branchHeadText =
        (booking.subtitleHighlight != null &&
            booking.subtitleHighlight!.isNotEmpty)
        ? booking.subtitleHighlight!
        : (booking.location != null
              ? 'Anas Kabeer (${booking.location})'
              : 'Anas Kabeer (Kozhikode)');

    return [
      // 1. Completed (Current)
      TimelineHistoryEvent(
        actionTitle: 'Booking Completed',
        time: '5:35 PM',
        date: displayDate,
        actor: actor,
        badgeLabel: 'Completed',
        badgeBg: const Color(0xFFDCFCE7),
        badgeTextColor: const Color(0xFF15803D),
        isCurrent: true,
        dotColor: const Color(0xFF22C55E),
        diffs: const [
          TimelineDiffField(
            label: 'STATUS',
            oldValue: 'Scheduled',
            newValue: 'Completed',
          ),
        ],
      ),

      // 2. Rescheduled (Demonstrates Schedule Date change)
      TimelineHistoryEvent(
        actionTitle: 'Booking Rescheduled',
        time: '5:20 PM',
        date: displayDate,
        actor: actor,
        badgeLabel: 'Edited',
        badgeBg: const Color(0xFFF1F5F9),
        badgeTextColor: const Color(0xFF475569),
        dotColor: const Color(0xFF64748B),
        diffs: const [
          TimelineDiffField(
            label: 'SCHEDULED DATE',
            oldValue: '30/10/2026',
            newValue: '02/11/2026',
          ),
        ],
      ),

      // 3. Details Updated (Demonstrates Name & Notes changes)
      TimelineHistoryEvent(
        actionTitle: 'Details Updated',
        time: '5:05 PM',
        date: displayDate,
        actor: actor,
        badgeLabel: 'Edited',
        badgeBg: const Color(0xFFF1F5F9),
        badgeTextColor: const Color(0xFF475569),
        dotColor: const Color(0xFF64748B),
        diffs: [
          TimelineDiffField(
            label: 'NAME',
            oldValue: booking.title.length > 3
                ? booking.title.substring(0, booking.title.length - 1)
                : 'tes',
            newValue: booking.title,
          ),
          TimelineDiffField(
            label: 'NOTES',
            oldValue: 'Call before arriving',
            newValue: notesText,
            multiline: true,
          ),
        ],
      ),

      // 4. Scheduled (Demonstrates Status & Branch Head changes)
      TimelineHistoryEvent(
        actionTitle: 'Booking Scheduled',
        time: '4:50 PM',
        date: displayDate,
        actor: actor,
        badgeLabel: 'Scheduled',
        badgeBg: const Color(0xFFFEF3C7),
        badgeTextColor: const Color(0xFFD97706),
        dotColor: const Color(0xFFF59E0B),
        diffs: [
          TimelineDiffField(
            label: 'BRANCH HEAD',
            oldValue: 'Unassigned',
            newValue: branchHeadText,
          ),
          const TimelineDiffField(
            label: 'STATUS',
            oldValue: 'New',
            newValue: 'Scheduled',
          ),
        ],
      ),

      // 5. New Booking Created
      TimelineHistoryEvent(
        actionTitle: 'New Booking Created',
        time: '4:30 PM',
        date: displayDate,
        actor: actor,
        badgeLabel: 'New',
        badgeBg: const Color(0xFFDBEAFE),
        badgeTextColor: const Color(0xFF1D4ED8),
        dotColor: const Color(0xFF3B82F6),
        diffs: const [],
      ),
    ];
  }

  /// Groups items by booking id or title for the clicked user
  List<BookingHistoryGroup> _buildGroupedBookings() {
    final Map<String, ActivityModel> uniqueBookings = {};

    // Only include the clicked user / booking — no other users are displayed!
    final initialKey = _getGroupKey(widget.initialBooking);
    uniqueBookings[initialKey] = widget.initialBooking;

    final List<BookingHistoryGroup> groups = [];

    for (final item in uniqueBookings.values) {
      final events = _buildTimelineEventsForBooking(item);

      final bId =
          item.bookingId?.toString() ?? (item.id.isNotEmpty ? item.id : '23');

      groups.add(
        BookingHistoryGroup(
          bookingId: bId,
          bookingName: item.title,
          date: item.date.isNotEmpty ? item.date : '29/10/2026',
          status: item.statusTag ?? 'Completed',
          statusBg: item.statusTagBg ?? const Color(0xFFDCFCE7),
          statusTextColor: item.statusTagTextColor ?? const Color(0xFF15803D),
          events: events,
        ),
      );
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _buildGroupedBookings();

    final bgColor = isDark
        ? AppDarkColors.scaffoldBackground
        : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final borderColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);
    final textPrimary = isDark
        ? AppDarkColors.textPrimary
        : const Color(0xFF0F172A);
    final textSubtitle = isDark
        ? AppDarkColors.textSubtitle
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header: Back Button, "History", Refresh Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    isDark: isDark,
                    icon: Icons.chevron_left_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Text(
                    'History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppDarkColors.primaryGreen
                          : const Color(0xFF0F766E),
                    ),
                  ),
                  _buildCircleButton(
                    isDark: isDark,
                    icon: Icons.refresh_rounded,
                    onTap: () async {
                      if (widget.onRefresh != null) {
                        await widget.onRefresh!();
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            // 5. Grouped Booking Cards List
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 48,
                            color: textSubtitle,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No history records found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textSubtitle,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final groupKey = 'group_${group.bookingId}';
                        final isExpanded = _expandedGroups[groupKey] ?? true;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Accordion Header
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    _expandedGroups[groupKey] = !isExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Green Circular Clock Icon
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppDarkColors.chipPendingBg
                                              : const Color(0xFFDCFCE7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.history_rounded,
                                            size: 22,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Title + Subtitle
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    group.bookingName,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  group.date,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: textSubtitle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),

                                            // Subtitle Row: Status Pill + #ID + Updates
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: group.statusBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    group.status,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          group.statusTextColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '#${group.bookingId}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: textSubtitle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '·',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textSubtitle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${group.events.length} updates',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: textSubtitle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Accordion Chevron Arrow
                                      Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 24,
                                        color: textSubtitle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Expanded Timeline Area
                              if (isExpanded) ...[
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: borderColor,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    12,
                                  ),
                                  child: _buildTimelineList(
                                    events: group.events,
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSubtitle: textSubtitle,
                                    borderColor: borderColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList({
    required List<TimelineHistoryEvent> events,
    required bool isDark,
    required Color textPrimary,
    required Color textSubtitle,
    required Color borderColor,
  }) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          'No timeline events matching filter.',
          style: TextStyle(
            fontSize: 13,
            color: textSubtitle,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final lineColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);

    return Column(
      children: List.generate(events.length, (i) {
        final event = events[i];
        final isFirst = i == 0;
        final isLast = i == events.length - 1;

        return Stack(
          children: [
            // Vertical connecting line running behind the dot node
            Positioned(
              top: isFirst ? 14 : 0,
              bottom: isLast ? null : 0,
              height: isLast ? 14 : null,
              left:
                  11, // Centered inside the 24px wide node column: (24 - 2) / 2
              width: 2,
              child: Container(color: lineColor),
            ),

            // Main row containing Dot Node and Event Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Milestone Dot Node
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: event.dotColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Event Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Row: Badges (e.g. Completed, CURRENT) + Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: event.badgeBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    event.badgeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: event.badgeTextColor,
                                    ),
                                  ),
                                ),
                                if (event.isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F766E),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              event.time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSubtitle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Action Title
                        Text(
                          event.actionTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),

                        // Diff Container (e.g. Scheduled Date, Name, Notes, Status, Branch Head)
                        if (event.diffs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppDarkColors.surfaceSecondary
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppDarkColors.border
                                    : const Color(0xFFF1F5F9),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(event.diffs.length, (
                                diffIdx,
                              ) {
                                final diff = event.diffs[diffIdx];
                                final isLastDiff =
                                    diffIdx == event.diffs.length - 1;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLastDiff ? 0 : 6.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        diff.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: textSubtitle,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (diff.multiline) ...[
                                        Text(
                                          '${diff.oldValue}  →',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          diff.newValue,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ] else ...[
                                        Row(
                                          children: [
                                            Text(
                                              diff.oldValue,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 13,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                diff.newValue,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),

                        // Subtitle: Date + Author
                        Text(
                          '${event.date} · by ${event.actor}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCircleButton({
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppDarkColors.primaryGreen : AppColors.brandGreen)
                : (isDark
                      ? AppDarkColors.surfaceCard
                      : const Color(0xFFF1F5F9)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? Colors.white
                : (isDark
                      ? AppDarkColors.textPrimary
                      : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
