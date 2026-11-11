import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/new_lead_service.dart';
import '../theme.dart';

/// In-app floating banner notifying the user that a new lead has been added,
/// giving them a quick action to trigger a refresh or dismiss.
class NewLeadBannerOverlay extends StatefulWidget {
  final Duration autoDismissDuration;

  const NewLeadBannerOverlay({
    super.key,
    this.autoDismissDuration = const Duration(seconds: 6),
  });

  @override
  State<NewLeadBannerOverlay> createState() => _NewLeadBannerOverlayState();
}

class _NewLeadBannerOverlayState extends State<NewLeadBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  NewLeadEvent? _activeEvent;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    NewLeadService.instance.currentEvent.addListener(_onEventChanged);
    _onEventChanged();
  }

  @override
  void dispose() {
    NewLeadService.instance.currentEvent.removeListener(_onEventChanged);
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onEventChanged() {
    final event = NewLeadService.instance.currentEvent.value;
    if (event != null) {
      _dismissTimer?.cancel();
      setState(() {
        _activeEvent = event;
      });
      _animController.forward();
      _dismissTimer = Timer(widget.autoDismissDuration, () {
        _dismiss();
      });
    } else if (_activeEvent != null) {
      _dismiss();
    }
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeEvent = null;
        });
        NewLeadService.instance.dismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeEvent == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2024) : Colors.white;
    final borderColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final primaryGreen = isDark
        ? AppDarkColors.primaryGreen
        : AppColors.primaryGreen;
    final badgeBg = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);

    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dismissible(
              key: ValueKey(_activeEvent!.timestamp),
              direction: DismissDirection.up,
              onDismissed: (_) => _dismiss(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Leading Green Icon Badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 19,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title & Subtitle Info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'New Lead Added',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _activeEvent!.displaySubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Refresh Action Button
                      InkWell(
                        onTap: () {
                          NewLeadService.instance.triggerRefresh();
                          _dismiss();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Refresh',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Dismiss Close Icon
                      InkResponse(
                        onTap: _dismiss,
                        radius: 16,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: subtextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
