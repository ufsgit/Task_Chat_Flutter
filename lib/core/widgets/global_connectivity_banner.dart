import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../connectivity_service.dart';
import '../theme.dart';
import 'new_lead_in_app_banner.dart';

/// Global wrapper widget that displays a Lottie-animated popup
/// whenever the internet connection is lost, with an option to close or retry.
class GlobalConnectivityBanner extends StatefulWidget {
  final Widget child;

  const GlobalConnectivityBanner({super.key, required this.child});

  @override
  State<GlobalConnectivityBanner> createState() =>
      _GlobalConnectivityBannerState();
}

class _GlobalConnectivityBannerState extends State<GlobalConnectivityBanner> {
  bool _wasOffline = false;
  bool _showRestored = false;
  bool _isDismissed = false;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.isConnected.addListener(
      _onConnectivityChanged,
    );
    _wasOffline = !ConnectivityService.instance.isConnected.value;
  }

  @override
  void dispose() {
    ConnectivityService.instance.isConnected.removeListener(
      _onConnectivityChanged,
    );
    _restoredTimer?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged() {
    final isOnline = ConnectivityService.instance.isConnected.value;
    if (!isOnline) {
      _restoredTimer?.cancel();
      setState(() {
        _wasOffline = true;
        _showRestored = false;
        _isDismissed = false;
      });
    } else if (_wasOffline) {
      // Transition from offline to online: show "Back Online" briefly
      setState(() {
        _wasOffline = false;
        _showRestored = true;
        _isDismissed = false;
      });
      _restoredTimer?.cancel();
      _restoredTimer = Timer(const Duration(seconds: 2, milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showRestored = false;
          });
        }
      });
    }
  }

  void _dismiss() {
    setState(() {
      _isDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isConnected,
      builder: (context, isOnline, _) {
        final isRestored = isOnline && _showRestored;
        final showOfflinePopup = !isOnline && !_isDismissed;
        final showOfflineTopBanner = !isOnline && _isDismissed;

        return Stack(
          children: [
            widget.child,
            if (isRestored) _buildRestoredBanner(context, isDark),
            if (showOfflineTopBanner)
              _buildNoInternetTopBanner(context, isDark),
            if (showOfflinePopup)
              Positioned.fill(
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) =>
                          _buildNoInternetPopup(context, isDark),
                    ),
                  ],
                ),
              ),
            const NewLeadBannerOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildNoInternetTopBanner(BuildContext context, bool isDark) {
    final redColor =
        isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    final cardBg = isDark ? const Color(0xFF1E2024) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2C3038) : const Color(0xFFE2E8F0);

    return Positioned(
      key: const Key('no_internet_top_banner'),
      top: 10,
      left: 12,
      right: 12,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              ConnectivityService.instance.checkConnection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 16,
                    color: redColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: redColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoredBanner(BuildContext context, bool isDark) {
    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14532D) : const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Back Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoInternetPopup(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E2024) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2C3038)
        : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final primaryGreen = isDark
        ? AppDarkColors.primaryGreen
        : AppColors.primaryGreen;

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkResponse(
                      onTap: _dismiss,
                      radius: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: subtextColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // Center: Lottie Animation (No Mobile Internet) or Icon in tests
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: ConnectivityService.isTestEnvironment
                      ? const Icon(
                          Icons.wifi_off_rounded,
                          size: 80,
                          color: Color(0xFFEF4444),
                        )
                      : Lottie.asset(
                          'assets/animations/No Mobile Internet.json',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.wifi_off_rounded,
                            size: 80,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                  // Title & Subtitle
                  Text(
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please check your network settings and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: subtextColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions: Close & Retry Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: _dismiss,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: subtextColor,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () {
                              ConnectivityService.instance.checkConnection();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
