import 'package:flutter/material.dart';
import '../api/api.dart';
import 'activity/activity_view.dart';
import 'activity/activity_view_model.dart';

export 'activity/activity_model.dart';
export 'activity/activity_view.dart';
export 'activity/activity_view_model.dart';
export 'activity/booking_history_page.dart';

/// Activity page displaying live booking history from ApiConfig.history_list.
class ActivityPage extends StatefulWidget {
  final VoidCallback? onBack;
  final ActivityViewModel? viewModel;

  const ActivityPage({super.key, this.onBack, this.viewModel});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  late final ActivityViewModel _viewModel;
  late final bool _isLocalViewModel;

  @override
  void initState() {
    super.initState();
    debugPrint('>>> [ActivityPage] Opening ActivityPage -> triggering ${ApiConfig.history_list}');
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isLocalViewModel = false;
    } else {
      _viewModel = ActivityViewModel();
      _isLocalViewModel = true;
    }
    _viewModel.fetchHistory();
  }

  @override
  void dispose() {
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActivityView(
      onBack: widget.onBack,
      viewModel: _viewModel,
    );
  }
}
