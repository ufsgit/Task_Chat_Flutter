import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/user_circle_avatar.dart';
import '../customer_details_model.dart';

/// Top header card displaying customer name, inquiry type, and status badge.
class CustomerHeaderCard extends StatelessWidget {
  final CustomerDetailsData customer;

  const CustomerHeaderCard({super.key, required this.customer});

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
        bg: isDark ? const Color(0xFF1A334A) : const Color(0xFFE0F2FE),
        text: isDark ? const Color(0xFF53BDEB) : const Color(0xFF0284C7),
        dot: isDark ? const Color(0xFF53BDEB) : const Color(0xFF0284C7),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. WhatsApp-style circular profile avatar
          const UserCircleAvatar(size: 64),
          const SizedBox(height: 12),

          // 2. Customer Name & Status Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  customer.name,
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: badgeColors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: badgeColors.dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: badgeColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // 3. Inquiry Subtitle (Clean WhatsApp about/status style)
          Text(
            customer.inquiry,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: colors.textSubtitle,
            ),
          ),

          if (customer.addressLine1.isNotEmpty ||
              customer.addressLine2.isNotEmpty) ...[
            const SizedBox(height: 18),

            // 4. Address Row (recessed container matching screenshot)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.pillActiveBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: colors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer.addressLine1.isNotEmpty)
                          Text(
                            customer.addressLine1,
                            style: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                        if (customer.addressLine2.isNotEmpty) ...[
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}
