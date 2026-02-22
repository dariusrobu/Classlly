import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

import 'package:classlly/core/utils/geometry_utils.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';

enum CanvasTool {
  pen,
  eraser,
  text,
  select,
  hand,
  highlighter,
  brush,
  monoline,
  fountain,
  reed,
  watercolor,
  pencil,
  marker,
  image,
}

enum EraserMode { pixel, object }

class NoteStateSnapshot {
  final List<Stroke> strokes;
  final List<TextBlock> textBlocks;
  final List<ImageBlock> images;
  NoteStateSnapshot({
    required this.strokes,
    required this.textBlocks,
    required this.images,
  });
}

class CanvasProvider with ChangeNotifier {
  final NotesRepository _repository;


  CanvasProvider({
    NotesRepository? repository,
  }) : _repository = repository ?? NotesRepository();

  final List<NoteStateSnapshot> _undoStack = [];
  final List<NoteStateSnapshot> _redoStack = [];

  Note? _currentNote;
  Note? get currentNote => _currentNote;

  CanvasTool _activeTool = CanvasTool.pen;
  CanvasTool get activeTool => _activeTool;

  EraserMode _eraserMode = EraserMode.pixel;
  EraserMode get eraserMode => _eraserMode;

  Color _currentColor = AppTheme.noteColors[0];
  Color get currentColor => _currentColor;

  List<Color> get savedColors {
    final prefs = _repository.getPreferences();
    return prefs.savedColors.map((c) => Color(c)).toList();
  }

  void addColor(Color color) {
    final prefs = _repository.getPreferences();
    if (!prefs.savedColors.contains(color.toARGB32())) {
      prefs.savedColors.add(color.toARGB32());
      _repository.savePreferences(prefs);
      notifyListeners();
    }
    setColor(color);
  }

  void removeColor(Color color) {
    final prefs = _repository.getPreferences();
    prefs.savedColors.remove(color.toARGB32());
    _repository.savePreferences(prefs);
    notifyListeners();
  }

  double _currentWidth = 3.0;
  double get currentWidth => _currentWidth;

  double _currentOpacity = 1.0;
  double get currentOpacity => _currentOpacity;

  int? _playbackTime;
  int? get playbackTime => _playbackTime;

  List<StrokePoint> _activePoints = [];
  List<StrokePoint> get activePoints => _activePoints;

  List<Stroke> _selectedStrokes = [];
  List<TextBlock> _selectedTextBlocks = [];
  List<ImageBlock> _selectedImages = [];

  List<Stroke> get selectedStrokes => _selectedStrokes;
  List<TextBlock> get selectedTextBlocks => _selectedTextBlocks;
  List<ImageBlock> get selectedImages => _selectedImages;

  List<Offset> _lassoPath = [];
  List<Offset> get lassoPath => _lassoPath;

  // Drag and resize state caching
  List<Stroke> _dragInitialStrokes = [];
  List<TextBlock> _dragInitialTextBlocks = [];
  List<ImageBlock> _dragInitialImages = [];
  Rect? _dragInitialRect;
  Offset? _dragStartPos;

  String? _activeResizeHandle;
  Rect? _selectionRect;

  ShapeResult? _ghostShape;
  ShapeResult? get ghostShape => _ghostShape;

  Timer? _debounceTimer;
  Timer? _studyTimer;
  final Stopwatch _studyStopwatch = Stopwatch();
  final bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _isStylusOnly = false;
  bool get isStylusOnly => _isStylusOnly;

  void toggleStylusOnly() {
    _isStylusOnly = !_isStylusOnly;
    notifyListeners();
  }

  void setEraserMode(EraserMode mode) {
    _eraserMode = mode;
    notifyListeners();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _takeSnapshot() {
    if (_currentNote == null) return;
    _undoStack.add(
      NoteStateSnapshot(
        strokes: List.from(_currentNote!.strokes),
        textBlocks: List.from(_currentNote!.textBlocks),
        images: List.from(_currentNote!.images),
      ),
    );
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    notifyListeners();
  }

  void undo() {
    if (!canUndo || _currentNote == null) return;
    _redoStack.add(
      NoteStateSnapshot(
        strokes: List.from(_currentNote!.strokes),
        textBlocks: List.from(_currentNote!.textBlocks),
        images: List.from(_currentNote!.images),
      ),
    );
    final snapshot = _undoStack.removeLast();
    _currentNote!.strokes.clear();
    _currentNote!.strokes.addAll(snapshot.strokes);
    _currentNote!.textBlocks.clear();
    _currentNote!.textBlocks.addAll(snapshot.textBlocks);
    _currentNote!.images.clear();
    _currentNote!.images.addAll(snapshot.images);
    notifyListeners();
    saveNote();
  }

  void redo() {
    if (!canRedo || _currentNote == null) return;
    _undoStack.add(
      NoteStateSnapshot(
        strokes: List.from(_currentNote!.strokes),
        textBlocks: List.from(_currentNote!.textBlocks),
        images: List.from(_currentNote!.images),
      ),
    );
    final snapshot = _redoStack.removeLast();
    _currentNote!.strokes.clear();
    _currentNote!.strokes.addAll(snapshot.strokes);
    _currentNote!.textBlocks.clear();
    _currentNote!.textBlocks.addAll(snapshot.textBlocks);
    _currentNote!.images.clear();
    _currentNote!.images.addAll(snapshot.images);
    notifyListeners();
    saveNote();
  }

  void setGhostShape(ShapeResult? shape) {
    _ghostShape = shape;
    notifyListeners();
  }

  void setOpacity(double opacity) {
    _currentOpacity = opacity;
    notifyListeners();
  }

  void startResize(Offset position) {
    if (_selectedStrokes.isEmpty &&
        _selectedTextBlocks.isEmpty &&
        _selectedImages.isEmpty) {
      return;
    }
    final rect = _calculateSelectionBounds();
    if (rect == null) return;
    _selectionRect = rect.inflate(10);
    const hitRadius = 40.0;

    if ((position - _selectionRect!.topLeft).distance < hitRadius) {
      _activeResizeHandle = 'tl';
    } else if ((position - _selectionRect!.topRight).distance < hitRadius) {
      _activeResizeHandle = 'tr';
    } else if ((position - _selectionRect!.bottomLeft).distance < hitRadius) {
      _activeResizeHandle = 'bl';
    } else if ((position - _selectionRect!.bottomRight).distance < hitRadius) {
      _activeResizeHandle = 'br';
    } else {
      _activeResizeHandle = null;
    }
    if (_activeResizeHandle != null) {
      _takeSnapshot();
      _cacheDragInitialState(position);
    }
  }

  void _cacheDragInitialState(Offset position) {
    _dragStartPos = position;
    _dragInitialRect = _calculateSelectionBounds()?.inflate(10);
    _dragInitialStrokes = _selectedStrokes.map((s) => Stroke(
      points: List.from(s.points), 
      color: s.color, 
      width: s.width, 
      createdAt: s.createdAt, 
      toolType: s.toolType
    )).toList();
    _dragInitialImages = _selectedImages.map((img) => ImageBlock(
      id: img.id,
      base64Data: img.base64Data,
      x: img.x,
      y: img.y,
      width: img.width,
      height: img.height,
      createdAt: img.createdAt
    )).toList();
    _dragInitialTextBlocks = _selectedTextBlocks.map((b) => TextBlock(
      id: b.id,
      text: b.text,
      x: b.x,
      y: b.y,
      createdAt: b.createdAt,
      color: b.color,
      fontSize: b.fontSize,
      isBold: b.isBold,
      hasBackground: b.hasBackground,
      isItalic: b.isItalic,
      isUnderline: b.isUnderline
    )).toList();
  }

  void resizeSelection(Offset position) {
    if (_activeResizeHandle == null || _dragInitialRect == null || _dragStartPos == null) return;

    final initialRect = _dragInitialRect!;

    Offset pivot;
    Offset oldCorner;

    switch (_activeResizeHandle) {
      case 'tl':
        pivot = initialRect.bottomRight;
        oldCorner = initialRect.topLeft;
        break;
      case 'tr':
        pivot = initialRect.bottomLeft;
        oldCorner = initialRect.topRight;
        break;
      case 'bl':
        pivot = initialRect.topRight;
        oldCorner = initialRect.bottomLeft;
        break;
      case 'br':
        pivot = initialRect.topLeft;
        oldCorner = initialRect.bottomRight;
        break;
      default:
        return;
    }

    double scaleX = (position.dx - pivot.dx) / (oldCorner.dx - pivot.dx);
    double scaleY = (position.dy - pivot.dy) / (oldCorner.dy - pivot.dy);

    if (scaleX.abs() < 0.1) scaleX = 0.1 * scaleX.sign;
    if (scaleY.abs() < 0.1) scaleY = 0.1 * scaleY.sign;

    for (int i = 0; i < _selectedStrokes.length; i++) {
      var initialStroke = _dragInitialStrokes[i];
      var currentStroke = _selectedStrokes[i];

      final newPoints = initialStroke.points.map((p) => StrokePoint(
        x: pivot.dx + (p.x - pivot.dx) * scaleX,
        y: pivot.dy + (p.y - pivot.dy) * scaleY,
        pressure: p.pressure,
      )).toList();

      final index = _currentNote!.strokes.indexOf(currentStroke);
      if (index != -1) {
        _currentNote!.strokes[index] = Stroke(
          points: newPoints,
          color: initialStroke.color,
          width: initialStroke.width * (scaleX.abs() + scaleY.abs()) / 2,
          createdAt: initialStroke.createdAt,
          toolType: initialStroke.toolType,
        );
        _selectedStrokes[i] = _currentNote!.strokes[index];
      }
    }

    for (int i = 0; i < _selectedImages.length; i++) {
      var initialImg = _dragInitialImages[i];
      var currentImg = _selectedImages[i];

      currentImg.width = (initialImg.width * scaleX).abs().clamp(50, 2000);
      currentImg.height = (initialImg.height * scaleY).abs().clamp(50, 2000);
      currentImg.x = pivot.dx + (initialImg.x - pivot.dx) * scaleX;
      currentImg.y = pivot.dy + (initialImg.y - pivot.dy) * scaleY;
    }

    for (int i = 0; i < _selectedTextBlocks.length; i++) {
      var initialBlock = _dragInitialTextBlocks[i];
      var currentBlock = _selectedTextBlocks[i];

      final index = _currentNote!.textBlocks.indexOf(currentBlock);
      if (index != -1) {
        _currentNote!.textBlocks[index] = TextBlock(
          id: initialBlock.id,
          text: initialBlock.text,
          x: pivot.dx + (initialBlock.x - pivot.dx) * scaleX,
          y: pivot.dy + (initialBlock.y - pivot.dy) * scaleY,
          createdAt: initialBlock.createdAt,
          color: initialBlock.color,
          fontSize: (initialBlock.fontSize * ((scaleX.abs() + scaleY.abs()) / 2)).clamp(10.0, 150.0),
          isBold: initialBlock.isBold,
          hasBackground: initialBlock.hasBackground,
          isItalic: initialBlock.isItalic,
          isUnderline: initialBlock.isUnderline,
        );
        _selectedTextBlocks[i] = _currentNote!.textBlocks[index];
      }
    }

    _selectionRect = _calculateSelectionBounds()?.inflate(10);
    notifyListeners();
  }

  Rect? _calculateSelectionBounds() {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;

    for (var stroke in _selectedStrokes) {
      for (var p in stroke.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
    }

    for (var img in _selectedImages) {
      if (img.x < minX) minX = img.x;
      if (img.x + img.width > maxX) maxX = img.x + img.width;
      if (img.y < minY) minY = img.y;
      if (img.y + img.height > maxY) maxY = img.y + img.height;
    }

    for (var block in _selectedTextBlocks) {
      if (block.x < minX) minX = block.x;
      if (block.x + 100 > maxX) maxX = block.x + 100; // rough width estimate
      if (block.y < minY) minY = block.y;
      if (block.y + 30 > maxY) maxY = block.y + 30; // rough height estimate
    }

    if (minX == double.infinity) return null;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool get isResizing => _activeResizeHandle != null;

  void endResize() {
    _activeResizeHandle = null;
    _selectionRect = _calculateSelectionBounds()?.inflate(10);
    _dragInitialStrokes.clear();
    _dragInitialTextBlocks.clear();
    _dragInitialImages.clear();
    saveNote();
  }

  void setNote(Note note) {
    _currentNote = note;
    _undoStack.clear();
    _redoStack.clear();
    _startStudyTracking();
    notifyListeners();
  }

  void _startStudyTracking() {
    _studyStopwatch.reset();
    _studyStopwatch.start();
    _studyTimer?.cancel();
    _studyTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateStudyTime();
    });
  }

  void _updateStudyTime() {
    if (!_studyStopwatch.isRunning) return;
    final elapsedSeconds = _studyStopwatch.elapsed.inSeconds;
    _studyStopwatch.reset();
    _studyStopwatch.start();

    final profile = _repository.getStudentProfile();
    profile.totalStudyTimeSeconds += elapsedSeconds;
    _repository.saveStudentProfile(profile);
  }

  void stopStudyTracking() {
    _updateStudyTime();
    _studyStopwatch.stop();
    _studyTimer?.cancel();
  }

  void setPlaybackTime(int? time) {
    _playbackTime = time;
    notifyListeners();
  }

  void clearSelection() {
    _selectedStrokes = [];
    _selectedTextBlocks = [];
    _selectedImages = [];
    _selectionRect = null;
    notifyListeners();
  }

  void setActiveTool(CanvasTool tool) {
    _activeTool = tool;
    if (tool != CanvasTool.select) {
      _selectedStrokes = [];
      _selectedTextBlocks = [];
      _selectedImages = [];
    }
    notifyListeners();
  }

  void setTemplate(String type) {
    if (_currentNote == null) return;
    _currentNote!.templateType = type;
    saveNote();
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setWidth(double val) {
    _currentWidth = val;
    notifyListeners();
  }

  bool _isPenType(CanvasTool tool) {
    return [
      CanvasTool.pen,
      CanvasTool.monoline,
      CanvasTool.fountain,
      CanvasTool.reed,
      CanvasTool.watercolor,
      CanvasTool.pencil,
      CanvasTool.marker,
      CanvasTool.highlighter,
      CanvasTool.brush,
    ].contains(tool);
  }

  void startStroke(Offset offset, double pressure, {int? timestamp}) {
    if (_currentNote == null) return;
    if (_isPenType(_activeTool)) {
      _activePoints = [
        StrokePoint(x: offset.dx, y: offset.dy, pressure: pressure),
      ];
    }
  }

  void updateStroke(Offset offset, double pressure) {
    if (_currentNote == null || !_isPenType(_activeTool)) return;

    // Performance: Don't add point if it's too close to the last one
    if (_activePoints.isNotEmpty) {
      final last = _activePoints.last;
      if ((last.x - offset.dx).abs() < 1.0 &&
          (last.y - offset.dy).abs() < 1.0) {
        return;
      }
    }

    _activePoints.add(
      StrokePoint(x: offset.dx, y: offset.dy, pressure: pressure),
    );
    notifyListeners();
  }

  void endStroke({int? timestamp, List<StrokePoint>? forcedPoints}) {
    if (_currentNote == null ||
        !_isPenType(_activeTool) ||
        _activePoints.isEmpty) {
      return;
    }

    if (forcedPoints == null && _checkForGestures(_activePoints)) {
      _activePoints = [];
      notifyListeners();
      return;
    }

    _takeSnapshot();

    List<StrokePoint> pointsToSave = forcedPoints ?? List.from(_activePoints);

    Color strokeColor = _currentColor;
    double strokeWidth = _currentWidth;

    if (_activeTool == CanvasTool.highlighter) {
      strokeColor = _currentColor.withValues(alpha: 0.3 * _currentOpacity);
      strokeWidth = _currentWidth * 4;
    } else {
      strokeColor = _currentColor.withValues(alpha: _currentOpacity);
    }

    final stroke = Stroke(
      points: pointsToSave,
      color: strokeColor.toARGB32(),
      width: strokeWidth,
      createdAt: timestamp ?? -1,
      toolType: _activeTool.name,
    );

    _currentNote!.strokes.add(stroke);
    _activePoints = [];

    // --- Shape Recognition ---
    final shape = GeometryUtils.recognizeShape(pointsToSave);
    if (shape != null) {
      // Replace last stroke with shape points
      _currentNote!.strokes.removeLast();
      _currentNote!.strokes.add(
        Stroke(
          points: shape.points,
          color: strokeColor.toARGB32(),
          width: strokeWidth,
          createdAt: timestamp ?? -1,
          toolType: _activeTool.name,
        ),
      );
    }

    saveNote();
    notifyListeners();
  }

  bool _checkForGestures(List<StrokePoint> points) {
    if (GeometryUtils.isClosedLoop(points)) {
      final insideStrokes = <Stroke>[];
      final insideBlocks = <TextBlock>[];
      final insideImages = <ImageBlock>[];

      for (var stroke in _currentNote!.strokes) {
        if (stroke.points.isNotEmpty) {
          final center = stroke.points[stroke.points.length ~/ 2];
          if (GeometryUtils.isPointInPolygon(
            Offset(center.x, center.y),
            points,
          )) {
            insideStrokes.add(stroke);
          }
        }
      }

      for (var block in _currentNote!.textBlocks) {
        if (GeometryUtils.isPointInPolygon(Offset(block.x, block.y), points)) {
          insideBlocks.add(block);
        }
      }

      for (var img in _currentNote!.images) {
        if (GeometryUtils.isPointInPolygon(
          Offset(img.x + img.width / 2, img.y + img.height / 2),
          points,
        )) {
          insideImages.add(img);
        }
      }

      if (insideStrokes.isNotEmpty ||
          insideBlocks.isNotEmpty ||
          insideImages.isNotEmpty) {
        _takeSnapshot();
        _selectedStrokes = insideStrokes;
        _selectedTextBlocks = insideBlocks;
        _selectedImages = insideImages;
        _activeTool = CanvasTool.select;
        notifyListeners();
        return true;
      }
    }

    if (GeometryUtils.isScribble(points)) {
      final scribbleBox = GeometryUtils.getBoundingBox(points);
      bool erasedSomething = false;

      _currentNote!.strokes.removeWhere((stroke) {
        final strokeBox = GeometryUtils.getBoundingBox(stroke.points);
        if (GeometryUtils.doRectsIntersect(scribbleBox, strokeBox)) {
          if (!erasedSomething) _takeSnapshot();
          erasedSomething = true;
          return true;
        }
        return false;
      });

      _currentNote!.textBlocks.removeWhere((block) {
        final blockRect = Rect.fromLTWH(block.x, block.y, 100, 30);
        if (scribbleBox.overlaps(blockRect)) {
          if (!erasedSomething) _takeSnapshot();
          erasedSomething = true;
          return true;
        }
        return false;
      });

      _currentNote!.images.removeWhere((img) {
        final imgRect = Rect.fromLTWH(img.x, img.y, img.width, img.height);
        if (scribbleBox.overlaps(imgRect)) {
          if (!erasedSomething) _takeSnapshot();
          erasedSomething = true;
          return true;
        }
        return false;
      });

      if (erasedSomething) {
        saveNote();
        return true;
      }
    }
    return false;
  }

  void eraseAt(Offset offset) {
    if (_currentNote == null || _activeTool != CanvasTool.eraser) return;

    final eraserRadius = _currentWidth * 5.0;
    final radiusSq = eraserRadius * eraserRadius;
    bool contentChanged = false;

    // 1. Handle Strokes
    if (_eraserMode == EraserMode.object) {
      final initialCount = _currentNote!.strokes.length;
      _currentNote!.strokes.removeWhere((stroke) {
        // Check if any point is within eraser radius
        for (final p in stroke.points) {
          if ((Offset(p.x, p.y) - offset).distanceSquared < radiusSq) {
            return true;
          }
        }
        return false;
      });
      if (_currentNote!.strokes.length != initialCount) {
        if (!contentChanged) _takeSnapshot();
        contentChanged = true;
      }
    } else {
      // Pixel Eraser (Split Strokes)
      final List<Stroke> newStrokes = [];
      bool strokesChanged = false;

      for (final stroke in _currentNote!.strokes) {
        // Optimization: Check bounding box first
        bool fastCheck = false;
        for (final p in stroke.points) {
          if ((p.x - offset.dx).abs() < eraserRadius &&
              (p.y - offset.dy).abs() < eraserRadius) {
            fastCheck = true;
            break;
          }
        }

        if (!fastCheck) {
          newStrokes.add(stroke);
          continue;
        }

        // Check if any point is actually inside the circle
        bool isHit = false;
        for (final p in stroke.points) {
          if ((Offset(p.x, p.y) - offset).distanceSquared < radiusSq) {
            isHit = true;
            break;
          }
        }

        if (!isHit) {
          newStrokes.add(stroke);
          continue;
        }

        // Hit detected: Split the stroke
        if (!strokesChanged) {
          if (!contentChanged) _takeSnapshot();
          contentChanged = true;
          strokesChanged = true;
        }

        List<StrokePoint> currentSegment = [];
        for (final p in stroke.points) {
          if ((Offset(p.x, p.y) - offset).distanceSquared >= radiusSq) {
            currentSegment.add(p);
          } else {
            // Point is inside eraser, end current segment
            if (currentSegment.isNotEmpty) {
              if (currentSegment.length > 1) {
                newStrokes.add(
                  Stroke(
                    points: List.from(currentSegment),
                    color: stroke.color,
                    width: stroke.width,
                    createdAt: stroke.createdAt,
                    toolType: stroke.toolType,
                  ),
                );
              }
              currentSegment = [];
            }
          }
        }
        // Add trailing segment
        if (currentSegment.isNotEmpty) {
          if (currentSegment.length > 1) {
            newStrokes.add(
              Stroke(
                points: List.from(currentSegment),
                color: stroke.color,
                width: stroke.width,
                createdAt: stroke.createdAt,
                toolType: stroke.toolType,
              ),
            );
          }
        }
      }

      if (strokesChanged) {
        _currentNote!.strokes.clear();
        _currentNote!.strokes.addAll(newStrokes);
      }
    }

    // 2. Handle Text Blocks (Standard Erasure)
    _currentNote!.textBlocks.removeWhere((block) {
      if ((Offset(block.x, block.y) - offset).distance < 30.0 + eraserRadius) {
        if (!contentChanged) {
          _takeSnapshot();
          contentChanged = true;
        }
        return true;
      }
      return false;
    });

    // 3. Handle Images (Standard Erasure)
    _currentNote!.images.removeWhere((img) {
      final rect = Rect.fromLTWH(img.x, img.y, img.width, img.height);
      if (rect.contains(offset)) {
        if (!contentChanged) {
          _takeSnapshot();
          contentChanged = true;
        }
        return true;
      }
      return false;
    });

    if (contentChanged) {
      saveNote();
      notifyListeners();
    }
  }

  void startMove(Offset position) {
    _takeSnapshot();
    _cacheDragInitialState(position);
  }

  void addTextBlock(Offset offset, {int? timestamp}) {
    if (_currentNote == null) return;
    _takeSnapshot();
    final block = TextBlock(
      id: const Uuid().v4(),
      text: '',
      x: offset.dx,
      y: offset.dy,
      createdAt: timestamp ?? -1,
    );
    _currentNote!.textBlocks.add(block);
    _selectedTextBlocks = [block];
    notifyListeners();
  }

  void addImage(
    String base64Data,
    Offset offset, {
    int? timestamp,
    double? width,
    double? height,
  }) {
    if (_currentNote == null) return;
    _takeSnapshot();
    final img = ImageBlock(
      id: const Uuid().v4(),
      base64Data: base64Data,
      x: offset.dx,
      y: offset.dy,
      width: width ?? 300,
      height: height ?? 300,
      createdAt: timestamp ?? -1,
    );
    _currentNote!.images.add(img);
    saveNote();
    notifyListeners();
  }

  void updateTextBlock(String id, String text) {
    if (_currentNote == null) return;
    final index = _currentNote!.textBlocks.indexWhere((b) => b.id == id);
    if (index != -1) {
      final oldBlock = _currentNote!.textBlocks[index];
      final newBlock = TextBlock(
        id: id,
        text: text,
        x: oldBlock.x,
        y: oldBlock.y,
        createdAt: oldBlock.createdAt,
        color: oldBlock.color,
        fontSize: oldBlock.fontSize,
        isBold: oldBlock.isBold,
        hasBackground: oldBlock.hasBackground,
        isItalic: oldBlock.isItalic,
        isUnderline: oldBlock.isUnderline,
      );
      _currentNote!.textBlocks[index] = newBlock;

      // Update selection if needed
      final selIndex = _selectedTextBlocks.indexWhere((b) => b.id == id);
      if (selIndex != -1) {
        _selectedTextBlocks[selIndex] = newBlock;
      }

      saveNote();
      notifyListeners();
    }
  }

  void updateTextBlockStyle(
    String id, {
    int? color,
    double? fontSize,
    bool? isBold,
    bool? hasBackground,
    bool? isItalic,
    bool? isUnderline,
  }) {
    if (_currentNote == null) return;
    final index = _currentNote!.textBlocks.indexWhere((b) => b.id == id);
    if (index != -1) {
      final oldBlock = _currentNote!.textBlocks[index];
      final newBlock = TextBlock(
        id: id,
        text: oldBlock.text,
        x: oldBlock.x,
        y: oldBlock.y,
        createdAt: oldBlock.createdAt,
        color: color ?? oldBlock.color,
        fontSize: fontSize ?? oldBlock.fontSize,
        isBold: isBold ?? oldBlock.isBold,
        hasBackground: hasBackground ?? oldBlock.hasBackground,
        isItalic: isItalic ?? oldBlock.isItalic,
        isUnderline: isUnderline ?? oldBlock.isUnderline,
      );
      _currentNote!.textBlocks[index] = newBlock;

      // Update selection if needed
      final selIndex = _selectedTextBlocks.indexWhere((b) => b.id == id);
      if (selIndex != -1) {
        _selectedTextBlocks[selIndex] = newBlock;
      }

      saveNote();
      notifyListeners();
    }
  }

  void moveTextBlock(String id, Offset offset) {
    if (_currentNote == null) return;
    final index = _currentNote!.textBlocks.indexWhere((b) => b.id == id);
    if (index != -1) {
      final oldBlock = _currentNote!.textBlocks[index];
      final newBlock = TextBlock(
        id: id,
        text: oldBlock.text,
        x: offset.dx,
        y: offset.dy,
        createdAt: oldBlock.createdAt,
        color: oldBlock.color,
        fontSize: oldBlock.fontSize,
        isBold: oldBlock.isBold,
        hasBackground: oldBlock.hasBackground,
        isItalic: oldBlock.isItalic,
        isUnderline: oldBlock.isUnderline,
      );
      _currentNote!.textBlocks[index] = newBlock;

      // Update selection if needed
      final selIndex = _selectedTextBlocks.indexWhere((b) => b.id == id);
      if (selIndex != -1) {
        _selectedTextBlocks[selIndex] = newBlock;
      }

      saveNote();
      notifyListeners();
    }
  }

  void moveSelection(Offset delta, {Offset? absolutePosition}) {
    if (_currentNote == null) return;

    if (absolutePosition != null && _dragStartPos != null) {
      // Use absolute cached drag state to prevent accumulative floating errors
      final totalDelta = absolutePosition - _dragStartPos!;
      
      for (int i = 0; i < _selectedStrokes.length; i++) {
        var initialStroke = _dragInitialStrokes[i];
        var currentStroke = _selectedStrokes[i];
        
        final newPoints = initialStroke.points
            .map((p) => StrokePoint(
                  x: p.x + totalDelta.dx,
                  y: p.y + totalDelta.dy,
                  pressure: p.pressure,
                ))
            .toList();
        final index = _currentNote!.strokes.indexOf(currentStroke);
        if (index != -1) {
          _currentNote!.strokes[index] = Stroke(
            points: newPoints,
            color: initialStroke.color,
            width: initialStroke.width,
            createdAt: initialStroke.createdAt,
            toolType: initialStroke.toolType,
          );
          _selectedStrokes[i] = _currentNote!.strokes[index];
        }
      }

      for (int i = 0; i < _selectedTextBlocks.length; i++) {
        var initialBlock = _dragInitialTextBlocks[i];
        var currentBlock = _selectedTextBlocks[i];
        final index = _currentNote!.textBlocks.indexOf(currentBlock);
        if (index != -1) {
          _currentNote!.textBlocks[index] = TextBlock(
            id: initialBlock.id,
            text: initialBlock.text,
            x: initialBlock.x + totalDelta.dx,
            y: initialBlock.y + totalDelta.dy,
            createdAt: initialBlock.createdAt,
            color: initialBlock.color,
            fontSize: initialBlock.fontSize,
            isBold: initialBlock.isBold,
            hasBackground: initialBlock.hasBackground,
            isItalic: initialBlock.isItalic,
            isUnderline: initialBlock.isUnderline,
          );
          _selectedTextBlocks[i] = _currentNote!.textBlocks[index];
        }
      }

      for (int i = 0; i < _selectedImages.length; i++) {
        var initialImg = _dragInitialImages[i];
        var currentImg = _selectedImages[i];
        currentImg.x = initialImg.x + totalDelta.dx;
        currentImg.y = initialImg.y + totalDelta.dy;
      }
    } else {
      // Fallback relative movement
      for (var stroke in _selectedStrokes) {
        final newPoints = stroke.points
            .map(
              (p) => StrokePoint(
                x: p.x + delta.dx,
                y: p.y + delta.dy,
                pressure: p.pressure,
              ),
            )
            .toList();
        final index = _currentNote!.strokes.indexOf(stroke);
        if (index != -1) {
          _currentNote!.strokes[index] = Stroke(
            points: newPoints,
            color: stroke.color,
            width: stroke.width,
            createdAt: stroke.createdAt,
            toolType: stroke.toolType,
          );
          _selectedStrokes[_selectedStrokes.indexOf(stroke)] =
              _currentNote!.strokes[index];
        }
      }
      for (var block in _selectedTextBlocks) {
        final index = _currentNote!.textBlocks.indexOf(block);
        if (index != -1) {
          final oldBlock = _currentNote!.textBlocks[index];
          _currentNote!.textBlocks[index] = TextBlock(
            id: block.id,
            text: block.text,
            x: block.x + delta.dx,
            y: block.y + delta.dy,
            createdAt: block.createdAt,
            color: oldBlock.color,
            fontSize: oldBlock.fontSize,
            isBold: oldBlock.isBold,
            hasBackground: oldBlock.hasBackground,
            isItalic: oldBlock.isItalic,
            isUnderline: oldBlock.isUnderline,
          );
          _selectedTextBlocks[_selectedTextBlocks.indexOf(block)] =
              _currentNote!.textBlocks[index];
        }
      }
      for (var img in _selectedImages) {
        img.x += delta.dx;
        img.y += delta.dy;
      }
    }

    _selectionRect = _calculateSelectionBounds()?.inflate(10);
    notifyListeners();
  }

  void endMove() {
    _dragInitialStrokes.clear();
    _dragInitialTextBlocks.clear();
    _dragInitialImages.clear();
    saveNote();
  }

  bool hitTestSelection(Offset position) {
    if (_selectedStrokes.isEmpty && _selectedTextBlocks.isEmpty && _selectedImages.isEmpty) {
      return false;
    }
    final rect = _calculateSelectionBounds();
    if (rect == null) return false;
    if (rect.inflate(10).contains(position)) {
      return true;
    }
    return false;
  }

  void startLasso(Offset position) {
    _lassoPath = [position];
    notifyListeners();
  }

  void updateLasso(Offset position) {
    if (_lassoPath.isNotEmpty) {
      _lassoPath.add(position);
      notifyListeners();
    }
  }

  void endLasso() {
    if (_currentNote == null || _lassoPath.length < 3) {
      _lassoPath = [];
      clearSelection();
      notifyListeners();
      return;
    }

    final insideStrokes = <Stroke>[];
    final insideBlocks = <TextBlock>[];
    final insideImages = <ImageBlock>[];

    final polygon = _lassoPath.map((o) => StrokePoint(x: o.dx, y: o.dy)).toList();

    for (var stroke in _currentNote!.strokes) {
      if (stroke.points.isNotEmpty) {
        bool isInside = false;
        for (var p in stroke.points) {
          if (GeometryUtils.isPointInPolygon(Offset(p.x, p.y), polygon)) {
            isInside = true;
            break;
          }
        }
        if (isInside) insideStrokes.add(stroke);
      }
    }

    for (var block in _currentNote!.textBlocks) {
      if (GeometryUtils.isPointInPolygon(Offset(block.x, block.y), polygon)) {
        insideBlocks.add(block);
      }
    }

    for (var img in _currentNote!.images) {
      if (GeometryUtils.isPointInPolygon(
        Offset(img.x + img.width / 2, img.y + img.height / 2),
        polygon,
      )) {
        insideImages.add(img);
      }
    }

    _selectedStrokes = insideStrokes;
    _selectedTextBlocks = insideBlocks;
    _selectedImages = insideImages;
    _lassoPath = [];
    notifyListeners();
  }

  bool selectItemAt(Offset position, AudioProvider audioProvider) {
    if (_currentNote == null) return false;

    // Images first
    for (var img in _currentNote!.images) {
      final rect = Rect.fromLTWH(img.x, img.y, img.width, img.height);
      if (rect.contains(position)) {
        _selectedImages = [img];
        _selectedStrokes = [];
        _selectedTextBlocks = [];
        _jumpToTimestamp(img.createdAt, audioProvider);
        notifyListeners();
        return true;
      }
    }

    for (var block in _currentNote!.textBlocks) {
      final blockRect = Rect.fromLTWH(block.x, block.y, 100, 30);
      if (blockRect.contains(position)) {
        _selectedTextBlocks = [block];
        _selectedStrokes = [];
        _selectedImages = [];
        _jumpToTimestamp(block.createdAt, audioProvider);
        notifyListeners();
        return true;
      }
    }
    for (var stroke in _currentNote!.strokes) {
      for (var p in stroke.points) {
        if ((Offset(p.x, p.y) - position).distance < 20.0) {
          _selectedStrokes = [stroke];
          _selectedTextBlocks = [];
          _selectedImages = [];
          _jumpToTimestamp(stroke.createdAt, audioProvider);
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }

  void _jumpToTimestamp(int timestamp, AudioProvider audio) {
    if (timestamp != -1) {
      audio.seek(Duration(milliseconds: timestamp));
    }
  }

  Future<void> saveNote() async {
    if (_currentNote != null) {
      await _repository.saveNote(_currentNote!);
      _debounceTimer?.cancel();
      _debounceTimer?.cancel();
      // Auto-save logic is handled by local repository save above.
      // Cloud sync should be triggered by CloudStorageService listener or periodic sync.
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _studyTimer?.cancel();
    _studyStopwatch.stop();
    super.dispose();
  }
}
