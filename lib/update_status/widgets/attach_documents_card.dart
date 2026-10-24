import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable Attach Documents card for Update Status screens.
class AttachDocumentsCard extends StatelessWidget {
  final List<String>? documents;
  final VoidCallback? onAttach;
  final ValueChanged<String>? onPreview;
  final ValueChanged<String>? onDelete;

  const AttachDocumentsCard({
    super.key,
    this.documents,
    this.onAttach,
    this.onPreview,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final subtitleText = isDark
        ? AppDarkColors.textSubtitle
        : AppColors.textSubtitle;
    final greenColor = isDark
        ? AppDarkColors.whatsappGreen
        : const Color(0xFF16A34A);

    final isDefaultPlaceholder = documents == null;
    final effectiveDocs = documents ?? const ['Door_Measurement...'];
    final showDelete = onDelete != null || isDefaultPlaceholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with "Attach Documents", count badge, and attach action
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (effectiveDocs.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F3822)
                          : const Color(0xFFE8FDF2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${effectiveDocs.length} ${effectiveDocs.length == 1 ? 'file' : 'files'} attached',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: greenColor,
                      ),
                    ),
                  ),
                  if (onAttach != null) const SizedBox(width: 8),
                ],
                if (onAttach != null)
                  InkWell(
                    onTap: onAttach,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: greenColor),
                          const SizedBox(width: 2),
                          Text(
                            'Upload',
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
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (effectiveDocs.isEmpty)
          InkWell(
            onTap: onAttach,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppDarkColors.surfaceCard
                    : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppDarkColors.border : AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.attachment_rounded, size: 20, color: subtitleText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No documents attached',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: subtitleText,
                      ),
                    ),
                  ),
                  if (onAttach != null)
                    Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: greenColor,
                      ),
                    ),
                ],
              ),
            ),
          )
        else ...[
          ...effectiveDocs.map((doc) {
            final fileName = doc.split('/').last.isNotEmpty
                ? doc.split('/').last
                : doc;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppDarkColors.surfaceCard
                    : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppDarkColors.border : AppColors.border,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
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
                  if (onPreview != null || isDefaultPlaceholder)
                    InkWell(
                      onTap: onPreview != null ? () => onPreview!(doc) : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
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
                  if (showDelete)
                    InkWell(
                      onTap: onDelete != null ? () => onDelete!(doc) : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: isDark
                              ? const Color(0xFF8696A0)
                              : const Color.fromARGB(255, 202, 51, 13),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (onAttach != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onAttach,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDarkColors.surfaceSecondary
                      : AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppDarkColors.border
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: greenColor),
                    const SizedBox(width: 6),
                    Text(
                      'Add Document',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: greenColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
