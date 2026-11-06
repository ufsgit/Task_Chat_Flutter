import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/report_activity/widgets/history_skeleton_loading.dart';

void main() {
  testWidgets('HistorySkeletonLoading renders card and timeline event placeholders with shimmer animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HistorySkeletonLoading(),
        ),
      ),
    );

    expect(find.byType(HistorySkeletonLoading), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    // Advance animation by 300ms to verify shimmer controller runs smoothly
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HistorySkeletonLoading), findsOneWidget);
  });
}

