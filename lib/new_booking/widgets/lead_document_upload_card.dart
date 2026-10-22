import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'lead_form_card.dart';

/// Reusable UI widget for the document upload option in New Booking.
/// Provides a list of attached documents and a dashed upload area with file format guidance.
class LeadDocumentUploadCard extends StatelessWidget {
  final List<String> documents;
  final VoidCallback? onTap;
  final ValueChanged<String>? onRemove;

  const LeadDocumentUploadCard({
    super.key,
    this.documents = const [],
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : const Color(0xFF0F172A);
    final subtitleColor = isDark
        ? AppDarkColors.textPlaceholder
        : const Color(0xFF94A3B8);
    final badgeBgColor = isDark
        ? const Color(0xFF2E2E34)
        : const Color(0xFFF1F5F9);
    final badgeTextColor = isDark
        ? AppDarkColors.textSubtitle
        : const Color(0xFF64748B);
    final uploadBoxBg = isDark
        ? const Color(0xFF222227)
        : const Color(0xFFF8FAFC);
    final dotBorderColor = isDark
        ? const Color(0xFF71717A)
        : const Color.fromARGB(255, 104, 97, 97);

    return LeadFormCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with "Attach Documents" and count or "Max 10MB" badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Attach Documents',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Max 10MB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attached documents list
          if (documents.isNotEmpty) ...[
            ...documents.map((doc) {
              final fileName = doc.split('/').last;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: uploadBoxBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            doc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: subtitleColor,
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => onRemove!(doc),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],

          // Dotted upload drop/tap zone
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: uploadBoxBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: _DottedRRectPainter(
                    color: dotBorderColor,
                    dotRadius: 0.5,
                    spacing: 8.0,
                    radius: 12.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Tap to browse or upload file',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supports PDF, DOCX, PNG, or JPG',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw a dotted rounded rectangle border.
class _DottedRRectPainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;
  final double radius;

  _DottedRRectPainter({
    required this.color,
    this.dotRadius = 2.0,
    this.spacing = 7.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= dotRadius * 2 || size.height <= dotRadius * 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            dotRadius + 0.5,
            dotRadius + 0.5,
            size.width - (dotRadius + 0.5) * 2,
            size.height - (dotRadius + 0.5) * 2,
          ),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, dotRadius, paint);
        }
        distance += spacing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}
