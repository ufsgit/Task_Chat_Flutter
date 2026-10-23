import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Documents section card displaying attached files for the customer.
class CustomerDocumentsCard extends StatelessWidget {
  final List<String> documents;
  final VoidCallback? onUpload;
  final ValueChanged<String>? onView;

  const CustomerDocumentsCard({
    super.key,
    this.documents = const [],
    this.onUpload,
    this.onView,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Documents" and "+ Upload"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (documents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No documents attached',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: subtitleText,
                ),
              ),
            )
          else
            ...documents.map((doc) {
              final fileName = doc.split('/').last.isNotEmpty
                  ? doc.split('/').last
                  : doc;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDarkColors.surfaceSecondary
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppDarkColors.border
                        : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Row(
                  children: [
                    // File icon thumbnail
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF38161A)
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

                    // File name & size/meta
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
                            '2.4 MB • Updated yesterday',
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
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
