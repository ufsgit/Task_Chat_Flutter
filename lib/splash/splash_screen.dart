import 'dart:async';
import 'package:flutter/material.dart';
import '../bottom_navigator/bottom_navigator.dart';
import '../core/theme.dart';
import '../core/widgets/fitmate_logo.dart';
import '../login_page/login_model.dart';
import '../login_page/login_view.dart';
import '../login_page/token_storage.dart';
import '../settings/settings_model.dart';

/// 1-second splash screen displaying the Fitmate brand logo and typography
/// before verifying the auth token and navigating to HomePage or LoginPage.
class SplashScreen extends StatefulWidget {
  final TokenStorage? tokenStorage;
  final Widget Function(BuildContext, UserModel?)? homeBuilder;

  const SplashScreen({
    super.key,
    this.tokenStorage,
    this.homeBuilder,
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

    // 1-second splash screen delay before checking session
    _timer = Timer(const Duration(seconds: 1), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final tokenStorage = widget.tokenStorage ?? TokenStorage();
    String? token;
    try {
      token = await tokenStorage.getToken();
    } catch (_) {
      token = null;
    }

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      final user = await UserProfileData.loadUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) =>
              widget.homeBuilder != null
                  ? widget.homeBuilder!(ctx, user)
                  : HomePage(
                      isCoordinator: user?.isCoordinator ?? false,
                      user: user,
                    ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      const Text(
                        'Fitmate',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0B192C),
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
                          child: const LinearProgressIndicator(
                            minHeight: 3.5,
                            backgroundColor: Color(0xFFD3F9E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen,
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
