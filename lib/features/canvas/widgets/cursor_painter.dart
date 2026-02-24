import 'package:flutter/material.dart';

class CursorPainter extends CustomPainter {
  final List<Map<String, dynamic>> users;

  CursorPainter({required this.users});

  @override
  void paint(Canvas canvas, Size size) {
    for (var user in users) {
      final double? x = user['cursor_x']?.toDouble();
      final double? y = user['cursor_y']?.toDouble();
      
      if (x != null && y != null) {
        _drawCursor(canvas, Offset(x, y), user['name'] ?? 'Student');
      }
    }
  }

  void _drawCursor(Canvas canvas, Offset position, String name) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    // Draw cursor arrow (simplified triangle)
    final path = Path()
      ..moveTo(position.dx, position.dy)
      ..lineTo(position.dx + 12, position.dy + 12)
      ..lineTo(position.dx + 4, position.dy + 12)
      ..lineTo(position.dx, position.dy + 18)
      ..close();
    
    canvas.drawPath(path, paint);

    // Draw label background
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      position.dx + 8,
      position.dy + 18,
      textPainter.width + 12,
      textPainter.height + 4,
    );

    final RRect rRect = RRect.fromRectAndRadius(labelRect, const Radius.circular(4));
    canvas.drawRRect(rRect, paint);

    // Draw label text
    textPainter.paint(
      canvas,
      Offset(labelRect.left + 6, labelRect.top + 2),
    );
  }

  @override
  bool shouldRepaint(covariant CursorPainter oldDelegate) => true;
}
