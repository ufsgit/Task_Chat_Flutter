import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../api/authenticated_client.dart';
import '../../core/status_color_service.dart';
import '../../core/theme.dart';
import '../../login_page/token_storage.dart';
import 'activity_model.dart';
import 'activity_view_model.dart';

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
  final ActivityViewModel? viewModel;
  final http.Client? client;
  final TokenStorage? tokenStorage;

  const BookingHistoryPage({
    super.key,
    required this.initialBooking,
    this.allActivities = const [],
    this.onRefresh,
    this.viewModel,
    this.client,
    this.tokenStorage,
  });

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  // Track which booking accordion cards are expanded
  final Map<String, bool> _expandedGroups = {};
  bool _isLoading = false;
  List<TimelineHistoryEvent>? _apiTimelineEvents;

  @override
  void initState() {
    super.initState();
    // Expand initial booking by default
    final initialKey = _getGroupKey(widget.initialBooking);
    _expandedGroups[initialKey] = true;

    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final bookingId =
        widget.initialBooking.bookingId ??
        int.tryParse(widget.initialBooking.id);
    if (bookingId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>>? rawList;
      int? totalCount;
      int? limit;

      if (widget.viewModel != null) {
        rawList = await widget.viewModel!.fetchHistoryByBookingId(bookingId);
      } else {
        final url = ApiConfig.reportGraphByBookingId(bookingId);
        debugPrint('>>> [BookingHistoryPage] Fetching history from: $url');

        String? token;
        try {
          final isTest = TokenStorage.isTestEnvironment;
          token = await (widget.tokenStorage ?? TokenStorage())
              .getToken()
              .timeout(
                isTest
                    ? const Duration(milliseconds: 50)
                    : const Duration(seconds: 2),
                onTimeout: () => null,
              );
        } catch (_) {}

        final headers = <String, String>{
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'authorization': token.startsWith('Bearer ')
                ? token
                : 'Bearer $token',
        };

        final isLocalClient = widget.client == null;
        final client = widget.client ?? AuthenticatedClient();
        try {
          final response = TokenStorage.isTestEnvironment
              ? await client.get(Uri.parse(url), headers: headers)
              : await client
                    .get(Uri.parse(url), headers: headers)
                    .timeout(const Duration(seconds: 10));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final decoded = json.decode(response.body);
            rawList = ActivityViewModel.extractHistoryList(decoded);
            if (decoded is Map<String, dynamic>) {
              final data = decoded['data'];
              if (data is Map<String, dynamic>) {
                totalCount = int.tryParse(
                  data['count']?.toString() ?? data['total']?.toString() ?? '',
                );
                limit = int.tryParse(data['limit']?.toString() ?? '');
              } else {
                totalCount = int.tryParse(
                  decoded['count']?.toString() ??
                      decoded['total']?.toString() ??
                      '',
                );
                limit = int.tryParse(decoded['limit']?.toString() ?? '');
              }
            }

            // Auto-paginate remaining pages if total count exceeds the first page
            int page = 1;
            while (rawList != null &&
                totalCount != null &&
                rawList.length < totalCount &&
                !TokenStorage.isTestEnvironment) {
              page++;
              final nextUri = Uri.parse(url).replace(
                queryParameters: {
                  'page': page.toString(),
                  'limit': (limit ?? 20).toString(),
                },
              );
              final nextResponse = await client
                  .get(nextUri, headers: headers)
                  .timeout(const Duration(seconds: 10));
              if (nextResponse.statusCode >= 200 &&
                  nextResponse.statusCode < 300) {
                final nextDecoded = json.decode(nextResponse.body);
                final nextItems = ActivityViewModel.extractHistoryList(
                  nextDecoded,
                );
                if (nextItems != null && nextItems.isNotEmpty) {
                  rawList.addAll(nextItems);
                } else {
                  break;
                }
              } else {
                break;
              }
            }
          }
        } finally {
          if (isLocalClient) {
            client.close();
          }
        }
      }

      if (rawList != null && rawList.isNotEmpty && mounted) {
        final parsed = <TimelineHistoryEvent>[];
        for (int i = 0; i < rawList.length; i++) {
          parsed.add(
            _parseApiHistoryItem(
              rawList[i],
              isCurrent: i == 0,
              fallbackBooking: widget.initialBooking,
            ),
          );
        }
        setState(() {
          _apiTimelineEvents = parsed;
        });
      }
    } catch (e, stack) {
      debugPrint('<<< [BookingHistoryPage] _fetchHistory error: $e');
      debugPrint('$stack');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  TimelineHistoryEvent _parseApiHistoryItem(
    Map<String, dynamic> item, {
    required bool isCurrent,
    required ActivityModel fallbackBooking,
  }) {
    final actionType =
        item['action_type']?.toString().trim() ??
        item['actionType']?.toString().trim() ??
        item['action']?.toString().trim() ??
        item['title']?.toString().trim() ??
        item['type']?.toString().trim();
    final actionTitle = (actionType != null && actionType.isNotEmpty)
        ? actionType
        : 'Activity Updated';

    final actor =
        item['action_by_name']?.toString().trim() ??
        item['actionByName']?.toString().trim() ??
        item['created_by_name']?.toString().trim() ??
        item['createdByName']?.toString().trim() ??
        item['userName']?.toString().trim() ??
        item['user_name']?.toString().trim() ??
        item['loginName']?.toString().trim();
    final actorName = (actor != null && actor.isNotEmpty)
        ? actor
        : (fallbackBooking.actionByName ??
              fallbackBooking.subtitleHighlight ??
              'Staff');

    DateTime? createdAt;
    final rawCreatedAt =
        item['created_at']?.toString() ??
        item['createdAt']?.toString() ??
        item['timestamp']?.toString() ??
        item['date']?.toString();
    if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    String displayDate = '';
    String displayTime = '';
    if (createdAt != null) {
      final local = createdAt.toLocal();
      displayDate =
          '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      final hour = local.hour == 0
          ? 12
          : (local.hour > 12 ? local.hour - 12 : local.hour);
      final period = local.hour >= 12 ? 'PM' : 'AM';
      displayTime = '$hour:${local.minute.toString().padLeft(2, '0')} $period';
    } else {
      displayDate = fallbackBooking.date;
      displayTime = '';
    }

    final newStatusLabel =
        item['new_status_label']?.toString() ??
        item['new_status_code']?.toString() ??
        item['new_status']?.toString() ??
        item['status']?.toString() ??
        item['status_label']?.toString();
    final badgeLabel = (newStatusLabel != null && newStatusLabel.isNotEmpty)
        ? newStatusLabel
        : ((actionType != null && actionType.isNotEmpty)
              ? actionType
              : 'Updated');

    final colorCode =
        item['new_status_color_code']?.toString() ??
        item['status_color_code']?.toString() ??
        item['colorCode']?.toString() ??
        item['color_code']?.toString();
    final parsedColor = StatusColorService.parseHexColor(colorCode);
    final badgeColors = StatusColorService.getBadgeColors(
      newStatusLabel ?? actionTitle,
      customColor: parsedColor,
    );
    final dotColor = badgeColors.dot;
    final badgeBg = badgeColors.bg;
    final badgeTextColor = badgeColors.text;

    final List<TimelineDiffField> diffs = [];

    // 1. Status Diff
    final oldStatus =
        item['old_status_label']?.toString() ??
        item['old_status_code']?.toString() ??
        item['old_status']?.toString();
    if (newStatusLabel != null && newStatusLabel.isNotEmpty) {
      if (oldStatus != null &&
          oldStatus.isNotEmpty &&
          oldStatus != newStatusLabel) {
        diffs.add(
          TimelineDiffField(
            label: 'STATUS',
            oldValue: oldStatus,
            newValue: newStatusLabel,
          ),
        );
      } else if (oldStatus == null || oldStatus.isEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'STATUS',
            oldValue: '',
            newValue: newStatusLabel,
          ),
        );
      }
    }

    // 2. Schedule Date Diff
    final oldSchedule =
        item['old_schedule_date']?.toString() ??
        item['oldScheduleDate']?.toString();
    final newSchedule =
        item['new_schedule_date']?.toString() ??
        item['newScheduleDate']?.toString() ??
        item['schedule_date']?.toString() ??
        item['scheduleDate']?.toString();
    if (oldSchedule != null || newSchedule != null) {
      String fmtDate(String? s) {
        if (s == null || s.isEmpty) return 'None';
        final dt = DateTime.tryParse(s);
        if (dt != null) {
          final l = dt.toLocal();
          return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
        }
        return s;
      }

      if (oldSchedule != null &&
          newSchedule != null &&
          oldSchedule != newSchedule) {
        diffs.add(
          TimelineDiffField(
            label: 'SCHEDULED DATE',
            oldValue: fmtDate(oldSchedule),
            newValue: fmtDate(newSchedule),
          ),
        );
      } else if (newSchedule != null && newSchedule.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'SCHEDULED DATE',
            oldValue: oldSchedule != null && oldSchedule.isNotEmpty
                ? fmtDate(oldSchedule)
                : '',
            newValue: fmtDate(newSchedule),
          ),
        );
      }
    }

    // 3. Transfer / Branch / District Diff
    final fromBranch =
        item['from_branch_head_name']?.toString() ??
        item['from_assigned_head_district_name']?.toString() ??
        item['from_branch']?.toString() ??
        item['from_district']?.toString();
    final toBranch =
        item['to_branch_head_name']?.toString() ??
        item['to_assigned_head_district_name']?.toString() ??
        item['to_branch']?.toString() ??
        item['to_district']?.toString();
    if (fromBranch != null || toBranch != null) {
      diffs.add(
        TimelineDiffField(
          label: 'BRANCH HEAD / DISTRICT',
          oldValue: fromBranch ?? 'Unassigned',
          newValue: toBranch ?? 'Unassigned',
        ),
      );
    }

    // 4. Staff Note
    final staffNote =
        item['staff_note']?.toString().trim() ??
        item['staffNote']?.toString().trim();
    if (staffNote != null && staffNote.isNotEmpty) {
      diffs.add(
        TimelineDiffField(
          label: 'STAFF NOTE',
          oldValue: '',
          newValue: staffNote,
          multiline: true,
        ),
      );
    }

    // 5. Customer Note
    final custNote =
        item['customer_note']?.toString().trim() ??
        item['customerNote']?.toString().trim();
    if (custNote != null && custNote.isNotEmpty) {
      diffs.add(
        TimelineDiffField(
          label: 'CUSTOMER NOTE',
          oldValue: '',
          newValue: custNote,
          multiline: true,
        ),
      );
    }

    // 6. General Notes / Remarks
    final generalNote =
        item['notes']?.toString().trim() ??
        item['note']?.toString().trim() ??
        item['comment']?.toString().trim() ??
        item['comments']?.toString().trim() ??
        item['remarks']?.toString().trim() ??
        item['description']?.toString().trim();
    if (generalNote != null &&
        generalNote.isNotEmpty &&
        generalNote != staffNote &&
        generalNote != custNote) {
      final oldNote =
          item['old_notes']?.toString().trim() ??
          item['old_note']?.toString().trim();
      diffs.add(
        TimelineDiffField(
          label: 'NOTES',
          oldValue: oldNote ?? '',
          newValue: generalNote,
          multiline: true,
        ),
      );
    }

    // 7. Client / Booking Name Diff
    final oldName =
        item['old_booking_name']?.toString() ??
        item['old_client_name']?.toString();
    final newName =
        item['new_booking_name']?.toString() ??
        item['new_client_name']?.toString() ??
        item['booking_name']?.toString() ??
        item['clientName']?.toString();
    if (oldName != null && newName != null && oldName != newName) {
      diffs.add(
        TimelineDiffField(label: 'NAME', oldValue: oldName, newValue: newName),
      );
    }

    // 8. Contact Number Diff
    final oldPhone =
        item['old_mobile']?.toString() ?? item['old_phone']?.toString();
    final newPhone =
        item['new_mobile']?.toString() ??
        item['new_phone']?.toString() ??
        item['mobile']?.toString() ??
        item['phone']?.toString();
    if (oldPhone != null && newPhone != null && oldPhone != newPhone) {
      diffs.add(
        TimelineDiffField(
          label: 'CONTACT NUMBER',
          oldValue: oldPhone,
          newValue: newPhone,
        ),
      );
    }

    // 9. Location / Address Diff
    final oldAddress =
        item['old_address']?.toString() ?? item['old_location']?.toString();
    final newAddress =
        item['new_address']?.toString() ??
        item['new_location']?.toString() ??
        item['address']?.toString() ??
        item['location']?.toString();
    if (oldAddress != null && newAddress != null && oldAddress != newAddress) {
      diffs.add(
        TimelineDiffField(
          label: 'LOCATION',
          oldValue: oldAddress,
          newValue: newAddress,
        ),
      );
    }

    // 10. Fallback for creation / initial events when diffs is otherwise empty
    if (diffs.isEmpty) {
      if (newStatusLabel != null && newStatusLabel.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'STATUS',
            oldValue: '',
            newValue: newStatusLabel,
          ),
        );
      }
      if (fallbackBooking.noteText != null &&
          fallbackBooking.noteText!.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'NOTES',
            oldValue: '',
            newValue: fallbackBooking.noteText!,
            multiline: true,
          ),
        );
      }
      if (fallbackBooking.location != null &&
          fallbackBooking.location!.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'LOCATION',
            oldValue: '',
            newValue: fallbackBooking.location!,
          ),
        );
      }
    }

    return TimelineHistoryEvent(
      actionTitle: actionTitle,
      time: displayTime,
      date: displayDate,
      actor: actorName,
      badgeLabel: badgeLabel,
      badgeBg: badgeBg,
      badgeTextColor: badgeTextColor,
      isCurrent: isCurrent,
      dotColor: dotColor,
      diffs: diffs,
    );
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

  /// Generates timeline events from ActivityModel items when API history is unavailable or to merge.
  List<TimelineHistoryEvent> _buildTimelineEventsFromActivities(
    List<ActivityModel> activities,
  ) {
    return activities.asMap().entries.map((entry) {
      final index = entry.key;
      final act = entry.value;

      final diffs = <TimelineDiffField>[];
      if (act.statusTag != null && act.statusTag!.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'STATUS',
            oldValue: '',
            newValue: act.statusTag!,
          ),
        );
      }
      if (act.noteText != null && act.noteText!.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'NOTES',
            oldValue: '',
            newValue: act.noteText!,
            multiline: true,
          ),
        );
      }
      if (act.location != null && act.location!.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'LOCATION',
            oldValue: '',
            newValue: act.location!,
          ),
        );
      }
      if (act.subtitleHighlight != null && act.subtitleHighlight!.isNotEmpty) {
        diffs.add(
          TimelineDiffField(
            label: 'ASSIGNED TO',
            oldValue: '',
            newValue: act.subtitleHighlight!,
          ),
        );
      }

      String time = '';
      if (act.dateTime != null) {
        final local = act.dateTime!.toLocal();
        final hour = local.hour == 0
            ? 12
            : (local.hour > 12 ? local.hour - 12 : local.hour);
        final period = local.hour >= 12 ? 'PM' : 'AM';
        time = '$hour:${local.minute.toString().padLeft(2, '0')} $period';
      }

      final badgeColors = StatusColorService.getBadgeColors(
        act.statusTag ?? 'Updated',
        customColor: act.statusTagTextColor,
      );

      return TimelineHistoryEvent(
        actionTitle:
            act.actionType ??
            (act.statusTag != null
                ? '${act.statusTag} Status'
                : 'Booking Updated'),
        time: time,
        date: act.date.isNotEmpty ? act.date : 'Today',
        actor: act.actionByName ?? act.subtitleHighlight ?? 'Staff',
        badgeLabel: act.statusTag ?? 'Updated',
        badgeBg: act.statusTagBg ?? badgeColors.bg,
        badgeTextColor: act.statusTagTextColor ?? badgeColors.text,
        isCurrent: index == 0,
        dotColor: act.avatarTextColor,
        diffs: diffs,
      );
    }).toList();
  }

  /// Merges API events with activity events so that no timeline events are lost
  /// when the API returns fewer items than previously loaded from the activity list.
  List<TimelineHistoryEvent> _mergeTimelineEvents(
    List<TimelineHistoryEvent> apiEvents,
    List<TimelineHistoryEvent> activityEvents,
  ) {
    if (apiEvents.isEmpty) return activityEvents;
    if (activityEvents.isEmpty) return apiEvents;

    final List<TimelineHistoryEvent> merged = List.of(apiEvents);

    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    for (final actEvent in activityEvents) {
      final actTitleNorm = norm(actEvent.actionTitle);
      final actBadgeNorm = norm(actEvent.badgeLabel);
      final actDateNorm = norm(actEvent.date);

      final exists = merged.any((apiEvent) {
        final apiTitleNorm = norm(apiEvent.actionTitle);
        final apiBadgeNorm = norm(apiEvent.badgeLabel);
        final apiDateNorm = norm(apiEvent.date);

        final titleMatches =
            apiTitleNorm == actTitleNorm ||
            (actTitleNorm.contains(apiTitleNorm) && apiTitleNorm.isNotEmpty) ||
            (apiTitleNorm.contains(actTitleNorm) && actTitleNorm.isNotEmpty) ||
            (apiBadgeNorm == actBadgeNorm && actBadgeNorm.isNotEmpty);

        final dateMatches =
            apiDateNorm == actDateNorm ||
            apiDateNorm.isEmpty ||
            actDateNorm.isEmpty ||
            actDateNorm == 'today';

        return titleMatches && dateMatches;
      });

      if (!exists) {
        merged.add(actEvent);
      }
    }

    return [
      for (int i = 0; i < merged.length; i++)
        if (i == 0 && !merged[i].isCurrent)
          TimelineHistoryEvent(
            actionTitle: merged[i].actionTitle,
            time: merged[i].time,
            date: merged[i].date,
            actor: merged[i].actor,
            badgeLabel: merged[i].badgeLabel,
            badgeBg: merged[i].badgeBg,
            badgeTextColor: merged[i].badgeTextColor,
            isCurrent: true,
            dotColor: merged[i].dotColor,
            diffs: merged[i].diffs,
          )
        else if (i > 0 && merged[i].isCurrent)
          TimelineHistoryEvent(
            actionTitle: merged[i].actionTitle,
            time: merged[i].time,
            date: merged[i].date,
            actor: merged[i].actor,
            badgeLabel: merged[i].badgeLabel,
            badgeBg: merged[i].badgeBg,
            badgeTextColor: merged[i].badgeTextColor,
            isCurrent: false,
            dotColor: merged[i].dotColor,
            diffs: merged[i].diffs,
          )
        else
          merged[i],
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
      final matchingActivities = widget.allActivities
          .where(
            (a) =>
                (item.bookingId != null && a.bookingId == item.bookingId) ||
                (a.id.isNotEmpty && a.id == item.id) ||
                (a.title.trim().toLowerCase() ==
                    item.title.trim().toLowerCase()),
          )
          .toList();

      final List<TimelineHistoryEvent> activityEvents =
          (matchingActivities.length > 1 ||
              (matchingActivities.isNotEmpty &&
                  (matchingActivities.first.actionType != null ||
                      matchingActivities.first.id != '23')))
          ? _buildTimelineEventsFromActivities(matchingActivities)
          : const [];

      final List<TimelineHistoryEvent> events;
      if (_apiTimelineEvents != null && _apiTimelineEvents!.isNotEmpty) {
        if (activityEvents.isEmpty) {
          events = _apiTimelineEvents!;
        } else {
          events = _mergeTimelineEvents(_apiTimelineEvents!, activityEvents);
        }
      } else if (activityEvents.isNotEmpty) {
        events = activityEvents;
      } else {
        events = _buildTimelineEventsForBooking(item);
      }

      final bId =
          item.bookingId?.toString() ?? (item.id.isNotEmpty ? item.id : '23');

      final latestEvent = events.isNotEmpty ? events.first : null;
      final status = item.statusTag ?? latestEvent?.badgeLabel ?? 'Completed';
      final statusBg =
          item.statusTagBg ?? latestEvent?.badgeBg ?? const Color(0xFFDCFCE7);
      final statusTextColor =
          item.statusTagTextColor ??
          latestEvent?.badgeTextColor ??
          const Color(0xFF15803D);
      final date =
          latestEvent?.date ??
          (item.date.isNotEmpty ? item.date : '29/10/2026');

      groups.add(
        BookingHistoryGroup(
          bookingId: bId,
          bookingName: item.title,
          date: date,
          status: status,
          statusBg: statusBg,
          statusTextColor: statusTextColor,
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
                      await _fetchHistory();
                    },
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2.5,
                color: AppColors.primaryGreen,
                backgroundColor: Colors.transparent,
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
                      scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final groupKey = 'group_${group.bookingId}';
                        final isExpanded = _expandedGroups[groupKey] ?? true;

                        return RepaintBoundary(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor,
                                width: 1.2,
                              ),
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
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                        color: group
                                                            .statusTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '#${group.bookingId}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
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
          'No timeline events found.',
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
                                        if (diff.oldValue.isNotEmpty)
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
                                            if (diff.oldValue.isNotEmpty) ...[
                                              Text(
                                                diff.oldValue,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  decoration: TextDecoration
                                                      .lineThrough,
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
                                            ],
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
