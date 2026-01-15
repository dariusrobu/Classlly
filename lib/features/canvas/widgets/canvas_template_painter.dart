import 'package:flutter/material.dart';

class CanvasTemplatePainter extends CustomPainter {
  final String type; // dot, grid, lined, cornell
  final Color color;
  final double spacing;

  CanvasTemplatePainter({
    required this.type,
    required this.color,
    this.spacing = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    switch (type) {
      case 'dot':
        final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
          }
        }
        break;

      case 'grid':
        for (double x = 0; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;

      case 'lined':
        for (double y = spacing * 2; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        // Vertical margin line
        final redPaint = Paint()..color = Colors.red.withOpacity(0.3)..strokeWidth = 1.0;
        canvas.drawLine(Offset(spacing * 3, 0), Offset(spacing * 3, size.height), redPaint);
        break;

      case 'cornell':
        // Summary Area (Bottom)
        canvas.drawLine(Offset(0, size.height - 150), Offset(size.width, size.height - 150), paint);
        // Cue Column (Left)
        canvas.drawLine(Offset(200, 0), Offset(200, size.height - 150), paint);
        // Header Area (Top)
        canvas.drawLine(Offset(0, 100), Offset(size.width, 100), paint);
        
        // Lines in Note Area
        final noteLinesPaint = Paint()..color = color.withOpacity(0.1)..strokeWidth = 0.5;
        for (double y = 100 + spacing; y < size.height - 150; y += spacing) {
          canvas.drawLine(Offset(200, y), Offset(size.width, y), noteLinesPaint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
