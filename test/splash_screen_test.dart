import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/login_page/login_model.dart';
import 'package:task_chat/login_page/login_view.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/settings/settings_model.dart';
import 'package:task_chat/splash/splash_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.useMemoryOnly = true;
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
  });

  testWidgets(
      'SplashScreen displays brand elements and navigates to LoginPage when no token',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial frame: brand name should be present
    expect(find.text('Fitmate'), findsOneWidget);

    await tester.pumpAndSettle();

    // Now transitioned to LoginPage
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets(
      'SplashScreen validates session with Checkvalid (200 OK) and routes to HomePage',
      (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savetoken('test_initial_token');

    final mockClient = MockClient((request) async {
      expect(request.url.toString(), equals(ApiConfig.Checkvalid));
      expect(request.headers['Authorization'], equals('Bearer test_initial_token'));

      return http.Response(
        jsonEncode({
          'sessionToken': 'refreshed_session_token_123',
          'user': {
            'id': 10,
            'username': 'johndoe',
            'roleId': 2,
            'role': 'Coordinator',
            'name': 'John Doe',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          tokenStorage: tokenStorage,
          client: mockClient,
          homeBuilder: (_, user) => Scaffold(
            body: Text('Home Screen Loaded for ${user?.name}'),
          ),
        ),
      ),
    );

    // Initial frame on SplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpAndSettle();

    // Transitioned to HomePage / custom homeBuilder with updated user profile
    expect(find.text('Home Screen Loaded for John Doe'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    // Refreshed token should be saved
    final savedToken = await tokenStorage.getToken();
    expect(savedToken, equals('refreshed_session_token_123'));

    // User profile should be saved
    final savedUser = await UserProfileData.loadUser();
    expect(savedUser?.name, equals('John Doe'));

    // Cleanup
    await tokenStorage.deleteToken();
    await UserProfileData.clear();
  });

  testWidgets(
      'SplashScreen handles 401 Unauthorized from Checkvalid: clears session and routes to LoginPage',
      (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savetoken('expired_token_abc');
    await UserProfileData.save(
      const UserModel(
        id: 99,
        username: 'olduser',
        roleId: 3,
        role: 'Branch Manager',
        name: 'Old User',
      ),
    );

    final mockClient = MockClient((request) async {
      expect(request.url.toString(), equals(ApiConfig.Checkvalid));
      return http.Response(
        jsonEncode({'error': 'Unauthorized - invalid/expired token or user inactive/deleted'}),
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          tokenStorage: tokenStorage,
          client: mockClient,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Transitioned to LoginPage
    expect(find.byType(LoginPage), findsOneWidget);

    // Token and User profile should be cleared
    final savedToken = await tokenStorage.getToken();
    expect(savedToken, isNull);

    final savedUser = await UserProfileData.loadUser();
    expect(savedUser, isNull);
  });

  testWidgets(
      'SplashScreen falls back to cached user profile when network offline/fails',
      (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savetoken('test_cached_token');
    await UserProfileData.save(
      const UserModel(
        id: 5,
        username: 'offline_user',
        roleId: 3,
        role: 'Branch Manager',
        name: 'Offline User',
      ),
    );

    final mockClient = MockClient((request) async {
      throw http.ClientException('Network connection failed');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          tokenStorage: tokenStorage,
          client: mockClient,
          homeBuilder: (_, user) => Scaffold(
            body: Text('Offline Home for ${user?.name}'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Gracefully transitioned to home with cached profile
    expect(find.text('Offline Home for Offline User'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    // Token should still be preserved
    final savedToken = await tokenStorage.getToken();
    expect(savedToken, equals('test_cached_token'));

    // Cleanup
    await tokenStorage.deleteToken();
    await UserProfileData.clear();
  });
}
