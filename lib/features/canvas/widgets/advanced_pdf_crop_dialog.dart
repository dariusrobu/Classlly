import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Advanced PDF Crop Dialog with 8-point handles, rule-of-thirds grid, and background processing.
class AdvancedPdfCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const AdvancedPdfCropDialog({super.key, required this.imageBytes});

  @override
  State<AdvancedPdfCropDialog> createState() => _AdvancedPdfCropDialogState();
}

class _AdvancedPdfCropDialogState extends State<AdvancedPdfCropDialog> {
  // Current crop rectangle in LOCAL coordinates of the displayed image
  Rect _cropRect = const Rect.fromLTWH(50, 50, 200, 200);
  
  // Real size of the decoded image (for coordinate mapping)
  Size? _realImageSize;
  
  // Size of the image as displayed on screen
  Size? _displayImageSize;
  
  final GlobalKey _imageKey = GlobalKey();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    final Completer<Size> completer = Completer();
    final Image image = Image.memory(widget.imageBytes);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    final size = await completer.future;
    if (mounted) {
      setState(() {
        _realImageSize = size;
        // Initial crop rect: center 60%
        _cropRect = Rect.fromCenter(
          center: const Offset(150, 150), // Will be updated in build
          width: 200,
          height: 200,
        );
      });
    }
  }

  Future<void> _onInsert() async {
    if (_realImageSize == null || _displayImageSize == null) return;

    setState(() => _isProcessing = true);

    try {
      final scaleX = _realImageSize!.width / _displayImageSize!.width;
      final scaleY = _realImageSize!.height / _displayImageSize!.height;

      final cropParams = _CropParams(
        imageBytes: widget.imageBytes,
        x: (_cropRect.left * scaleX).toInt(),
        y: (_cropRect.top * scaleY).toInt(),
        width: (_cropRect.width * scaleX).toInt(),
        height: (_cropRect.height * scaleY).toInt(),
      );

      // Process in background isolate
      final croppedBytes = await compute(_processCrop, cropParams);
      
      if (mounted) {
        Navigator.pop(context, croppedBytes);
      }
    } catch (e) {
      debugPrint('Crop error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New PDF Snippet'),
      backgroundColor: const Color(0xFF1E293B),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: _realImageSize == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate display size matching BoxFit.contain
                            final double imageAspectRatio =
                                _realImageSize!.width / _realImageSize!.height;
                            double displayW, displayH;

                            if (constraints.maxWidth / constraints.maxHeight >
                                imageAspectRatio) {
                              displayH = constraints.maxHeight;
                              displayW = displayH * imageAspectRatio;
                            } else {
                              displayW = constraints.maxWidth;
                              displayH = displayW / imageAspectRatio;
                            }

                            // Update display size and initial crop if first time
                            if (_displayImageSize == null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _displayImageSize = Size(displayW, displayH);
                                  _cropRect = Rect.fromLTWH(
                                    displayW * 0.1,
                                    displayH * 0.1,
                                    displayW * 0.8,
                                    displayH * 0.4,
                                  );
                                });
                              });
                            }

                            return Container(
                              width: displayW,
                              height: displayH,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                  )
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Image.memory(
                                    widget.imageBytes,
                                    key: _imageKey,
                                    width: displayW,
                                    height: displayH,
                                    fit: BoxFit.fill,
                                  ),
                                  // Dimmed overlay
                                  Positioned.fill(
                                    child: _CropOverlay(
                                      cropRect: _cropRect,
                                      onChanged: (newRect) {
                                        setState(() => _cropRect = newRect);
                                      },
                                      imageSize: Size(displayW, displayH),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black26,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.grid_3x3_rounded,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Drag corners to crop. High-resolution output.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const Spacer(),
                        if (_isProcessing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _onInsert,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Insert Snippet'),
        ),
      ],
    );
  }
}

class _CropOverlay extends StatelessWidget {
  final Rect cropRect;
  final ValueChanged<Rect> onChanged;
  final Size imageSize;

  const _CropOverlay({
    required this.cropRect,
    required this.onChanged,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Darkened areas around crop rect
        CustomPaint(
          size: Size.infinite,
          painter: _DimmerPainter(cropRect: cropRect),
        ),
        // The crop window itself
        Positioned.fromRect(
          rect: cropRect,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: CustomPaint(
              painter: _GridPainter(),
              child: Stack(
                children: [
                  // Middle move handle
                  GestureDetector(
                    onPanUpdate: (details) {
                      onChanged(_clamp(cropRect.shift(details.delta)));
                    },
                    child: Container(color: Colors.transparent),
                  ),
                  // Corner/Side handles
                  ..._buildHandles(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Rect _clamp(Rect rect) {
    double left = rect.left.clamp(0.0, imageSize.width - rect.width);
    double top = rect.top.clamp(0.0, imageSize.height - rect.height);
    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  List<Widget> _buildHandles() {
    return [
      // Corners
      _handle(
        Alignment.topLeft,
        (d) => _resize(top: d.dy, left: d.dx),
        Icons.circle,
      ),
      _handle(
        Alignment.topRight,
        (d) => _resize(top: d.dy, right: d.dx),
        Icons.circle,
      ),
      _handle(
        Alignment.bottomLeft,
        (d) => _resize(bottom: d.dy, left: d.dx),
        Icons.circle,
      ),
      _handle(
        Alignment.bottomRight,
        (d) => _resize(bottom: d.dy, right: d.dx),
        Icons.circle,
      ),
      // Sides
      _handle(Alignment.topCenter, (d) => _resize(top: d.dy), null),
      _handle(Alignment.bottomCenter, (d) => _resize(bottom: d.dy), null),
      _handle(Alignment.centerLeft, (d) => _resize(left: d.dx), null),
      _handle(Alignment.centerRight, (d) => _resize(right: d.dx), null),
    ];
  }

  Widget _handle(Alignment alignment, Function(Offset) onDrag, IconData? icon) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: icon != null ? Colors.white : Colors.white70,
            shape: icon != null ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: icon == null ? BorderRadius.circular(2) : null,
          ),
          margin: const EdgeInsets.all(-4), // Overlap edge
        ),
      ),
    );
  }

  void _resize({double? top, double? bottom, double? left, double? right}) {
    double l = cropRect.left + (left ?? 0);
    double t = cropRect.top + (top ?? 0);
    double r = cropRect.right + (right ?? 0);
    double b = cropRect.bottom + (bottom ?? 0);

    // Minimum size
    const minSize = 40.0;
    
    if (r - l < minSize) {
      if (left != null) l = r - minSize;
      if (right != null) r = l + minSize;
    }
    if (b - t < minSize) {
      if (top != null) t = b - minSize;
      if (bottom != null) b = t + minSize;
    }

    // Constraints
    l = l.clamp(0.0, imageSize.width);
    t = t.clamp(0.0, imageSize.height);
    r = r.clamp(l + minSize, imageSize.width);
    b = b.clamp(t + minSize, imageSize.height);

    onChanged(Rect.fromLTRB(l, t, r, b));
  }
}

class _DimmerPainter extends CustomPainter {
  final Rect cropRect;
  _DimmerPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cropRect.top), paint);
    // Bottom
    canvas.drawRect(Rect.fromLTRB(0, cropRect.bottom, size.width, size.height), paint);
    // Left
    canvas.drawRect(Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom), paint);
    // Right
    canvas.drawRect(Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom), paint);
  }

  @override
  bool shouldRepaint(_DimmerPainter oldDelegate) => oldDelegate.cropRect != cropRect;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);

    // Vertical lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CropParams {
  final Uint8List imageBytes;
  final int x, y, width, height;
  _CropParams({
    required this.imageBytes,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Top-level function for background isolate processing
Uint8List _processCrop(_CropParams params) {
  final image = img.decodeImage(params.imageBytes);
  if (image == null) throw Exception('Failed to decode image');
  
  final cropped = img.copyCrop(
    image,
    x: params.x,
    y: params.y,
    width: params.width,
    height: params.height,
  );
  
  return Uint8List.fromList(img.encodePng(cropped));
}
