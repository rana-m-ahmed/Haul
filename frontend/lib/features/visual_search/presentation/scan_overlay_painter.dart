import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ScanOverlayPainter extends CustomPainter {
  final double scanLineProgress;

  ScanOverlayPainter({required this.scanLineProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.signal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);

    final crosshairPaint = Paint()
      ..color = AppColors.signal.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      crosshairPaint,
    );

    final scanLineY = size.height * scanLineProgress;
    
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    final scanPaint = Paint()
      ..color = AppColors.signal.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, scanLineY),
      Offset(size.width, scanLineY),
      scanPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanLineProgress != scanLineProgress;
  }
}
