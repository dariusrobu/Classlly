import 'package:flutter/material.dart';
import 'package:freehand/freehand.dart' as fh;
import 'package:classlly/data/models/note_models.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Stroke> selectedStrokes;
  final List<ImageBlock> selectedImages;
  final List<TextBlock> selectedTextBlocks;
  final List<StrokePoint> activePoints;
  final Color activeColor;
  final double activeWidth;
  final int? playbackTime;
  final List<StrokePoint>? ghostPoints;
  final List<Offset>? lassoPath;

  DrawingPainter({
    required this.strokes,
    this.selectedStrokes = const [],
    this.selectedImages = const [],
    this.selectedTextBlocks = const [],
    this.activePoints = const [],
    required this.activeColor,
    required this.activeWidth,
    this.playbackTime,
    this.ghostPoints,
    this.lassoPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (var stroke in strokes) {
      if (playbackTime != null && stroke.createdAt > playbackTime!) continue;
      bool isSelected = selectedStrokes.contains(stroke);
      _drawStroke(
        canvas,
        stroke.points,
        isSelected ? Colors.deepPurpleAccent : Color(stroke.color),
        stroke.width + (isSelected ? 2.0 : 0.0),
        paint,
        toolType: stroke.toolType,
      );
    }

    if (activePoints.isNotEmpty && playbackTime == null) {
      _drawStroke(canvas, activePoints, activeColor, activeWidth, paint);
    }

    if (ghostPoints != null && ghostPoints!.isNotEmpty) {
      _drawStroke(
        canvas,
        ghostPoints!,
        Colors.deepPurpleAccent.withValues(alpha: 0.5),
        activeWidth,
        paint,
      );
    }

    if (lassoPath != null && lassoPath!.length > 1) {
      _drawLassoPath(canvas);
    }

    if (selectedStrokes.isNotEmpty || selectedImages.isNotEmpty || selectedTextBlocks.isNotEmpty) {
      _drawSelectionBox(canvas, size);
    }
  }

  void _drawLassoPath(Canvas canvas) {
    final path = Path();
    path.moveTo(lassoPath!.first.dx, lassoPath!.first.dy);
    for (int i = 1; i < lassoPath!.length; i++) {
      path.lineTo(lassoPath![i].dx, lassoPath![i].dy);
    }
    path.close();

    final fillPaint = Paint()
      ..color = Colors.deepPurpleAccent.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.deepPurpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);
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

    for (var img in selectedImages) {
      if (img.x < minX) minX = img.x;
      if (img.x + img.width > maxX) maxX = img.x + img.width;
      if (img.y < minY) minY = img.y;
      if (img.y + img.height > maxY) maxY = img.y + img.height;
    }

    for (var block in selectedTextBlocks) {
      if (block.x < minX) minX = block.x;
      if (block.x + 100 > maxX) maxX = block.x + 100;
      if (block.y < minY) minY = block.y;
      if (block.y + 30 > maxY) maxY = block.y + 30;
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
    Paint paint, {
    String toolType = 'pen',
  }) {
    if (points.isEmpty) return;
    paint.color = color;

    // Specific rendering for Highlighter
    if (toolType == 'highlighter') {
      paint.blendMode = BlendMode.multiply; // Highlighter effect
      paint.strokeCap = StrokeCap.square;
    } else {
      paint.blendMode = BlendMode.srcOver;
      paint.strokeCap = StrokeCap.round;
    }

    if (points.length == 2 || points.length == 5) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = width;
      paint.strokeJoin = StrokeJoin.miter;
      final path = Path();
      path.moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
      if (points.length == 5) path.close();
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
      return;
    }

    // Customize stroke options based on toolType
    var options = fh.StrokeOptions(
      size: width,
      thinning: 0.5,
      smoothing: 0.5,
      streamline: 0.5,
      simulatePressure: true,
    );

    if (toolType == 'monoline') {
      options = fh.StrokeOptions(
        size: width,
        thinning: 0.0, // No pressure sensitivity for thickness
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
      );
    } else if (toolType == 'fountain') {
      options = fh.StrokeOptions(
        size: width * 1.2,
        thinning: 0.9, // High contrast between thin and thick
        smoothing: 0.2, // Shorter smoothing for more responsive/sharper feel
        streamline: 0.8, // High streamline for elegant curves
        simulatePressure: true,
      );
    } else if (toolType == 'marker') {
      options = fh.StrokeOptions(
        size: width,
        thinning: 0.0,
        smoothing: 0.2, // Less smoothing for "rough" look
        streamline: 0.3,
        simulatePressure: false,
      );
    } else if (toolType == 'pencil') {
      options = fh.StrokeOptions(
        size: width * 0.8, // Slightly thinner
        thinning: 0.3, // Less pressure variance
        smoothing: 0.3, // More raw input
        streamline: 0.3,
        simulatePressure: true,
      );
    } else if (toolType == 'brush') {
      options = fh.StrokeOptions(
        size: width * 1.2, // Slightly thicker base
        thinning: 0.85, // Very high pressure sensitivity
        smoothing: 0.8, // Very smooth
        streamline: 0.7,
        simulatePressure: true,
      );
    } else if (toolType == 'watercolor') {
      options = fh.StrokeOptions(
        size: width * 2.0, // Large soft brush
        thinning: 0.95, // Extreme pressure sensitivity
        smoothing: 0.9, // Ultra smooth
        streamline: 0.8,
        simulatePressure: true,
      );
    }

    final inputPoints = points
        .map((p) => fh.Vec(p.x, p.y, p.pressure))
        .toList();
    final outlinePoints = fh.getStroke(inputPoints, options: options);

    if (outlinePoints.isEmpty) return;
    final path = Path();
    path.moveTo(outlinePoints[0].x, outlinePoints[0].y);
    for (var i = 1; i < outlinePoints.length; i++) {
      path.lineTo(outlinePoints[i].x, outlinePoints[i].y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
