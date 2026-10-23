import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/Coordinator/cordinator_page.dart';
import 'package:task_chat/Coordinator/widgets/super_admin_filter_bottom_sheet.dart';

void main() {
  testWidgets(
      'SuperAdminPage renders search bar and filter button with Status and Branch Manager options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminPage(),
      ),
    );

    // Verify search bar and filter icon exist
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Tap filter button to open bottom sheet
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // Verify both Status and Branch Manager filter sections are displayed
    expect(find.text('Filter Options'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Branch Manager'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SuperAdminFilterBottomSheet),
        matching: find.text('Sarah Jenkins'),
      ),
      findsOneWidget,
    );
    expect(find.text('Apply Filters'), findsOneWidget);

    // Select 'Completed' status inside bottom sheet
    await tester.tap(
      find.descendant(
        of: find.byType(SuperAdminFilterBottomSheet),
        matching: find.text('Completed'),
      ),
    );
    await tester.pumpAndSettle();

    // Select 'Sarah Jenkins' branch manager
    await tester.tap(
      find.descendant(
        of: find.byType(SuperAdminFilterBottomSheet),
        matching: find.text('Sarah Jenkins'),
      ),
    );
    await tester.pumpAndSettle();

    // Apply filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // Verify modal dismissed and active filter badges appear
    expect(find.text('Filter Options'), findsNothing);
    expect(find.text('Status: Completed'), findsOneWidget);
    expect(find.text('Manager: Sarah Jenkins'), findsOneWidget);
  });

  test('CoordinatorViewModel manages filters, search, and state properly in MVVM', () {
    final vm = CoordinatorViewModel();
    expect(vm.selectedFilterIndex, 0);
    expect(vm.selectedStatusFilter, 'All');
    expect(vm.selectedManagerFilter, 'All');
    expect(vm.hasActiveFilters, isFalse);

    // Filter index
    vm.setFilterIndex(1);
    expect(vm.selectedFilterIndex, 1);

    // Apply status and manager filter
    vm.applyFilters('Completed', 'Sarah Jenkins');
    expect(vm.selectedStatusFilter, 'Completed');
    expect(vm.selectedManagerFilter, 'Sarah Jenkins');
    expect(vm.hasActiveFilters, isTrue);

    // Reset filters
    vm.resetFilters();
    expect(vm.selectedStatusFilter, 'All');
    expect(vm.selectedManagerFilter, 'All');
    expect(vm.hasActiveFilters, isFalse);

    // Search query
    vm.searchController.text = 'non_existent_query_xyz';
    expect(vm.filteredChatItems, isEmpty);

    vm.clearSearch();
    expect(vm.searchController.text, isEmpty);

    vm.dispose();
  });
}
