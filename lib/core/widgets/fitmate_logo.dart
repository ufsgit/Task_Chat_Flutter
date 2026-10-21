import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable brand logo widget for Fitmate.
/// Accurately scales the primary green chat bubble and verified badge icon.
class FitmateLogo extends StatelessWidget {
  final double size;

  const FitmateLogo({
    super.key,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    final scale = size / 104.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerBgColor =
        isDark ? AppDarkColors.pillActiveBg : const Color(0xFFD3F9E0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: outerBgColor,
        borderRadius: BorderRadius.circular(30 * scale),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 66 * scale,
          height: 66 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Dark green rounded container with chat bubble
              Container(
                width: 64 * scale,
                height: 64 * scale,
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.primaryGreen : AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(18 * scale),
                ),
                child: Center(
                  child: CustomPaint(
                    size: Size(28 * scale, 26 * scale),
                    painter: ChatBubblePainter(),
                  ),
                ),
              ),

              // Small check badge in bottom-right corner
              Positioned(
                bottom: -2 * scale,
                right: -2 * scale,
                child: Container(
                  width: 24 * scale,
                  height: 24 * scale,
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.primaryGreen : AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: outerBgColor,
                      width: 2.5 * scale,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 13 * scale,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the speech bubble and horizontal messaging lines.
class ChatBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cornerRadius = size.height * (5.0 / 26.0);
    final tailHeight = size.height * (4.0 / 26.0);
    final bubbleHeight = size.height - tailHeight;

    final path = Path();
    // Rounded bubble body
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, bubbleHeight),
        Radius.circular(cornerRadius),
      ),
    );

    // Bottom-left speech bubble tail
    final tailPath = Path()
      ..moveTo(size.width * 0.16, bubbleHeight)
      ..lineTo(size.width * 0.04, size.height)
      ..lineTo(size.width * 0.32, bubbleHeight)
      ..close();
    path.addPath(tailPath, Offset.zero);

    canvas.drawPath(path, bubblePaint);

    // Two rounded horizontal lines inside representing text lines
    final linePaint = Paint()
      ..color = AppColors.primaryGreen
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.height * (2.2 / 26.0);

    // Top text line
    canvas.drawLine(
      Offset(size.width * 0.24, bubbleHeight * 0.38),
      Offset(size.width * 0.76, bubbleHeight * 0.38),
      linePaint,
    );

    // Bottom text line (shorter)
    canvas.drawLine(
      Offset(size.width * 0.24, bubbleHeight * 0.64),
      Offset(size.width * 0.58, bubbleHeight * 0.64),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
