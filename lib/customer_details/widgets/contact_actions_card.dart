import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../customer_details_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card containing customer contact phone, quick call/message action buttons,
/// and editable notes & interaction history.
class ContactActionsCard extends StatefulWidget {
  final CustomerDetailsData customer;
  final VoidCallback? onCallTap;
  final VoidCallback? onMessageTap;

  const ContactActionsCard({
    super.key,
    required this.customer,
    this.onCallTap,
    this.onMessageTap,
  });

  @override
  State<ContactActionsCard> createState() => _ContactActionsCardState();
}

class _ContactActionsCardState extends State<ContactActionsCard> {
  late final TextEditingController _notesController;
  final FocusNode _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.customer.notes);
  }

  @override
  void didUpdateWidget(covariant ContactActionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer.notes != widget.customer.notes &&
        _notesController.text != widget.customer.notes) {
      _notesController.text = widget.customer.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryText = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final subtitleText = isDark
        ? AppDarkColors.textSubtitle
        : AppColors.textSubtitle;
    final iconBgColor = isDark
        ? AppDarkColors.pillActiveBg
        : const Color(0xFFE7FCE3);
    final iconFgColor = isDark
        ? AppDarkColors.whatsappGreen
        : AppColors.primaryGreen;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Contact Phone Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.phone_outlined, color: iconFgColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.phoneNumber,
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Mobile',
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: subtitleText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. WhatsApp Quick Action Buttons (Call & Message)
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.call_outlined,
                  label: 'Call',
                  isPrimary: false,
                  onTap: () {
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
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  isPrimary: true,
                  onTap:
                      widget.onMessageTap ??
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

          const SizedBox(height: 18),

          // 3. Notes & Interaction History Section
          Text(
            'NOTES',
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppDarkColors.textPlaceholder
                  : AppColors.textSubtitle,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),

          // Clean Note Container matching screenshot
          GestureDetector(
            onTap: () => _notesFocusNode.requestFocus(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppDarkColors.surfaceSecondary
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppDarkColors.border : AppColors.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                maxLines: null,
                minLines: 3,
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: primaryText,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: 'Add notes or client details...',
                  hintStyle: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppDarkColors.textPlaceholder
                        : AppColors.textPlaceholder,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
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
              Icon(icon, color: iconColor, size: 18),
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
  //final webUri = Uri.parse('https://wa.me/$whatsappNumber');

  try {
    await launchUrl(
      nativeUri,
      mode: LaunchMode.externalApplication,
    );
    // if (!launched) {
    //   await launchUrl(webUri, mode: LaunchMode.externalApplication);
    // }
  } catch (_) {
    try {
      // final launchedWeb = await launchUrl(
      //   webUri,
      //   mode: LaunchMode.externalApplication,
      // );
      // if (!launchedWeb) {
      //   await launchUrl(webUri);
      // }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }
}
