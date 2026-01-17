import 'dart:math';
import 'package:flutter/material.dart';
import 'package:classlly/data/models/note_models.dart';

class GeometryUtils {
  static bool isClosedLoop(
    List<StrokePoint> points, {
    double threshold = 100.0,
  }) {
    if (points.length < 10) return false;
    final start = points.first;
    final end = points.last;
    final distance = sqrt(pow(start.x - end.x, 2) + pow(start.y - end.y, 2));
    return distance < threshold;
  }

  static Rect getBoundingBox(List<StrokePoint> points) {
    if (points.isEmpty) return Rect.zero;
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (var p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static bool isPointInPolygon(Offset point, List<StrokePoint> polygonPoints) {
    bool isInside = false;
    int j = polygonPoints.length - 1;
    for (int i = 0; i < polygonPoints.length; i++) {
      if ((polygonPoints[i].y > point.dy) != (polygonPoints[j].y > point.dy) &&
          point.dx <
              (polygonPoints[j].x - polygonPoints[i].x) *
                      (point.dy - polygonPoints[i].y) /
                      (polygonPoints[j].y - polygonPoints[i].y) +
                  polygonPoints[i].x) {
        isInside = !isInside;
      }
      j = i;
    }
    return isInside;
  }

  static bool doRectsIntersect(Rect a, Rect b) => a.overlaps(b);

  static bool isScribble(List<StrokePoint> points) {
    if (points.length < 15) return false;
    final rect = getBoundingBox(points);
    double pathLen = 0;
    for (int i = 1; i < points.length; i++) {
      pathLen += sqrt(
        pow(points[i].x - points[i - 1].x, 2) +
            pow(points[i].y - points[i - 1].y, 2),
      );
    }
    final diag = sqrt(pow(rect.width, 2) + pow(rect.height, 2));
    return pathLen > 4 * diag;
  }

  static ShapeResult? recognizeShape(List<StrokePoint> points) {
    if (points.length < 20) return null;
    final rect = getBoundingBox(points);
    final center = rect.center;
    final start = Offset(points.first.x, points.first.y);
    final end = Offset(points.last.x, points.last.y);

    double pathLength = 0;
    for (int i = 1; i < points.length; i++) {
      pathLength += sqrt(
        pow(points[i].x - points[i - 1].x, 2) +
            pow(points[i].y - points[i - 1].y, 2),
      );
    }
    final directDist = (end - start).distance;
    if (pathLength / (directDist == 0 ? 1 : directDist) < 1.05) {
      return ShapeResult(ShapeType.line, [points.first, points.last]);
    }

    if (isClosedLoop(points, threshold: 80.0)) {
      final distances = points
          .map((p) => (Offset(p.x, p.y) - center).distance)
          .toList();
      final double avgDist =
          distances.reduce((a, b) => a + b) / distances.length;
      double circleError = 0;
      for (var d in distances) {
        circleError += pow(d - avgDist, 2);
      }
      circleError = sqrt(circleError / points.length) / avgDist;

      double rectError = 0;
      for (var p in points) {
        final dL = (p.x - rect.left).abs();
        final dR = (p.x - rect.right).abs();
        final dT = (p.y - rect.top).abs();
        final dB = (p.y - rect.bottom).abs();
        rectError += pow([dL, dR, dT, dB].reduce(min), 2);
      }
      rectError =
          sqrt(rectError / points.length) / ((rect.width + rect.height) / 2);

      const double strictThreshold = 0.10;
      if (circleError < rectError && circleError < strictThreshold) {
        final circlePoints = <StrokePoint>[];
        for (int i = 0; i <= 40; i++) {
          final angle = (i * 2 * pi) / 40;
          circlePoints.add(
            StrokePoint(
              x: center.dx + avgDist * cos(angle),
              y: center.dy + avgDist * sin(angle),
            ),
          );
        }
        return ShapeResult(ShapeType.circle, circlePoints);
      } else if (rectError < strictThreshold) {
        return ShapeResult(ShapeType.rectangle, [
          StrokePoint(x: rect.left, y: rect.top),
          StrokePoint(x: rect.right, y: rect.top),
          StrokePoint(x: rect.right, y: rect.bottom),
          StrokePoint(x: rect.left, y: rect.bottom),
          StrokePoint(x: rect.left, y: rect.top),
        ]);
      }
    }
    return null;
  }
}

enum ShapeType { line, circle, rectangle }

class ShapeResult {
  final ShapeType type;
  final List<StrokePoint> points;
  ShapeResult(this.type, this.points);
}
