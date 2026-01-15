import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/repositories/supabase_repository.dart';
import 'package:classlly/core/utils/geometry_utils.dart';
import 'package:classlly/core/theme/app_theme.dart';

enum CanvasTool { pen, eraser, text, select, hand, highlighter }

class NoteStateSnapshot {
  final List<Stroke> strokes;
  final List<TextBlock> textBlocks;
  NoteStateSnapshot({required this.strokes, required this.textBlocks});
}

class CanvasProvider with ChangeNotifier {
  final NotesRepository _repository = NotesRepository();
  final SupabaseRepository _remoteRepository = SupabaseRepository();

  // History Stacks
  final List<NoteStateSnapshot> _undoStack = [];
  final List<NoteStateSnapshot> _redoStack = [];

  Note? _currentNote;
  Note? get currentNote => _currentNote;

  CanvasTool _activeTool = CanvasTool.pen;
  CanvasTool get activeTool => _activeTool;

  Color _currentColor = AppTheme.noteColors[0];
  Color get currentColor => _currentColor;

  double _currentWidth = 3.0;
  double get currentWidth => _currentWidth;

  int? _playbackTime;
  int? get playbackTime => _playbackTime;

  List<StrokePoint> _activePoints = [];
  List<StrokePoint> get activePoints => _activePoints;

  List<Stroke> _selectedStrokes = [];
  List<TextBlock> _selectedTextBlocks = [];

  List<Stroke> get selectedStrokes => _selectedStrokes;
  List<TextBlock> get selectedTextBlocks => _selectedTextBlocks;

  String? _activeResizeHandle;
  Rect? _selectionRect;

  ShapeResult? _ghostShape;
  ShapeResult? get ghostShape => _ghostShape;

  Timer? _debounceTimer;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _takeSnapshot() {
    if (_currentNote == null) return;
    _undoStack.add(NoteStateSnapshot(
      strokes: List.from(_currentNote!.strokes),
      textBlocks: List.from(_currentNote!.textBlocks),
    ));
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    notifyListeners();
  }

  void undo() {
    if (!canUndo || _currentNote == null) return;
    _redoStack.add(NoteStateSnapshot(
      strokes: List.from(_currentNote!.strokes),
      textBlocks: List.from(_currentNote!.textBlocks),
    ));
    final snapshot = _undoStack.removeLast();
    _currentNote!.strokes.clear();
    _currentNote!.strokes.addAll(snapshot.strokes);
    _currentNote!.textBlocks.clear();
    _currentNote!.textBlocks.addAll(snapshot.textBlocks);
    notifyListeners();
    saveNote();
  }

  void redo() {
    if (!canRedo || _currentNote == null) return;
    _undoStack.add(NoteStateSnapshot(
      strokes: List.from(_currentNote!.strokes),
      textBlocks: List.from(_currentNote!.textBlocks),
    ));
    final snapshot = _redoStack.removeLast();
    _currentNote!.strokes.clear();
    _currentNote!.strokes.addAll(snapshot.strokes);
    _currentNote!.textBlocks.clear();
    _currentNote!.textBlocks.addAll(snapshot.textBlocks);
    notifyListeners();
    saveNote();
  }

  void setGhostShape(ShapeResult? shape) {
    _ghostShape = shape;
    notifyListeners();
  }

  void startResize(Offset position) {
    if (_selectedStrokes.isEmpty && _selectedTextBlocks.isEmpty) return;
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
    if (_activeResizeHandle != null) _takeSnapshot();
  }

  void resizeSelection(Offset position) {
    if (_activeResizeHandle == null || _selectionRect == null) return;

    Offset pivot;
    Offset oldCorner;
    
    switch (_activeResizeHandle) {
      case 'tl': pivot = _selectionRect!.bottomRight; oldCorner = _selectionRect!.topLeft; break;
      case 'tr': pivot = _selectionRect!.bottomLeft; oldCorner = _selectionRect!.topRight; break;
      case 'bl': pivot = _selectionRect!.topRight; oldCorner = _selectionRect!.bottomLeft; break;
      case 'br': pivot = _selectionRect!.topLeft; oldCorner = _selectionRect!.bottomRight; break;
      default: return;
    }

    double scaleX = (position.dx - pivot.dx) / (oldCorner.dx - pivot.dx);
    double scaleY = (position.dy - pivot.dy) / (oldCorner.dy - pivot.dy);
    
    if (scaleX.abs() < 0.1) scaleX = 0.1;
    if (scaleY.abs() < 0.1) scaleY = 0.1;

    for (var stroke in _selectedStrokes) {
      final newPoints = stroke.points.map((p) => StrokePoint(
        x: pivot.dx + (p.x - pivot.dx) * scaleX,
        y: pivot.dy + (p.y - pivot.dy) * scaleY,
        pressure: p.pressure,
      )).toList();
      
      final index = _currentNote!.strokes.indexOf(stroke);
      if (index != -1) {
        _currentNote!.strokes[index] = Stroke(
          points: newPoints,
          color: stroke.color,
          width: stroke.width * (scaleX + scaleY) / 2,
          createdAt: stroke.createdAt,
        );
        _selectedStrokes[_selectedStrokes.indexOf(stroke)] = _currentNote!.strokes[index];
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
    
    if (minX == double.infinity) return null;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool get isResizing => _activeResizeHandle != null;

  void endResize() {
    _activeResizeHandle = null;
    _selectionRect = null;
    saveNote();
  }

  void setNote(Note note) {
    _currentNote = note;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void setPlaybackTime(int? time) {
    _playbackTime = time;
    notifyListeners();
  }

  void setActiveTool(CanvasTool tool) {
    _activeTool = tool;
    if (tool != CanvasTool.select) {
      _selectedStrokes = [];
      _selectedTextBlocks = [];
    }
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setWidth(double width) {
    _currentWidth = width;
    notifyListeners();
  }

  void startStroke(Offset offset, double pressure, {int? timestamp}) {
    if (_currentNote == null) return;
    if (_activeTool == CanvasTool.pen || _activeTool == CanvasTool.highlighter) {
      _activePoints = [StrokePoint(x: offset.dx, y: offset.dy, pressure: pressure)];
    }
  }

  void updateStroke(Offset offset, double pressure) {
    if (_currentNote == null || (_activeTool != CanvasTool.pen && _activeTool != CanvasTool.highlighter)) return;
    _activePoints.add(StrokePoint(x: offset.dx, y: offset.dy, pressure: pressure));
    notifyListeners();
  }

  void endStroke({int? timestamp, List<StrokePoint>? forcedPoints}) {
    if (_currentNote == null || (_activeTool != CanvasTool.pen && _activeTool != CanvasTool.highlighter) || _activePoints.isEmpty) return;

    if (forcedPoints == null && _checkForGestures(_activePoints)) {
      _activePoints = [];
      notifyListeners();
      return;
    }

    _takeSnapshot();

    List<StrokePoint> pointsToSave = forcedPoints ?? List.from(_activePoints);
    if (forcedPoints == null) {
      final shape = GeometryUtils.recognizeShape(pointsToSave);
      if (shape != null) pointsToSave = shape.points;
    }

    Color strokeColor = _currentColor;
    double strokeWidth = _currentWidth;

    if (_activeTool == CanvasTool.highlighter) {
      strokeColor = _currentColor.withOpacity(0.3);
      strokeWidth = _currentWidth * 4;
    }

    final stroke = Stroke(
      points: pointsToSave,
      color: strokeColor.value,
      width: strokeWidth,
      createdAt: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );

    _currentNote!.strokes.add(stroke);
    _activePoints = [];
    saveNote();
    notifyListeners();
  }

  bool _checkForGestures(List<StrokePoint> points) {
    if (GeometryUtils.isClosedLoop(points)) {
      final insideStrokes = <Stroke>[];
      final insideBlocks = <TextBlock>[];

      for (var stroke in _currentNote!.strokes) {
        if (stroke.points.isNotEmpty) {
          final center = stroke.points[stroke.points.length ~/ 2];
          if (GeometryUtils.isPointInPolygon(Offset(center.x, center.y), points)) {
            insideStrokes.add(stroke);
          }
        }
      }

      for (var block in _currentNote!.textBlocks) {
        if (GeometryUtils.isPointInPolygon(Offset(block.x, block.y), points)) {
          insideBlocks.add(block);
        }
      }

      if (insideStrokes.isNotEmpty || insideBlocks.isNotEmpty) {
        _takeSnapshot();
        _selectedStrokes = insideStrokes;
        _selectedTextBlocks = insideBlocks;
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

      if (erasedSomething) {
        saveNote();
        return true;
      }
    }
    return false;
  }

  void eraseAt(Offset offset) {
    if (_currentNote == null || _activeTool != CanvasTool.eraser) return;
    
    bool erased = false;
    _currentNote!.strokes.removeWhere((stroke) {
      for (var point in stroke.points) {
        if ((Offset(point.x, point.y) - offset).distance < 10.0) {
          if (!erased) _takeSnapshot();
          erased = true;
          return true;
        }
      }
      return false;
    });
    
    _currentNote!.textBlocks.removeWhere((block) {
      if ((Offset(block.x, block.y) - offset).distance < 30.0) {
        if (!erased) _takeSnapshot();
        erased = true;
        return true;
      }
      return false;
    });

    if (erased) {
      saveNote();
      notifyListeners();
    }
  }

  void startMove() {
    _takeSnapshot();
  }

  void addTextBlock(Offset offset, {int? timestamp}) {
    if (_currentNote == null) return;
    _takeSnapshot();
    final block = TextBlock(
      id: const Uuid().v4(),
      text: '',
      x: offset.dx,
      y: offset.dy,
      createdAt: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );
    _currentNote!.textBlocks.add(block);
    notifyListeners();
  }

  void updateTextBlock(String id, String text) {
    if (_currentNote == null) return;
    final index = _currentNote!.textBlocks.indexWhere((b) => b.id == id);
    if (index != -1) {
      _currentNote!.textBlocks[index] = TextBlock(
        id: id,
        text: text,
        x: _currentNote!.textBlocks[index].x,
        y: _currentNote!.textBlocks[index].y,
        createdAt: _currentNote!.textBlocks[index].createdAt,
      );
      saveNote();
      notifyListeners();
    }
  }

  void moveTextBlock(String id, Offset offset) {
    if (_currentNote == null) return;
    final index = _currentNote!.textBlocks.indexWhere((b) => b.id == id);
    if (index != -1) {
      _currentNote!.textBlocks[index] = TextBlock(
        id: id,
        text: _currentNote!.textBlocks[index].text,
        x: offset.dx,
        y: offset.dy,
        createdAt: _currentNote!.textBlocks[index].createdAt,
      );
      saveNote();
      notifyListeners();
    }
  }

  void moveSelection(Offset delta) {
    if (_currentNote == null) return;
    for (var stroke in _selectedStrokes) {
      final newPoints = stroke.points.map((p) => StrokePoint(x: p.x + delta.dx, y: p.y + delta.dy, pressure: p.pressure)).toList();
      final index = _currentNote!.strokes.indexOf(stroke);
      if (index != -1) {
        _currentNote!.strokes[index] = Stroke(points: newPoints, color: stroke.color, width: stroke.width, createdAt: stroke.createdAt);
        _selectedStrokes[_selectedStrokes.indexOf(stroke)] = _currentNote!.strokes[index];
      }
    }
    for (var block in _selectedTextBlocks) {
      final index = _currentNote!.textBlocks.indexOf(block);
      if (index != -1) {
        _currentNote!.textBlocks[index] = TextBlock(id: block.id, text: block.text, x: block.x + delta.dx, y: block.y + delta.dy, createdAt: block.createdAt);
        _selectedTextBlocks[_selectedTextBlocks.indexOf(block)] = _currentNote!.textBlocks[index];
      }
    }
    notifyListeners();
  }

  Future<void> saveNote() async {
    if (_currentNote != null) {
      await _repository.saveNote(_currentNote!);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () async {
        _isSyncing = true;
        notifyListeners();
        await _remoteRepository.syncNotes();
        _isSyncing = false;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
