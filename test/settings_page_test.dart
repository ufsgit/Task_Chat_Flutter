import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/bottom_navigator/bottom_navigator.dart';
import 'package:task_chat/login_page/login_model.dart';
import 'package:task_chat/settings/settings_model.dart';
import 'package:task_chat/settings/settings_view.dart';
import 'package:task_chat/settings/settings_view_model.dart';

void main() {
  const testProfile = UserProfileData(
    name: 'Rajesh Menon',
    initials: 'RM',
    phone: '+91 98470 12345',
    email: 'rajesh.menon@steeldoor.com',
    stateName: 'Kerala',
    districtName: 'Ernakulam Hub',
  );

  const testUser = UserModel(
    id: 4,
    username: 'branch_ekm',
    roleId: 3,
    role: 'branch_head',
    name: 'Rajesh Menon',
    email: 'rajesh.menon@steeldoor.com',
    phone: '+91 98470 12345',
    stateName: 'Kerala',
    districtName: 'Ernakulam Hub',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsPage renders initials RM, user info, About, and Logout',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsPage(profile: testProfile),
        ),
      ),
    );

    expect(find.text('RM'), findsOneWidget);
    expect(find.text('Rajesh Menon'), findsOneWidget);
    expect(find.text('+91 98470 12345'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    // Tap About to verify About bottom sheet displays API data
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('rajesh.menon@steeldoor.com'), findsOneWidget);
    expect(find.text('Kerala'), findsOneWidget);
    expect(find.text('Ernakulam Hub'), findsOneWidget);
  });

  testWidgets('BottomNavigator switches to Settings tab and renders passed user',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BottomNavigator(user: testUser),
      ),
    );

    // Initially Dashboard or Today is shown
    expect(find.text('RM'), findsNothing);

    // Tap on Settings nav item icon
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify SettingsPage content is visible
    expect(find.text('RM'), findsOneWidget);
    expect(find.text('Rajesh Menon'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  test('UserProfileData saves, loads, and clears from SharedPreferences',
      () async {
    await UserProfileData.save(testUser);
    final loaded = await UserProfileData.load();
    expect(loaded?.name, 'Rajesh Menon');
    expect(loaded?.phone, '+91 98470 12345');
    expect(loaded?.email, 'rajesh.menon@steeldoor.com');

    await UserProfileData.clear();
    final cleared = await UserProfileData.load();
    expect(cleared, isNull);
  });

  test('SettingsViewModel loads profile and performs logout', () async {
    await UserProfileData.save(testUser);
    final vm = SettingsViewModel();
    expect(vm.activeProfile.name, '');

    await vm.loadProfile();
    expect(vm.profile?.name, 'Rajesh Menon');
    expect(vm.activeProfile.name, 'Rajesh Menon');

    await vm.logout();
    expect(vm.profile, isNull);
    expect(await UserProfileData.load(), isNull);
  });
}
