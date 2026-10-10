import 'package:flutter/material.dart';
import '../login_page/login_page.dart';
import 'settings_data.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/settings_action_tile.dart';

/// Settings page matching the TaskChat design specification.
class SettingsPage extends StatelessWidget {
  final UserProfileData profile;
  final VoidCallback? onLogout;
  final VoidCallback? onAbout;
  final VoidCallback? onEditProfile;

  const SettingsPage({
    super.key,
    this.profile = defaultUserProfile,
    this.onLogout,
    this.onAbout,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'TaskChat',
          style: TextStyle(
            color: Color(0xFF00A859),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header Card
          ProfileHeaderCard(
            profile: profile,
            onEdit: onEditProfile ?? () => _handleEditProfile(context),
          ),
          const SizedBox(height: 14),

          // 2. About Action Tile
          SettingsActionTile(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF0D9488),
            iconBgColor: const Color(0xFFCCFBF1),
            title: 'About',
            subtitle: 'Block contacts, task visibility, status',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
            onTap: onAbout ?? () => _handleAbout(context),
          ),
          const SizedBox(height: 14),

          // 3. Log out Action Tile
          SettingsActionTile(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBgColor: const Color(0xFFFEE2E2),
            title: 'Log out',
            titleColor: const Color(0xFFDC2626),
            trailing: const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
            onTap: onLogout ?? () => _handleLogout(context),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
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
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF0D9488),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'About & Privacy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage your contacts, customize task visibility, and set your status updates easily in TaskChat.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF036838),
                      foregroundColor: Colors.white,
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of TaskChat?',
            style: TextStyle(
              fontSize: 14.5,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
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
