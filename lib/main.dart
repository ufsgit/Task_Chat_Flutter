import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/connectivity_service.dart';
import 'core/display_mode_service.dart';
import 'core/theme.dart';
import 'core/widgets/global_connectivity_banner.dart';
import 'services/firebase_options.dart';
import 'services/notification_service.dart';
import 'splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for a pure mobile experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure modern edge-to-edge transparent system overlay for mobile
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.scaffoldBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Mount UI immediately so the splash screen renders instantly on the 1st frame
  runApp(const FitmateApp());

  // Initialize Firebase and notifications asynchronously in the background
  _initServices();
}

Future<void> _initServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    NotificationService.navigatorKey = FitmateApp.navigatorKey;
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('>>> [Services Init Error] $e');
  }

  // Optimize for 120Hz high refresh rate display smoothness
  try {
    await DisplayModeService.enableHighRefreshRate();
  } catch (e) {
    debugPrint('>>> [DisplayMode Init Note] $e');
  }

  // Initialize global internet connectivity listener
  try {
    await ConnectivityService.instance.initialize();
  } catch (e) {
    debugPrint('>>> [ConnectivityService Init Error] $e');
  }
}

class FitmateApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const FitmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'Fitmate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          scrollBehavior: const AppScrollBehavior(),
          builder: (context, child) {
            return GlobalConnectivityBanner(
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
