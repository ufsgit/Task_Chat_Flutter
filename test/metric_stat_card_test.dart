import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/dashboard/dashboard_model.dart';
import 'package:task_chat/dashboard/widgets/metric_stat_card.dart';

void main() {
  testWidgets('MetricStatCard renders title beside icon and no progress bar for completed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(child: MetricStatCard(data: defaultNewBookingMetric)),
              Expanded(child: MetricStatCard(data: defaultCompletedMetric)),
            ],
          ),
        ),
      ),
    );

    // Verify titles and numbers are present
    expect(find.text('New Booking'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('64.5%'), findsOneWidget);

    // Verify progress bar is not present
    expect(find.byType(FractionallySizedBox), findsNothing);
  });
}
