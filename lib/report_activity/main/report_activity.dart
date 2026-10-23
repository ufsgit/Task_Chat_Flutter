import 'package:flutter/material.dart';
import '../../core/widgets/fitmate_app_bar_title.dart';
import '../activity_page.dart';
import '../report_data.dart';
import '../task_report_page.dart';
import '../widgets/report_menu_card.dart';

/// Report & Activity landing screen.
/// Keeps data cleanly separated in `report_data.dart` and UI modular in `widgets/`.
class ReportActivity extends StatelessWidget {
  const ReportActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        toolbarHeight: 68,
        title: const FitmateAppBarTitle(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...defaultReportMenuItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: ReportMenuCard(
                    item: item,
                    onTap: () {
                      if (item.title == 'Activity') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivityPage(),
                          ),
                        );
                      } else if (item.title == 'Report 1' ||
                          item.title == 'Task Report') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskReportPage(),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
