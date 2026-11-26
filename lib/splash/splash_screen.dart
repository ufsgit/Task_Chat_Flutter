import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../bottom_navigator/bottom_navigator.dart';
import '../core/theme.dart';
import '../core/widgets/fitmate_logo.dart';
import '../login_page/login_model.dart';
import '../login_page/login_view.dart';
import '../login_page/token_storage.dart';
import '../services/notification_service.dart';
import '../settings/settings_model.dart';

/// 1-second splash screen displaying the Fitmate brand logo and typography
/// before verifying the auth token and navigating to HomePage or LoginPage.
class SplashScreen extends StatefulWidget {
  final TokenStorage? tokenStorage;
  final Widget Function(BuildContext, UserModel?)? homeBuilder;
  final http.Client? client;

  const SplashScreen({
    super.key,
    this.tokenStorage,
    this.homeBuilder,
    this.client,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    // Verify session immediately without artificial delay
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final tokenStorage = widget.tokenStorage ?? TokenStorage();
    String? token;
    UserModel? user;

    try {
      final results = await Future.wait([
        tokenStorage
            .getToken()
            .timeout(const Duration(seconds: 2), onTimeout: () => null)
            .catchError((_) => null),
        UserProfileData.loadUser().catchError((_) => null),
      ]);
      token = results[0] as String?;
      user = results[1] as UserModel?;
    } catch (_) {
      token = null;
      user = null;
    }

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      if (user != null) {
        // Cached session exists: open HomePage immediately and revalidate in background
        final navigator = Navigator.of(context);
        unawaited(
          NotificationService.registerDeviceWithBackend(jwtToken: token),
        );
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => widget.homeBuilder != null
                ? widget.homeBuilder!(ctx, user)
                : HomePage(
                    isCoordinator: user?.isCoordinator ?? false,
                    user: user,
                  ),
          ),
        );
        unawaited(
          _validateSessionInBackground(
            token: token,
            tokenStorage: tokenStorage,
            navigator: navigator,
          ),
        );
        return;
      }

      // No cached profile yet: validate session with Checkvalid API before entering HomePage
      final client = widget.client ?? http.Client();
      final isInternalClient = widget.client == null;

      try {
        final authHeader = token.startsWith('Bearer ')
            ? token
            : 'Bearer $token';
        final response = await client
            .get(
              Uri.parse(ApiConfig.Checkvalid),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': authHeader,
              },
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final parsed = _parseCheckvalidResponse(response.body);
          if (parsed.user != null) {
            user = parsed.user;
            await UserProfileData.save(user!);
          }
          if (parsed.refreshedToken != null &&
              parsed.refreshedToken!.isNotEmpty) {
            token = parsed.refreshedToken!;
            await tokenStorage.savetoken(token);
          }

          unawaited(
            NotificationService.registerDeviceWithBackend(jwtToken: token),
          );
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => widget.homeBuilder != null
                  ? widget.homeBuilder!(ctx, user)
                  : HomePage(
                      isCoordinator: user?.isCoordinator ?? false,
                      user: user,
                    ),
            ),
          );
          return;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          await tokenStorage.deleteToken();
          await UserProfileData.clear();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          return;
        }
      } catch (_) {
        // Network offline/timeout with no cached user: fall through to LoginPage
      } finally {
        if (isInternalClient) {
          client.close();
        }
      }
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> _validateSessionInBackground({
    required String token,
    required TokenStorage tokenStorage,
    required NavigatorState navigator,
  }) async {
    final client = widget.client ?? http.Client();
    final isInternalClient = widget.client == null;
    try {
      final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
      final response = await client
          .get(
            Uri.parse(ApiConfig.Checkvalid),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': authHeader,
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final parsed = _parseCheckvalidResponse(response.body);
        if (parsed.user != null) {
          await UserProfileData.save(parsed.user!);
        }
        if (parsed.refreshedToken != null &&
            parsed.refreshedToken!.isNotEmpty) {
          await tokenStorage.savetoken(parsed.refreshedToken!);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await tokenStorage.deleteToken();
        await UserProfileData.clear();
        if (navigator.mounted) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        }
      }
    } catch (_) {
      // Offline / transient error: keep user on HomePage with cached session
    } finally {
      if (isInternalClient) {
        client.close();
      }
    }
  }

  ({UserModel? user, String? refreshedToken}) _parseCheckvalidResponse(
    String body,
  ) {
    if (body.isEmpty) return (user: null, refreshedToken: null);
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return (user: null, refreshedToken: null);
      }
      final userMap = decoded['user'] is Map<String, dynamic>
          ? decoded['user'] as Map<String, dynamic>
          : (decoded['data'] is Map<String, dynamic>
                ? (decoded['data']['user'] is Map<String, dynamic>
                      ? decoded['data']['user'] as Map<String, dynamic>
                      : decoded['data'] as Map<String, dynamic>)
                : decoded);

      UserModel? parsedUser;
      if (userMap.containsKey('id') || userMap.containsKey('username')) {
        parsedUser = UserModel.fromJson(userMap);
      }

      final refreshedToken =
          decoded['sessionToken']?.toString() ??
          decoded['token']?.toString() ??
          decoded['access_token']?.toString() ??
          (decoded['data'] is Map<String, dynamic>
              ? (decoded['data']['sessionToken']?.toString() ??
                    decoded['data']['token']?.toString() ??
                    decoded['data']['access_token']?.toString())
              : null);

      return (user: parsedUser, refreshedToken: refreshedToken);
    } catch (_) {
      return (user: null, refreshedToken: null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppDarkColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated Logo & Title Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fitmate Logo
                      const FitmateLogo(size: 116),
                      const SizedBox(height: 24),

                      // Brand Name
                      Text(
                        'Fitmate',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppDarkColors.textPrimary
                              : AppColors.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Bottom Progress Bar & Version Tag
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth mini progress indicator
                      SizedBox(
                        width: 44,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 3.5,
                            backgroundColor: isDark
                                ? AppDarkColors.pillActiveBg
                                : AppColors.chipPendingBg,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
