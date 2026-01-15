import 'package:flutter/material.dart';

class DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  DotGridPainter({
    required this.dotColor,
    this.spacing = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
