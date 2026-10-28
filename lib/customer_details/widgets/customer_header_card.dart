import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/widgets/user_circle_avatar.dart';
import '../customer_details_model.dart';

/// Unified Contact Info card displaying customer details in order:
/// 1. Name (Avatar, Name, Inquiry)
/// 2. Address
/// 3. Phone number (with Call & WhatsApp quick actions)
/// 4. Status (Status badge & scheduled date)
/// 5. Note
class CustomerHeaderCard extends StatelessWidget {
  final CustomerDetailsData customer;
  final VoidCallback? onCallTap;
  final VoidCallback? onMessageTap;

  const CustomerHeaderCard({
    super.key,
    required this.customer,
    this.onCallTap,
    this.onMessageTap,
  });

  ({Color bg, Color text, Color dot}) _getBadgeColors(
    String status,
    bool isDark,
  ) {
    return switch (status.toLowerCase().trim()) {
      'completed' => (
        bg: isDark ? AppDarkColors.completedBg : AppColors.completedBg,
        text: isDark ? AppDarkColors.completedText : AppColors.completedText,
        dot: isDark ? AppDarkColors.primaryGreen : AppColors.primaryGreen,
      ),
      'cancelled' => (
        bg: isDark ? AppDarkColors.cancelledBg : AppColors.cancelledBg,
        text: isDark ? AppDarkColors.cancelledText : AppColors.cancelledText,
        dot: isDark ? AppDarkColors.cancelledText : AppColors.cancelledText,
      ),
      'new' => (
        bg: isDark ? AppDarkColors.newBg : AppColors.newBg,
        text: isDark ? AppDarkColors.newText : AppColors.newText,
        dot: isDark ? AppDarkColors.newText : AppColors.newText,
      ),
      'scheduled' || 'in-progress' || 'in progress' => (
        bg: isDark ? AppDarkColors.scheduledBg : AppColors.scheduledBg,
        text: isDark ? AppDarkColors.scheduledText : AppColors.scheduledText,
        dot: isDark ? AppDarkColors.scheduledText : AppColors.scheduledText,
      ),
      _ => (
        bg: isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F9FF),
        text: isDark ? AppDarkColors.primaryGreen : const Color(0xFF0369A1),
        dot: isDark ? AppDarkColors.primaryGreen : AppColors.primaryGreen,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = customer.status;
    final badgeColors = _getBadgeColors(status, colors.isDark);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Name Block (Avatar, Customer Name, Inquiry)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                UserCircleAvatar(
                  size: 50,
                  name: customer.name,
                  status: customer.status,
                ),
                SizedBox(width: 20),
                Center(
                  child: Text(
                    customer.name,
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: colors.border),
          const SizedBox(height: 16),

          // 2. Address Block (direct row without container card)
          _buildAddressSection(context, colors),

          const SizedBox(height: 12),

          // 3. Phone Number Block (right below address)
          _buildPhoneSection(context, colors),

          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: colors.border),
          const SizedBox(height: 16),

          // 4. Status Block (Status Badge & Scheduled Date Badge)
          _buildStatusSection(context, colors, badgeColors),

          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: colors.border),
          const SizedBox(height: 16),

          // 5. Note Block
          _buildNoteSection(context, colors),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, AppThemeColors colors) {
    final hasAddress =
        customer.addressLine1.trim().isNotEmpty ||
        customer.addressLine2.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, color: colors.primaryGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasAddress
                    ? (customer.addressLine1.isNotEmpty
                          ? customer.addressLine1
                          : customer.addressLine2)
                    : 'No address provided',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: hasAddress ? colors.textPrimary : colors.textSubtitle,
                  letterSpacing: -0.1,
                ),
              ),
              if (customer.addressLine1.isNotEmpty &&
                  customer.addressLine2.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  customer.addressLine2,
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: colors.textSubtitle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection(BuildContext context, AppThemeColors colors) {
    final primaryText = colors.textPrimary;
    final subtitleText = colors.textSubtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.phone_outlined, color: colors.primaryGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.phoneNumber.isNotEmpty
                        ? customer.phoneNumber
                        : 'No phone number',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Mobile',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: subtitleText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.call_outlined,
                label: 'Call',
                isPrimary: false,
                onTap:
                    onCallTap ??
                    () {
                      final phone = customer.phoneNumber.isNotEmpty
                          ? customer.phoneNumber
                          : "7089098908";
                      openDialer(phone);
                    },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                image: const AssetImage('assets/images/whatsapp_png.png'),
                icon: Icons.chat_bubble_outline_rounded,
                label: 'WhatsApp',
                isPrimary: false,
                onTap:
                    onMessageTap ??
                    () {
                      final phone = customer.phoneNumber.isNotEmpty
                          ? customer.phoneNumber
                          : "7089098910";
                      openWhatsApp(phone);
                    },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    AppThemeColors colors,
    ({Color bg, Color text, Color dot}) badgeColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textSubtitle,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4.5,
              ),
              decoration: BoxDecoration(
                color: badgeColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: badgeColors.dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    customer.status,
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: badgeColors.text,
                    ),
                  ),
                ],
              ),
            ),
            if (customer.scheduleDate != null &&
                customer.scheduleDate!.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: colors.textSubtitle,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scheduled: ${customer.formattedScheduleDate.isNotEmpty ? customer.formattedScheduleDate : customer.scheduleDate}',
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoteSection(BuildContext context, AppThemeColors colors) {
    final hasNotes = customer.notes.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTES',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textSubtitle,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Text(
            hasNotes ? customer.notes.trim() : 'No notes added',
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: hasNotes ? colors.textPrimary : colors.textSubtitle,
              height: 1.45,
              fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    IconData? icon,
    ImageProvider? image,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color fgColor;
    final Color iconColor;
    final Color borderColor;

    if (isPrimary) {
      bgColor = isDark ? AppDarkColors.whatsappGreen : AppColors.whatsappGreen;
      fgColor = isDark ? const Color(0xFF06140D) : Colors.white;
      iconColor = isDark ? const Color(0xFF06140D) : Colors.white;
      borderColor = Colors.transparent;
    } else {
      bgColor = isDark
          ? AppDarkColors.surfaceSecondary
          : const Color(0xFFF0FDF4);
      fgColor = isDark ? Colors.white : AppColors.primaryGreen;
      iconColor = isDark ? AppDarkColors.whatsappGreen : AppColors.primaryGreen;
      borderColor = isDark ? AppDarkColors.border : const Color(0xFFDCFCE7);
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null)
                Image(
                  image: image,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      icon ?? Icons.chat_bubble_outline_rounded,
                      color: iconColor,
                      size: 20,
                    );
                  },
                )
              else if (icon != null)
                Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias for CustomerHeaderCard
typedef ContactInfoCard = CustomerHeaderCard;

Future<void> openDialer(String phoneNumber) async {
  final trimmed = phoneNumber.trim();
  final numberOnly = trimmed.startsWith('tel:')
      ? trimmed.substring(4)
      : trimmed;
  final cleanNumber = numberOnly.replaceAll(RegExp(r'[^0-9+]'), '');
  final Uri uri = Uri(scheme: 'tel', path: cleanNumber);

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(uri);
    }
  } catch (e) {
    debugPrint('Could not launch dialer: $e');
  }
}

Future<void> openWhatsApp(String phoneNumber) async {
  final trimmed = phoneNumber.trim();

  final numberOnly = trimmed.startsWith('whatsapp:')
      ? trimmed.substring('whatsapp:'.length)
      : trimmed.startsWith('tel:')
      ? trimmed.substring(4)
      : trimmed;

  final cleanNumber = numberOnly.replaceAll(RegExp(r'[^0-9+]'), '');
  var whatsappNumber = cleanNumber.replaceAll('+', '');
  if (whatsappNumber.length == 10) {
    whatsappNumber = '91$whatsappNumber';
  }

  final nativeUri = Uri.parse('whatsapp://send?phone=$whatsappNumber');

  try {
    await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    try {
      final webUri = Uri.parse('https://wa.me/$whatsappNumber');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }
}
