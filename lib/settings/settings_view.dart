import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme.dart';
import '../core/widgets/fitmate_app_bar_title.dart';
import '../login_page/login_view.dart';
import 'settings_model.dart';
import 'settings_view_model.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/settings_action_tile.dart';

/// Settings view matching the Fitmate MVVM architecture.
class SettingsView extends StatefulWidget {
  final UserProfileData? profile;
  final SettingsViewModel? viewModel;
  final VoidCallback? onLogout;
  final VoidCallback? onAbout;

  const SettingsView({
    super.key,
    this.profile,
    this.viewModel,
    this.onLogout,
    this.onAbout,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

/// Backwards-compatible alias for existing callers.
typedef SettingsPage = SettingsView;

class _SettingsViewState extends State<SettingsView> {
  late final SettingsViewModel _viewModel;
  bool _isLocalViewModel = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      if (widget.profile != null) {
        _viewModel.setProfile(widget.profile!);
      }
    } else {
      _viewModel = SettingsViewModel(initialProfile: widget.profile);
      _isLocalViewModel = true;
      if (widget.profile == null) {
        _viewModel.loadProfile();
      }
    }
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != null && widget.profile != oldWidget.profile) {
      _viewModel.setProfile(widget.profile!);
    }
  }

  @override
  void dispose() {
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  UserProfileData get _activeProfile => _viewModel.activeProfile;

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        toolbarHeight: 68,
        title: const FitmateAppBarTitle(),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header Card
          ProfileHeaderCard(profile: _activeProfile),
          const SizedBox(height: 14),

          // 2. WhatsApp Theme Action Tile
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance.themeModeNotifier,
            builder: (context, mode, child) {
              return SettingsActionTile(
                icon: Icons.brightness_6_outlined,
                iconColor: isDark
                    ? AppDarkColors.primaryGreen
                    : AppColors.primaryGreen,
                iconBgColor: isDark
                    ? AppDarkColors.chipPendingBg
                    : const Color(0xFFE7FCE3),
                title: 'Theme',
                subtitle: ThemeController.instance.themeModeLabel,
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF8696A0)
                      : const Color(0xFF94A3B8),
                  size: 24,
                ),
                onTap: () => showWhatsAppThemeDialog(context),
              );
            },
          ),
          const SizedBox(height: 14),

          // 3. About Action Tile
          SettingsActionTile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF0D9488),
            iconBgColor: isDark
                ? const Color(0xFF103635)
                : const Color(0xFFCCFBF1),
            title: 'About',
            subtitle: 'Account info, App version',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF94A3B8),
              size: 24,
            ),
            onTap: widget.onAbout ?? () => _handleAbout(context),
          ),
          const SizedBox(height: 14),

          // 4. Log out Action Tile
          SettingsActionTile(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBgColor: isDark
                ? const Color(0xFF38181A)
                : const Color(0xFFFEE2E2),
            title: 'Log out',
            titleColor: const Color(0xFFDC2626),
            trailing: const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
            onTap: widget.onLogout ?? () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  static String? _cachedVersion;

  Future<String> _getAppVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      if (version.isNotEmpty && build.isNotEmpty) {
        _cachedVersion = '$version+$build';
      } else if (version.isNotEmpty) {
        _cachedVersion = version;
      } else {
        _cachedVersion = '1.0.0+1';
      }
      return _cachedVersion!;
    } catch (_) {
      return '1.0.0+1';
    }
  }

  void _handleAbout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final cardBg = isDark
        ? AppDarkColors.surfaceSecondary
        : const Color(0xFFFFFFFF);
    final borderColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final fitmateGreen = isDark
        ? AppDarkColors.primaryGreen
        : AppColors.primaryGreen;
    final iconBg = isDark ? const Color(0xFF122E23) : const Color(0xFFE8F7EC);
    final versionCardBg = isDark
        ? const Color(0xFF122820)
        : const Color(0xFFEDF8F1);
    final versionBorderColor = isDark
        ? const Color(0xFF1E4534)
        : const Color(0xFFD4EEDC);
    final versionLabelColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF334155);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: dialogBg,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: About Us Title & Subtitle + Close Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Us',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your application details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: subtextColor,
                        splashRadius: 18,
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Individual Cards per Attribute matching Screenshot Design
                  _buildDetailCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    value: _activeProfile.name.isNotEmpty
                        ? _activeProfile.name
                        : '—',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    labelColor: subtextColor,
                    valueColor: titleColor,
                    iconBg: iconBg,
                    iconFg: fitmateGreen,
                  ),
                  const SizedBox(height: 8),

                  _buildDetailCard(
                    icon: Icons.phone_outlined,
                    label: 'Mobile Number',
                    value: _activeProfile.phone.isNotEmpty
                        ? _activeProfile.phone
                        : '—',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    labelColor: subtextColor,
                    valueColor: titleColor,
                    iconBg: iconBg,
                    iconFg: fitmateGreen,
                  ),
                  const SizedBox(height: 8),

                  _buildDetailCard(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email Address',
                    value: _activeProfile.email ?? '—',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    labelColor: subtextColor,
                    valueColor: titleColor,
                    iconBg: iconBg,
                    iconFg: fitmateGreen,
                  ),
                  const SizedBox(height: 8),

                  if (_activeProfile.role != null &&
                      _activeProfile.role!.isNotEmpty) ...[
                    _buildDetailCard(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: _activeProfile.role!,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      labelColor: subtextColor,
                      valueColor: titleColor,
                      iconBg: iconBg,
                      iconFg: fitmateGreen,
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildDetailCard(
                    icon: Icons.location_on_outlined,
                    label: 'District',
                    value: _activeProfile.districtName ?? '—',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    labelColor: subtextColor,
                    valueColor: titleColor,
                    iconBg: iconBg,
                    iconFg: fitmateGreen,
                  ),
                  const SizedBox(height: 8),

                  _buildDetailCard(
                    icon: Icons.map_outlined,
                    label: 'State',
                    value: _activeProfile.stateName ?? '—',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    labelColor: subtextColor,
                    valueColor: titleColor,
                    iconBg: iconBg,
                    iconFg: fitmateGreen,
                  ),
                  const SizedBox(height: 10),

                  // 3. Application Version Card (Tinted Card at bottom)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: versionCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: versionBorderColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Application Version',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: versionLabelColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<String>(
                          future: _getAppVersion(),
                          builder: (context, snapshot) {
                            final versionText =
                                snapshot.data ?? _cachedVersion ?? '1.0.0+1';
                            return Text(
                              versionText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: fitmateGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Close Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fitmateGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color cardBg,
    required Color borderColor,
    required Color labelColor,
    required Color valueColor,
    required Color iconBg,
    required Color iconFg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: labelColor,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    letterSpacing: -0.2,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppDarkColors.surfaceCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Log out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Are you sure you want to log out of Fitmate?',
            style: TextStyle(
              fontSize: 14.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _viewModel.logout();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}
