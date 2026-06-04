import 'dart:math';
import 'package:flutter/material.dart';
import 'package:classlly/data/models/note_models.dart';

enum RecognizedShape { line, circle, rectangle, triangle, arrow, diamond }

class ShapeRecognitionResult {
  final RecognizedShape type;
  final List<StrokePoint> points;
  final double confidence;

  ShapeRecognitionResult({
    required this.type,
    required this.points,
    required this.confidence,
  });
}

class ShapeRecognizer {
  static const double _minPoints = 15;
  // static const double _confidenceThreshold = 0.7;

  static const Map<RecognizedShape, String> shapeNames = {
    RecognizedShape.line: 'Line',
    RecognizedShape.circle: 'Circle',
    RecognizedShape.rectangle: 'Rectangle',
    RecognizedShape.triangle: 'Triangle',
    RecognizedShape.arrow: 'Arrow',
    RecognizedShape.diamond: 'Diamond',
  };

  ShapeRecognitionResult? recognize(List<StrokePoint> points) {
    if (points.length < _minPoints) return null;

    final rect = _getBoundingBox(points);
    final center = rect.center;
    final start = Offset(points.first.x, points.first.y);
    final end = Offset(points.last.x, points.last.y);

    final pathLength = _calculatePathLength(points);
    final directDist = (end - start).distance;
    final ratio = pathLength / (directDist == 0 ? 1 : directDist);

    if (ratio < 1.1) {
      return ShapeRecognitionResult(
        type: RecognizedShape.line,
        points: [points.first, points.last],
        confidence: 0.95,
      );
    }

    if (_isClosedLoop(points, 100)) {
      return _recognizeClosedShape(points, rect, center);
    }

    return _recognizeOpenShape(points, start, end, pathLength);
  }

  ShapeRecognitionResult? _recognizeClosedShape(
    List<StrokePoint> points,
    Rect rect,
    Offset center,
  ) {
    final distances = points
        .map((p) => (Offset(p.x, p.y) - center).distance)
        .toList();
    final avgDist = distances.reduce((a, b) => a + b) / distances.length;

    final circleError = _calculateCircleError(distances, avgDist);
    final rectError = _calculateRectError(points, rect);
    final triangleError = _calculateTriangleError(points, rect);
    final diamondError = _calculateDiamondError(points, rect);

    final aspectRatio = rect.width / (rect.height == 0 ? 1 : rect.height);
    final aspectRatioDiff = (aspectRatio - 1.0).abs();

    double adjustedCircleError = circleError;
    if (aspectRatioDiff < 0.25) {
      adjustedCircleError = circleError * 0.5;
    } else if (aspectRatioDiff < 0.4) {
      adjustedCircleError = circleError * 0.75;
    }

    final shapeErrors = {
      RecognizedShape.circle: adjustedCircleError,
      RecognizedShape.rectangle: rectError,
      RecognizedShape.triangle: triangleError,
      RecognizedShape.diamond: diamondError,
    };

    final sortedShapes = shapeErrors.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final bestShape = sortedShapes.first;
    final bestError = bestShape.value;

    if (bestError > 0.45) {
      return null;
    }

    final confidence = (1.0 - (bestError / 0.45)).clamp(0.0, 1.0);

    switch (bestShape.key) {
      case RecognizedShape.circle:
        return ShapeRecognitionResult(
          type: RecognizedShape.circle,
          points: _generateCirclePoints(center, avgDist, 40),
          confidence: confidence,
        );
      case RecognizedShape.rectangle:
        return ShapeRecognitionResult(
          type: RecognizedShape.rectangle,
          points: [
            StrokePoint(x: rect.left, y: rect.top),
            StrokePoint(x: rect.right, y: rect.top),
            StrokePoint(x: rect.right, y: rect.bottom),
            StrokePoint(x: rect.left, y: rect.bottom),
            StrokePoint(x: rect.left, y: rect.top),
          ],
          confidence: confidence,
        );
      case RecognizedShape.triangle:
        return ShapeRecognitionResult(
          type: RecognizedShape.triangle,
          points: _generateTrianglePoints(rect),
          confidence: confidence,
        );
      case RecognizedShape.diamond:
        return ShapeRecognitionResult(
          type: RecognizedShape.diamond,
          points: _generateDiamondPoints(rect),
          confidence: confidence,
        );
      default:
        return null;
    }
  }

  ShapeRecognitionResult _recognizeOpenShape(
    List<StrokePoint> points,
    Offset start,
    Offset end,
    double pathLength,
  ) {
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowHeadAngle = 0.5;
    final arrowHeadLength = (end - start).distance * 0.25;

    final leftWing = Offset(
      end.dx - arrowHeadLength * cos(angle + arrowHeadAngle),
      end.dy - arrowHeadLength * sin(angle + arrowHeadAngle),
    );
    final rightWing = Offset(
      end.dx - arrowHeadLength * cos(angle - arrowHeadAngle),
      end.dy - arrowHeadLength * sin(angle - arrowHeadAngle),
    );

    double arrowError = 0;
    for (final p in points) {
      final point = Offset(p.x, p.y);

      if ((point - end).distance < arrowHeadLength * 1.5) {
        final distToLeft = (point - leftWing).distance;
        final distToRight = (point - rightWing).distance;
        final distToLine = _pointToLineDistance(point, start, end);
        arrowError += min(distToLeft, min(distToRight, distToLine));
      } else {
        arrowError += _pointToLineDistance(point, start, end);
      }
    }
    arrowError /= points.length;

    final diag = (end - start).distance;
    final normalizedError = arrowError / (diag == 0 ? 1 : diag);

    if (normalizedError < 0.15) {
      return ShapeRecognitionResult(
        type: RecognizedShape.arrow,
        points: [
          points.first,
          points.last,
          StrokePoint(x: leftWing.dx, y: leftWing.dy),
          points.last,
          StrokePoint(x: rightWing.dx, y: rightWing.dy),
        ],
        confidence: 1.0 - normalizedError,
      );
    }

    return ShapeRecognitionResult(
      type: RecognizedShape.line,
      points: [points.first, points.last],
      confidence: 0.9,
    );
  }

  Rect _getBoundingBox(List<StrokePoint> points) {
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _calculatePathLength(List<StrokePoint> points) {
    double len = 0;
    for (int i = 1; i < points.length; i++) {
      len += sqrt(
        pow(points[i].x - points[i - 1].x, 2) +
            pow(points[i].y - points[i - 1].y, 2),
      );
    }
    return len;
  }

  bool _isClosedLoop(List<StrokePoint> points, double threshold) {
    final start = Offset(points.first.x, points.first.y);
    final end = Offset(points.last.x, points.last.y);
    return (end - start).distance < threshold;
  }

  double _calculateCircleError(List<double> distances, double avgDist) {
    double error = 0;
    for (var d in distances) {
      error += pow(d - avgDist, 2);
    }
    return sqrt(error / distances.length) / avgDist;
  }

  double _calculateRectError(List<StrokePoint> points, Rect rect) {
    double error = 0;
    for (var p in points) {
      final dL = (p.x - rect.left).abs();
      final dR = (p.x - rect.right).abs();
      final dT = (p.y - rect.top).abs();
      final dB = (p.y - rect.bottom).abs();
      final minDist = [dL, dR, dT, dB].reduce(min);
      error += minDist * minDist;
    }
    return sqrt(error / points.length) / ((rect.width + rect.height) / 2);
  }

  double _calculateTriangleError(List<StrokePoint> points, Rect rect) {
    final vertices = [
      Offset(rect.center.dx, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];

    double error = 0;
    for (var p in points) {
      final point = Offset(p.x, p.y);
      double minDist = double.infinity;
      for (int i = 0; i < 3; i++) {
        final dist = _pointToLineDistance(
          point,
          vertices[i],
          vertices[(i + 1) % 3],
        );
        if (dist < minDist) minDist = dist;
      }
      error += minDist;
    }
    return (error / points.length) / ((rect.width + rect.height) / 2);
  }

  double _calculateDiamondError(List<StrokePoint> points, Rect rect) {
    final vertices = [
      Offset(rect.center.dx, rect.top),
      Offset(rect.right, rect.center.dy),
      Offset(rect.center.dx, rect.bottom),
      Offset(rect.left, rect.center.dy),
    ];

    double error = 0;
    for (var p in points) {
      final point = Offset(p.x, p.y);
      double minDist = double.infinity;
      for (int i = 0; i < 4; i++) {
        final dist = _pointToLineDistance(
          point,
          vertices[i],
          vertices[(i + 1) % 4],
        );
        if (dist < minDist) minDist = dist;
      }
      error += minDist;
    }
    return (error / points.length) / ((rect.width + rect.height) / 2);
  }

  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    double param = -1;
    if (lenSq != 0) param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      xx = lineStart.dx;
      yy = lineStart.dy;
    } else if (param > 1) {
      xx = lineEnd.dx;
      yy = lineEnd.dy;
    } else {
      xx = lineStart.dx + param * C;
      yy = lineStart.dy + param * D;
    }

    return sqrt(pow(point.dx - xx, 2) + pow(point.dy - yy, 2));
  }

  List<StrokePoint> _generateCirclePoints(
    Offset center,
    double radius,
    int count,
  ) {
    final pts = <StrokePoint>[];
    for (int i = 0; i <= count; i++) {
      final angle = (i * 2 * pi) / count;
      pts.add(
        StrokePoint(
          x: center.dx + radius * cos(angle),
          y: center.dy + radius * sin(angle),
        ),
      );
    }
    return pts;
  }

  List<StrokePoint> _generateTrianglePoints(Rect rect) {
    return [
      StrokePoint(x: rect.center.dx, y: rect.top),
      StrokePoint(x: rect.right, y: rect.bottom),
      StrokePoint(x: rect.left, y: rect.bottom),
      StrokePoint(x: rect.center.dx, y: rect.top),
    ];
  }

  List<StrokePoint> _generateDiamondPoints(Rect rect) {
    return [
      StrokePoint(x: rect.center.dx, y: rect.top),
      StrokePoint(x: rect.right, y: rect.center.dy),
      StrokePoint(x: rect.center.dx, y: rect.bottom),
      StrokePoint(x: rect.left, y: rect.center.dy),
      StrokePoint(x: rect.center.dx, y: rect.top),
    ];
  }
}
