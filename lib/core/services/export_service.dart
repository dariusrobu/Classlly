import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:freehand/freehand.dart' as fh;
import 'dart:io';
import 'package:classlly/data/models/note_models.dart';

enum ExportFormat { png, pdf, svg }

class ExportService {
  Future<Uint8List?> exportAsImage(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    try {
      final boundary =
          repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('EXPORT_SERVICE: Image export error: $e');
      return null;
    }
  }

  Future<Uint8List> exportAsPdf(Note note) async {
    final pdf = pw.Document();

    final pageWidth = 595.0;
    final pageHeight = 842.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              ...note.strokes.map((stroke) {
                if (stroke.points.isEmpty) return pw.SizedBox();
                final inputPoints = stroke.points
                    .map((p) => fh.Vec(p.x, p.y, p.pressure))
                    .toList();
                final outlinePoints = fh.getStroke(
                  inputPoints,
                  options: fh.StrokeOptions(
                    size: stroke.width,
                    thinning: 0.5,
                    smoothing: 0.5,
                    streamline: 0.5,
                    simulatePressure: true,
                  ),
                );
                if (outlinePoints.isEmpty) return pw.SizedBox();
                final pathData = StringBuffer();
                pathData.write(
                  'M ${outlinePoints[0].x} ${outlinePoints[0].y} ',
                );
                for (var i = 1; i < outlinePoints.length; i++) {
                  pathData.write(
                    'L ${outlinePoints[i].x} ${outlinePoints[i].y} ',
                  );
                }
                pathData.write('Z');
                final colorHex = stroke.color
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .substring(2);
                return pw.Positioned(
                  left: 0,
                  top: 0,
                  child: pw.SvgImage(
                    svg:
                        '<svg width="$pageWidth" height="$pageHeight"><path d="${pathData.toString()}" fill="#$colorHex" /></svg>',
                  ),
                );
              }),
              ...note.textBlocks.map((block) {
                return pw.Positioned(
                  left: block.x,
                  top: block.y,
                  child: pw.Text(
                    block.text,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<String> exportAsSvg(Note note) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000">',
    );

    for (final stroke in note.strokes) {
      if (stroke.points.isEmpty) continue;
      final inputPoints = stroke.points
          .map((p) => fh.Vec(p.x, p.y, p.pressure))
          .toList();
      final outlinePoints = fh.getStroke(
        inputPoints,
        options: fh.StrokeOptions(
          size: stroke.width,
          thinning: 0.5,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: true,
        ),
      );
      if (outlinePoints.isEmpty) continue;
      final pathData = StringBuffer();
      pathData.write('M ${outlinePoints[0].x} ${outlinePoints[0].y} ');
      for (var i = 1; i < outlinePoints.length; i++) {
        pathData.write('L ${outlinePoints[i].x} ${outlinePoints[i].y} ');
      }
      pathData.write('Z');
      final colorHex = stroke.color
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2);
      buffer.writeln(
        '<path d="${pathData.toString()}" fill="#$colorHex" stroke="none"/>',
      );
    }

    for (final block in note.textBlocks) {
      buffer.writeln(
        '<text x="${block.x}" y="${block.y}" font-size="14">${block.text}</text>',
      );
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  Future<void> shareImage(Uint8List bytes, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> shareSvg(String svgContent, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename.svg');
    await file.writeAsString(svgContent);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> exportAndShare(
    Note note,
    ExportFormat format,
    GlobalKey repaintBoundaryKey,
  ) async {
    final title = note.title.isEmpty ? 'note' : note.title;
    final safeTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '');

    switch (format) {
      case ExportFormat.png:
        final bytes = await exportAsImage(repaintBoundaryKey);
        if (bytes != null) {
          await shareImage(bytes, safeTitle);
        }
        break;
      case ExportFormat.pdf:
        final bytes = await exportAsPdf(note);
        await sharePdf(bytes, '$safeTitle.pdf');
        break;
      case ExportFormat.svg:
        final svg = await exportAsSvg(note);
        await shareSvg(svg, safeTitle);
        break;
    }
  }
}
