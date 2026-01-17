import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:freehand/freehand.dart' as fh;
import 'package:classlly/data/models/note_models.dart';

class PdfService {
  Future<void> exportNote(Note note) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
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
                        '<svg width="1000" height="1000"><path d="${pathData.toString()}" fill="#$colorHex" /></svg>',
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

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${note.title}.pdf',
    );
  }
}
