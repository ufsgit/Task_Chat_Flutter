// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate app logo PNGs', () async {
    // 1. Generate app_logo.png (1024x1024) with #D3F9E0 background
    final fullLogoBytes = await _renderLogoImage(
      size: 1024,
      drawBackground: true,
      scale: 1.0,
    );
    final file1 = File('assets/images/app_logo.png');
    await file1.parent.create(recursive: true);
    await file1.writeAsBytes(fullLogoBytes);
    print('Generated ${file1.path} (${file1.lengthSync()} bytes)');

    // 2. Generate app_logo_foreground.png (1024x1024) transparent background, scaled for Android adaptive icon safe zone
    final foregroundBytes = await _renderLogoImage(
      size: 1024,
      drawBackground: false,
      scale: 0.65, // 65% ensures it stays well inside the safe zone (66% circle)
    );
    final file2 = File('assets/images/app_logo_foreground.png');
    await file2.writeAsBytes(foregroundBytes);
    print('Generated ${file2.path} (${file2.lengthSync()} bytes)');
  });
}

Future<List<int>> _renderLogoImage({
  required double size,
  required bool drawBackground,
  required double scale,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  const primaryGreen = Color(0xFF16A34A);
  const mintGreen = Color(0xFFD3F9E0);

  if (drawBackground) {
    final bgPaint = Paint()..color = mintGreen;
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);
  }

  // Canvas center
  final center = Offset(size / 2, size / 2);

  // Base design dimensions:
  // Base outer container = 104
  // Dark green container = 64
  // Chat bubble size = 28 x 26
  // Check badge = 24, center offset = (23, 23) from center of 64x64
  // We apply `scale` to fit within canvas:
  // When scale = 1.0, let 104 units correspond to size * 0.82
  final baseUnit = (size * 0.82 * scale) / 104.0;

  // Dark green container: 64 x 64
  final darkSquareSize = 64.0 * baseUnit;
  final darkSquareRadius = 18.0 * baseUnit;
  final darkSquareRect = Rect.fromCenter(
    center: center,
    width: darkSquareSize,
    height: darkSquareSize,
  );

  // Subtle shadow for dark square if background is drawn
  if (drawBackground) {
    final shadowPaint = Paint()
      ..color = primaryGreen.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        darkSquareRect.shift(Offset(0, 6 * baseUnit)),
        Radius.circular(darkSquareRadius),
      ),
      shadowPaint,
    );
  }

  final darkSquarePaint = Paint()..color = primaryGreen;
  canvas.drawRRect(
    RRect.fromRectAndRadius(darkSquareRect, Radius.circular(darkSquareRadius)),
    darkSquarePaint,
  );

  // Chat bubble inside dark square
  final bubbleWidth = 28.0 * baseUnit;
  final bubbleHeightTotal = 26.0 * baseUnit;
  final tailHeight = 4.0 * baseUnit;
  final bubbleBodyHeight = bubbleHeightTotal - tailHeight;
  final bubbleCornerRadius = 5.0 * baseUnit;

  // Top-left of chat bubble centered inside dark square
  final bubbleLeft = center.dx - (bubbleWidth / 2);
  final bubbleTop = center.dy - (bubbleHeightTotal / 2);

  final bubblePaint = Paint()..color = Colors.white;
  final bubblePath = Path();
  bubblePath.addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleWidth, bubbleBodyHeight),
      Radius.circular(bubbleCornerRadius),
    ),
  );

  // Tail
  final tailPath = Path()
    ..moveTo(bubbleLeft + bubbleWidth * 0.16, bubbleTop + bubbleBodyHeight)
    ..lineTo(bubbleLeft + bubbleWidth * 0.04, bubbleTop + bubbleHeightTotal)
    ..lineTo(bubbleLeft + bubbleWidth * 0.32, bubbleTop + bubbleBodyHeight)
    ..close();
  bubblePath.addPath(tailPath, Offset.zero);

  canvas.drawPath(bubblePath, bubblePaint);

  // Inner lines inside chat bubble
  final linePaint = Paint()
    ..color = primaryGreen
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.2 * baseUnit;

  // Top line
  canvas.drawLine(
    Offset(bubbleLeft + bubbleWidth * 0.24, bubbleTop + bubbleBodyHeight * 0.38),
    Offset(bubbleLeft + bubbleWidth * 0.76, bubbleTop + bubbleBodyHeight * 0.38),
    linePaint,
  );

  // Bottom line
  canvas.drawLine(
    Offset(bubbleLeft + bubbleWidth * 0.24, bubbleTop + bubbleBodyHeight * 0.64),
    Offset(bubbleLeft + bubbleWidth * 0.58, bubbleTop + bubbleBodyHeight * 0.64),
    linePaint,
  );

  // Check Badge in bottom right
  // In the original design, 66x66 container, dark square is 64x64 at (0,0),
  // badge is 24x24 at bottom: -2, right: -2.
  // Dark square center is at (32, 32).
  // Badge center is at (66 - 2 - 12, 66 - 2 - 12) = (52, 52).
  // Offset from dark square center = (52 - 32, 52 - 32) = (20, 20).
  final badgeOffset = Offset(20.0 * baseUnit, 20.0 * baseUnit);
  final badgeCenter = center + badgeOffset;
  final badgeRadius = 12.0 * baseUnit;
  final borderWidth = 2.5 * baseUnit;

  // Badge border / background circle
  final borderPaint = Paint()..color = mintGreen;
  canvas.drawCircle(badgeCenter, badgeRadius + borderWidth, borderPaint);

  // Badge inner circle
  final badgeInnerPaint = Paint()..color = primaryGreen;
  canvas.drawCircle(badgeCenter, badgeRadius, badgeInnerPaint);

  // Checkmark inside badge
  final checkPaint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4 * baseUnit;

  final checkPath = Path();
  // Checkmark points relative to badgeCenter:
  // Left point: (-4.2, 0.2)
  // Vertex: (-1.0, 3.4)
  // Right point: (4.4, -2.8)
  checkPath.moveTo(
    badgeCenter.dx - 4.2 * baseUnit,
    badgeCenter.dy + 0.2 * baseUnit,
  );
  checkPath.lineTo(
    badgeCenter.dx - 1.0 * baseUnit,
    badgeCenter.dy + 3.4 * baseUnit,
  );
  checkPath.lineTo(
    badgeCenter.dx + 4.4 * baseUnit,
    badgeCenter.dy - 2.8 * baseUnit,
  );

  canvas.drawPath(checkPath, checkPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
