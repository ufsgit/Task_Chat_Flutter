import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable Attach Documents card for Update Status screens.
class AttachDocumentsCard extends StatelessWidget {
  final VoidCallback? onPreview;
  final VoidCallback? onDelete;

  const AttachDocumentsCard({
    super.key,
    this.onPreview,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subtitleText =
        isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle;
    final greenColor =
        isDark ? AppDarkColors.whatsappGreen : const Color(0xFF16A34A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with "Attach Documents" and "1 file attached" badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Attach Documents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F3822)
                    : const Color(0xFFE8FDF2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '1 file attached',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: greenColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Document item container
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppDarkColors.border : AppColors.border,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Red document thumbnail
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF38181A)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF451A1D)
                        : const Color(0xFFFEE2E2),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.description_outlined,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // File title and type/size
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Door_Measurement...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF • 2.4 MB',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: subtitleText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Preview action
              InkWell(
                onTap: onPreview ?? () {},
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: greenColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: greenColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Delete action icon
              InkWell(
                onTap: onDelete ?? () {},
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: isDark
                        ? const Color(0xFF8696A0)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
