import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/dashboard/dashboard_model.dart';
import 'package:task_chat/dashboard/widgets/metric_stat_card.dart';

void main() {
  const newBookingMetric = MetricCardData(
    title: 'New Booking',
    value: '48',
    subtitle: 'New bookings per month',
    titleColor: Color(0xFFA3E635),
    leadingIcon: Icons.person_add_alt_1_rounded,
    iconBgColor: Color(0xFF1D61E7),
    iconColor: Color(0xFFA3E635),
    cardBgColor: Color(0xFFF2F7FE),
    darkCardBgColor: Color.fromARGB(255, 36, 36, 41),
  );

  const completedMetric = MetricCardData(
    title: 'Completed',
    value: '31',
    subtitle: 'Completed orders per month',
    percentageText: '64.5%',
    percentageColor: Colors.green,
    titleColor: Colors.green,
    leadingIcon: Icons.check_circle_outline_rounded,
    iconBgColor: Color(0xFF15803D),
    iconColor: Colors.green,
    cardBgColor: Color(0xFFEFFBF3),
    darkCardBgColor: Color.fromARGB(255, 36, 36, 41),
  );

  testWidgets('MetricStatCard renders title beside icon and no progress bar for completed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(child: MetricStatCard(data: newBookingMetric)),
              Expanded(child: MetricStatCard(data: completedMetric)),
            ],
          ),
        ),
      ),
    );

    // Verify titles and numbers are present
    expect(find.text('New Booking'), findsOneWidget);
    final newBookingNumberText = tester.widget<Text>(find.text('48'));
    expect(newBookingNumberText.style?.color, equals(newBookingMetric.iconColor));

    expect(find.text('Completed'), findsOneWidget);
    final completedNumberText = tester.widget<Text>(find.text('31'));
    expect(completedNumberText.style?.color, equals(completedMetric.iconColor));
    expect(find.text('64.5%'), findsOneWidget);

    // Verify progress bar is not present
    expect(find.byType(FractionallySizedBox), findsNothing);
  });
}
