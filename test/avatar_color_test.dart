import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/theme.dart';
import 'package:task_chat/core/widgets/user_circle_avatar.dart';
import 'package:task_chat/today/widgets/chat_list_item_tile.dart';

void main() {
  group('Avatar status color rules', () {
    test('Scheduled status resolves to scheduled amber color', () {
      final color = getAvatarColorsForStatus('Scheduled');
      expect(color.background, equals(AppColors.scheduledBg));
      expect(color.icon, equals(AppColors.scheduledText));
    });

    test('Completed status resolves to completed green color', () {
      final color = getAvatarColorsForStatus('Completed');
      expect(color.background, equals(AppColors.completedBg));
      expect(color.icon, equals(AppColors.completedText));
    });

    test('New status resolves to new blue color', () {
      final color = getAvatarColorsForStatus('New');
      expect(color.background, equals(AppColors.newBg));
      expect(color.icon, equals(AppColors.newText));
    });

    test('Cancelled status resolves to cancelled red color', () {
      final color = getAvatarColorsForStatus('Cancelled');
      expect(color.background, equals(AppColors.cancelledBg));
      expect(color.icon, equals(AppColors.cancelledText));
    });

    test('Pending status resolves to pending chip green color', () {
      final color = getAvatarColorsForStatus('Pending');
      expect(color.background, equals(AppColors.chipPendingBg));
      expect(color.icon, equals(AppColors.chipPendingText));
    });

    test('Dark mode resolves to AppDarkColors status palette', () {
      final sched = getAvatarColorsForStatus('Scheduled', isDark: true);
      expect(sched.background, equals(AppDarkColors.scheduledBg));
      expect(sched.icon, equals(AppDarkColors.scheduledText));

      final comp = getAvatarColorsForStatus('Completed', isDark: true);
      expect(comp.background, equals(AppDarkColors.completedBg));
      expect(comp.icon, equals(AppDarkColors.completedText));

      final canc = getAvatarColorsForStatus('Cancelled', isDark: true);
      expect(canc.background, equals(AppDarkColors.cancelledBg));
      expect(canc.icon, equals(AppDarkColors.cancelledText));
    });

    test('Case-insensitivity applies to status matching', () {
      expect(
        getAvatarColorsForStatus('scheduled').background,
        equals(getAvatarColorsForStatus('SCHEDULED').background),
      );
      expect(
        getAvatarColorsForStatus('completed').background,
        equals(getAvatarColorsForStatus('COMPLETED').background),
      );
      expect(
        getAvatarColorsForStatus('cancelled').background,
        equals(getAvatarColorsForStatus('Cancelled').background),
      );
    });

    testWidgets('UserCircleAvatar renders with status color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserCircleAvatar(status: 'Scheduled')),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(UserCircleAvatar),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      final containerWidget = tester.widget<Container>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.scheduledBg));
    });

    testWidgets('ChatListItemTile renders avatar with status-resolved color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatListItemTile(
              title: 'Peter Parker',
              date: '23/10/2026',
              tagText: 'Scheduled',
              location: 'Kochi',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(UserCircleAvatar),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      final containerWidget = tester.widget<Container>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.scheduledBg));
    });
  });
}
