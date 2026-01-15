import 'package:flutter/material.dart';
import 'package:freehand/freehand.dart' as fh;
import 'package:classlly/data/models/note_models.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Stroke> selectedStrokes;
  final List<StrokePoint> activePoints;
  final Color activeColor;
  final double activeWidth;
  final int? playbackTime;
  final List<StrokePoint>? ghostPoints;

  DrawingPainter({
    required this.strokes,
    this.selectedStrokes = const [],
    this.activePoints = const [],
    required this.activeColor,
    required this.activeWidth,
    this.playbackTime,
    this.ghostPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (var stroke in strokes) {
      if (playbackTime != null && stroke.createdAt > playbackTime!) continue;
      bool isSelected = selectedStrokes.contains(stroke);
      _drawStroke(canvas, stroke.points, isSelected ? Colors.deepPurpleAccent : Color(stroke.color), stroke.width + (isSelected ? 2.0 : 0.0), paint);
    }

    if (activePoints.isNotEmpty && playbackTime == null) {
      _drawStroke(canvas, activePoints, activeColor, activeWidth, paint);
    }

    // Draw Ghost Shape (Dashed/Transparent)
    if (ghostPoints != null && ghostPoints!.isNotEmpty) {
      final ghostPaint =
        Paint()
          ..color = Colors.deepPurpleAccent.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
      
      // Simulating dashed by just drawing the outline
      _drawStroke(canvas, ghostPoints!, Colors.deepPurpleAccent.withOpacity(0.5), activeWidth, paint);
    }

    if (selectedStrokes.isNotEmpty) {
      _drawSelectionBox(canvas, size);
    }
  }

  void _drawSelectionBox(Canvas canvas, Size size) {
    double minX = double.infinity,
        maxX = -double.infinity,
        minY = double.infinity,
        maxY = -double.infinity;
    for (var stroke in selectedStrokes) {
      for (var p in stroke.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
    }
    if (minX == double.infinity) return;
    final rect = Rect.fromLTRB(minX, minY, maxX, maxY).inflate(10);
    final paint = Paint()
      ..color = Colors.deepPurpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, paint);
    final handlePaint = Paint()..color = Colors.deepPurpleAccent;
    const handleRadius = 6.0;
    canvas.drawCircle(rect.topLeft, handleRadius, handlePaint);
    canvas.drawCircle(rect.topRight, handleRadius, handlePaint);
    canvas.drawCircle(rect.bottomLeft, handleRadius, handlePaint);
    canvas.drawCircle(rect.bottomRight, handleRadius, handlePaint);
  }

  void _drawStroke(
    Canvas canvas,
    List<StrokePoint> points,
    Color color,
    double width,
    Paint paint,
  ) {
    if (points.isEmpty) return;
    paint.color = color;

    // If it's a perfected shape (e.g. 2 points for line, 5 points for rect)
    // we draw it directly to avoid smoothing artifacts
    if (points.length == 2 || points.length == 5) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = width;
      paint.strokeJoin = StrokeJoin.miter;
      paint.strokeCap = StrokeCap.round;
      
      final path = Path();
      path.moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
      if (points.length == 5) path.close();
      canvas.drawPath(path, paint);
      
      // Reset paint for next call
      paint.style = PaintingStyle.fill;
      return;
    }

    // Default: Smoothing for freehand ink
    final inputPoints = points
        .map((p) => fh.Vec(p.x, p.y, p.pressure))
        .toList();
    final outlinePoints = fh.getStroke(
      inputPoints,
      options: fh.StrokeOptions(
        size: width,
        thinning: 0.5,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: true,
      ),
    );
    if (outlinePoints.isEmpty) return;
    final path = Path();
    path.moveTo(outlinePoints[0].x, outlinePoints[0].y);
    for (var i = 1; i < outlinePoints.length; i++)
      path.lineTo(outlinePoints[i].x, outlinePoints[i].y);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
