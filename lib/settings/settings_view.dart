import 'package:flutter/material.dart';
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
  final VoidCallback? onEditProfile;

  const SettingsView({
    super.key,
    this.profile,
    this.viewModel,
    this.onLogout,
    this.onAbout,
    this.onEditProfile,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header Card
          ProfileHeaderCard(
            profile: _activeProfile,
            onEdit: widget.onEditProfile ?? () => _handleEditProfile(context),
          ),
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
            subtitle: 'App info, task visibility, status',
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

  void _handleEditProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile edit tapped'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleAbout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final itemBg = isDark
        ? AppDarkColors.surfaceSecondary
        : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF103635)
                            : const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF0D9488),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildAboutRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _activeProfile.email ?? '—',
                        isDark: isDark,
                      ),
                      Divider(color: borderColor, height: 16),
                      _buildAboutRow(
                        icon: Icons.location_on_outlined,
                        label: 'District',
                        value: _activeProfile.districtName ?? '—',
                        isDark: isDark,
                      ),
                      Divider(color: borderColor, height: 16),
                      _buildAboutRow(
                        icon: Icons.map_outlined,
                        label: 'State',
                        value: _activeProfile.stateName ?? '—',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Manage your contacts, customize task visibility, and set your status updates easily in Fitmate.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: subtextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppDarkColors.primaryGreen
                          : AppColors.whatsappGreen,
                      foregroundColor: isDark
                          ? const Color(0xFF06140D)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppDarkColors.primaryGreen : AppColors.primaryGreen,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
