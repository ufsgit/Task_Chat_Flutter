import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../customer_details/customer_details_model.dart';
import '../customer_details/customer_details_view.dart';
import '../login_page/token_storage.dart';
import '../today/today_view_model.dart';
import 'new_lead_service.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
/// Must be outside of any class and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('>>> [FCM Background] Message ID: ${message.messageId}');
  debugPrint('>>> [FCM Background] Title: ${message.notification?.title}');
  debugPrint('>>> [FCM Background] Body: ${message.notification?.body}');
  debugPrint('>>> [FCM Background] Data: ${message.data}');
}

/// Service class to manage Firebase Cloud Messaging permissions,
/// tokens, notification message streams, and backend registration.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Cached device FCM token.
  static String? fcmToken;

  /// Optional navigator key for displaying foreground in-app toasts/alerts and routing.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Pending customer model waiting to be navigated to when root UI is ready.
  static CustomerDetailsModel? pendingCustomer;

  /// Checks if the current target platform supports Firebase Cloud Messaging.
  /// (Supported: Android, iOS, macOS, Web. Unsupported: Windows Desktop, Linux).
  static bool get isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Retrieves or generates a persistent device installation ID.
  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('fitmate_device_id');
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = 'fitmate-${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('fitmate_device_id', deviceId);
      }
      return deviceId;
    } catch (_) {
      return 'Error finding device id';
    }
  }

  /// Returns the current device type string ('android', 'ios', 'web', etc.).
  static String getDeviceType() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      default:
        return 'android';
    }
  }

  /// Initializes Firebase Cloud Messaging:
  /// 1. Verifies platform support (bypasses Windows desktop safely).
  /// 2. Registers background message handler.
  /// 3. Sets iOS foreground presentation options.
  /// 4. Requests notification permissions (required for Android 13+ & iOS).
  /// 5. Registers device and retrieves FCM token for test pushes.
  /// 6. Listens for foreground push messages and shows in-app banner toast.
  /// 7. Automatically registers token with backend if user is already logged in.
  static Future<void> initialize() async {
    if (!isSupportedPlatform) {
      debugPrint(
        '>>> [FCM] Push notifications are not supported on ${defaultTargetPlatform.name} desktop. Skipping FCM setup.',
      );
      return;
    }

    try {
      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Configure foreground notification presentation (iOS)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // 2. Request user permissions (crucial for Android 13+ POST_NOTIFICATIONS and iOS)
      final NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      debugPrint(
        '>>> [FCM] Notification authorization status: ${settings.authorizationStatus}',
      );

      // 3. Listen for token/registration events
      FirebaseMessaging.instance.onRegistered.listen((String token) {
        fcmToken = token;
        _logFcmToken(token, source: 'onRegistered');
        unawaited(registerDeviceWithBackend());
      });

      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
        fcmToken = token;
        _logFcmToken(token, source: 'onTokenRefresh');
        unawaited(registerDeviceWithBackend());
      });

      // 4. Fetch token & register instance
      try {
        final isTest = TokenStorage.isTestEnvironment;
        // ignore: deprecated_member_use
        final directToken = await FirebaseMessaging.instance.getToken().timeout(
          isTest
              ? const Duration(milliseconds: 50)
              : const Duration(seconds: 15),
          onTimeout: () => null,
        );
        if (directToken != null) {
          fcmToken = directToken;
          _logFcmToken(directToken, source: 'getToken');
        }
      } catch (e) {
        debugPrint('>>> [FCM] Direct token fetch note: $e');
      }

      try {
        final isTest = TokenStorage.isTestEnvironment;
        await FirebaseMessaging.instance.register().timeout(
          isTest
              ? const Duration(milliseconds: 50)
              : const Duration(seconds: 10),
          onTimeout: () {},
        );
      } catch (e) {
        debugPrint('>>> [FCM] Register note: $e');
      }

      // 5. Automatically register device token with backend if user has an active session
      unawaited(registerDeviceWithBackend());

      // 6. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title =
            message.notification?.title ??
            message.data['title']?.toString() ??
            'Fitmate Notification';
        final body =
            message.notification?.body ??
            message.data['body']?.toString() ??
            message.data['message']?.toString() ??
            '';

        debugPrint('>>> [FCM Foreground] Received: $title - $body');
        debugPrint('>>> [FCM Foreground] Data payload: ${message.data}');

        final bool isLead = isNewLeadNotification(message);
        if (isLead) {
          // Silently refresh active lists in background without showing in-app banner
          NewLeadService.instance.triggerRefresh();
        }
        // In-app notifications are stopped for now
      });

      // 7. Handle notification click when app launched from terminated state
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '>>> [FCM] App opened from terminated state via notification: ${initialMessage.messageId}',
        );
        unawaited(handleNotificationClick(initialMessage, isInitial: true));
      }

      // 8. Handle notification click when app opened from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '>>> [FCM] App opened from background state via notification: ${message.messageId}',
        );
        unawaited(handleNotificationClick(message, isInitial: false));
      });
    } on MissingPluginException catch (e) {
      debugPrint(
        '>>> [FCM Setup Note] MissingPluginException: The native FCM plugin is not yet compiled into the running app ($e).',
      );
      debugPrint(
        '>>> [FCM Fix] Please completely STOP the app and run a fresh "flutter run" so Gradle compiles the new native Android plugin.',
      );
    } catch (e, stackTrace) {
      debugPrint('>>> [FCM Error] Failed to initialize notifications: $e');
      debugPrint('$stackTrace');
    }
  }

  /// Checks whether notifications are currently authorized by the user.
  static Future<bool> isPermissionGranted() async {
    if (!isSupportedPlatform) return false;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Explicitly requests notification permissions from the user.
  static Future<NotificationSettings> requestPermission() async {
    return FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Checks whether a [RemoteMessage] represents a new lead or new booking notification.
  static bool isNewLeadNotification(RemoteMessage message) {
    final type =
        (message.data['type'] ??
                message.data['action_type'] ??
                message.data['event'])
            ?.toString()
            .toLowerCase();
    if (type != null) {
      if (type.contains('lead') ||
          type.contains('booking') ||
          type.contains('new')) {
        return true;
      }
    }

    final title = (message.notification?.title ?? message.data['title'] ?? '')
        .toString()
        .toLowerCase();
    final body =
        (message.notification?.body ??
                message.data['body'] ??
                message.data['message'] ??
                '')
            .toString()
            .toLowerCase();

    return title.contains('lead') ||
        title.contains('booking') ||
        body.contains('lead') ||
        body.contains('booking') ||
        body.contains('created') ||
        body.contains('assigned');
  }

  /// Parses or builds a [CustomerDetailsModel] from a [RemoteMessage].
  static CustomerDetailsModel? parseCustomerFromMessage(RemoteMessage message) {
    return parseCustomerFromData(
      message.data,
      notification: message.notification,
    );
  }

  /// Parses or builds a [CustomerDetailsModel] from raw notification data and optional [RemoteNotification].
  static CustomerDetailsModel? parseCustomerFromData(
    Map<String, dynamic> data, {
    RemoteNotification? notification,
  }) {
    // 1. Check for booking ID
    String? bookingId =
        (data['bookingId'] ??
                data['booking_id'] ??
                data['bookingID'] ??
                data['id'] ??
                data['booking'])
            ?.toString();

    // If bookingId is not in data, try extracting "#1234" from title, body or message
    if (bookingId == null || bookingId.isEmpty) {
      final textToScan =
          '${notification?.title ?? ''} ${notification?.body ?? ''} ${data['message'] ?? ''}';
      final match = RegExp(r'#(\d+)').firstMatch(textToScan);
      if (match != null) {
        bookingId = match.group(1);
      }
    }

    // 2. Try matching an existing booking cached in TodayViewModel
    if (bookingId != null && bookingId.isNotEmpty) {
      final todayBookings = TodayViewModel.currentSession?.bookings;
      if (todayBookings != null) {
        for (final b in todayBookings) {
          if (b.id.toString() == bookingId) {
            return CustomerDetailsModel.fromBooking(b);
          }
        }
      }
    }

    // 3. Check for customer name
    final name =
        (data['customerName'] ??
                data['customer_name'] ??
                data['clientName'] ??
                data['client_name'] ??
                data['booking_name'] ??
                data['name'] ??
                data['title'] ??
                notification?.title)
            ?.toString();

    // If both bookingId and name are empty, we cannot identify the booking
    if ((bookingId == null || bookingId.isEmpty) &&
        (name == null || name.isEmpty)) {
      return null;
    }

    final payload = Map<String, dynamic>.from(data);
    if (bookingId != null) payload['bookingId'] = bookingId;
    if (name != null) payload['name'] = name;
    if (notification?.body != null && !data.containsKey('notes')) {
      payload['notes'] = notification!.body;
    }

    return CustomerDetailsModel.fromNotificationData(payload);
  }

  /// Navigates to the booking details page for the given [CustomerDetailsModel].
  static Future<void> navigateToBooking(
    CustomerDetailsModel customer, {
    BuildContext? context,
  }) async {
    final nav = context != null
        ? Navigator.of(context)
        : navigatorKey?.currentState;

    if (nav == null) {
      debugPrint(
        '>>> [FCM Navigation] Navigator is not ready yet. Queuing booking #${customer.id}.',
      );
      pendingCustomer = customer;
      return;
    }

    debugPrint(
      '>>> [FCM Navigation] Navigating to CustomerDetailsPage for booking #${customer.id} (${customer.name}).',
    );
    pendingCustomer = null;

    try {
      nav.push(
        MaterialPageRoute(
          builder: (_) => CustomerDetailsPage(customer: customer),
        ),
      );
    } catch (e) {
      debugPrint('>>> [FCM Navigation Error] $e');
    }
  }

  /// Checks if there is a pending customer navigation and executes it if the navigator is available.
  static Future<void> checkAndNavigatePending([BuildContext? context]) async {
    final customer = pendingCustomer;
    if (customer != null) {
      pendingCustomer = null;
      await navigateToBooking(customer, context: context);
    }
  }

  /// Handles when a user taps a push notification outside the app (background or terminated state).
  static Future<void> handleNotificationClick(
    RemoteMessage message, {
    bool isInitial = false,
  }) async {
    debugPrint(
      '>>> [FCM Click] Notification tapped! ID: ${message.messageId}, isInitial: $isInitial',
    );
    debugPrint('>>> [FCM Click] Payload data: ${message.data}');

    final customer = parseCustomerFromMessage(message);
    if (customer == null) {
      debugPrint(
        '>>> [FCM Click] No booking details found in notification payload.',
      );
      return;
    }

    if (isInitial) {
      pendingCustomer = customer;
      if (navigatorKey?.currentState != null) {
        await checkAndNavigatePending();
      }
    } else {
      await navigateToBooking(customer);
    }
  }

  static bool _isRegisteringDevice = false;
  static String? _lastRegisteredToken;
  static String? _lastRegisteredJwt;

  /// Registers the device with the backend for push notifications:
  /// POST /api/notifications/device-token
  /// Headers: Authorization: Bearer `<JWT_TOKEN>`
  /// Body: { "fcmToken": "...", "deviceType": "android", "deviceId": "..." }
  static Future<bool> registerDeviceWithBackend({
    String? jwtToken,
    http.Client? client,
  }) async {
    if (_isRegisteringDevice) {
      debugPrint(
        '>>> [FCM Backend] Registration already in progress. Skipping duplicate call.',
      );
      return true;
    }
    _isRegisteringDevice = true;

    try {
      final token = jwtToken ?? await TokenStorage().getToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint(
          '>>> [FCM Backend] Skipping register: user is not logged in.',
        );
        return false;
      }

      var tokenToRegister = fcmToken;
      if ((tokenToRegister == null || tokenToRegister.isEmpty) &&
          isSupportedPlatform) {
        try {
          final isTest = TokenStorage.isTestEnvironment;
          // ignore: deprecated_member_use
          tokenToRegister = await FirebaseMessaging.instance.getToken().timeout(
            isTest
                ? const Duration(milliseconds: 50)
                : const Duration(seconds: 15),
            onTimeout: () => null,
          );
          if (tokenToRegister != null) {
            fcmToken = tokenToRegister;
          }
        } catch (_) {}
      }

      if (tokenToRegister == null || tokenToRegister.isEmpty) {
        debugPrint(
          '>>> [FCM Backend] Skipping register: FCM device token is not available yet.',
        );
        return false;
      }

      if (tokenToRegister == _lastRegisteredToken &&
          token == _lastRegisteredJwt &&
          client == null) {
        debugPrint(
          '>>> [FCM Backend] Device already registered with current tokens. Skipping duplicate POST.',
        );
        return true;
      }

      final deviceId = await getDeviceId();
      final deviceType = getDeviceType();

      final httpClient = client ?? http.Client();
      try {
        final url = Uri.parse(ApiConfig.notificationDeviceToken);
        final payload = jsonEncode({
          'fcmToken': tokenToRegister,
          'deviceToken': tokenToRegister,
          'device_token': tokenToRegister,
          'fcm_token': tokenToRegister,
          'token': tokenToRegister,
          'deviceType': deviceType,
          'device_type': deviceType,
          'platform': deviceType,
          'deviceId': deviceId,
          'device_id': deviceId,
        });

        debugPrint('>>> [FCM Backend] Registering device token: $url');
        debugPrint('>>> [FCM Backend] Payload: $payload');

        final authHeader = token.startsWith('Bearer ')
            ? token
            : 'Bearer $token';

        final response = await httpClient
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': authHeader,
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 8));

        debugPrint(
          '<<< [FCM Backend] Register Response (${response.statusCode}): ${response.body}',
        );
        final success = response.statusCode >= 200 && response.statusCode < 300;
        if (success) {
          _lastRegisteredToken = tokenToRegister;
          _lastRegisteredJwt = token;
        }
        return success;
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }
    } catch (e) {
      debugPrint('>>> [FCM Backend] Error registering device: $e');
      return false;
    } finally {
      _isRegisteringDevice = false;
    }
  }

  /// Unregisters the device from the backend on logout:
  /// POST /api/notifications/unregister
  /// Headers: Authorization: Bearer `<JWT_TOKEN>`
  /// Body: { "fcmToken": "..." }
  static Future<bool> unregisterDeviceFromBackend({
    String? jwtToken,
    http.Client? client,
  }) async {
    _lastRegisteredToken = null;
    _lastRegisteredJwt = null;
    try {
      final token = jwtToken ?? await TokenStorage().getToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint(
          '>>> [FCM Backend] Skipping unregister: no JWT token available.',
        );
        return false;
      }

      final tokenToUnregister = fcmToken;
      if (tokenToUnregister == null || tokenToUnregister.isEmpty) {
        debugPrint(
          '>>> [FCM Backend] Skipping unregister: no FCM token available.',
        );
        return false;
      }

      final httpClient = client ?? http.Client();
      try {
        final authHeader = token.startsWith('Bearer ')
            ? token
            : 'Bearer $token';

        final url = Uri.parse(ApiConfig.notificationUnregister);
        final payload = jsonEncode({
          'fcmToken': tokenToUnregister,
          'deviceToken': tokenToUnregister,
          'device_token': tokenToUnregister,
          'fcm_token': tokenToUnregister,
          'token': tokenToUnregister,
        });

        debugPrint('>>> [FCM Backend] Unregistering device: $url');
        debugPrint('>>> [FCM Backend] Payload: $payload');

        final response = await httpClient
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': authHeader,
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 8));

        debugPrint(
          '<<< [FCM Backend] Unregister Response (${response.statusCode}): ${response.body}',
        );
        return response.statusCode >= 200 && response.statusCode < 300;
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }
    } catch (e) {
      debugPrint('>>> [FCM Backend] Error unregistering device: $e');
      return false;
    }
  }

  /// Prominently displays the FCM token in the debug console for easy copying.
  static void _logFcmToken(String? token, {String source = 'Token'}) {
    if (token == null || token.isEmpty) {
      debugPrint(
        '>>> [FCM] Unable to retrieve FCM token at this moment ($source).',
      );
      return;
    }
    debugPrint(
      '\n==================== FCM DEVICE TOKEN ($source) ====================',
    );
    debugPrint(token);
    debugPrint(
      '======================================================================\n',
    );
  }
}
