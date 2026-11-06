import 'dart:async';
import 'package:flutter/material.dart';
import '../connectivity_service.dart';

/// Global wrapper widget that displays a non-intrusive animated banner
/// at the top of the screen whenever the internet connection is lost.
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
      });
    } else if (_wasOffline) {
      // Transition from offline to online: show "Back Online" briefly
      setState(() {
        _wasOffline = false;
        _showRestored = true;
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isConnected,
      builder: (context, isOnline, _) {
        final showBanner = !isOnline || _showRestored;
        final isRestored = isOnline && _showRestored;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isRestored
            ? (isDark ? const Color(0xFF14532D) : const Color(0xFF16A34A))
            : (isDark ? const Color(0xFF991B1B) : const Color(0xFFDC2626));

        final message = isRestored ? 'Back Online' : 'No Internet Connection';

        final icon = isRestored
            ? Icons.check_circle_rounded
            : Icons.wifi_off_rounded;

        return Stack(
          children: [
            widget.child,

            // Floating Top Banner
            Positioned(
              top: 7,
              left: 5,
              right: 5,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: showBanner
                    ? Material(
                        color: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: bgColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            bottom: false,
                            minimum: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isRestored) ...[
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () {
                                      ConnectivityService.instance
                                          .checkConnection();
                                    },
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Retry',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
