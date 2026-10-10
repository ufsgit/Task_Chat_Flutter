import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../report_data.dart';
import '../widgets/report_menu_card.dart';

/// Report & Activity landing screen.
/// Keeps data cleanly separated in `report_data.dart` and UI modular in `widgets/`.
class ReportActivity extends StatelessWidget {
  const ReportActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'TaskChat',
          style: TextStyle(
            color: AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...defaultReportMenuItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: ReportMenuCard(
                    item: item,
                    onTap: () {
                      // Action when tapping Report 1 or Activity
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
