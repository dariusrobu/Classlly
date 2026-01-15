import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';
import 'package:classlly/features/canvas/widgets/drawing_painter.dart';
import 'package:classlly/features/canvas/widgets/text_block_widget.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/core/services/pdf_service.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final TransformationController _transformationController = TransformationController();
  final TextEditingController _titleController = TextEditingController();
  bool _isEditingTitle = false;
  
  Timer? _snapTimer;
  Offset? _lastPointerPos;

  static const double pageWidth = 1000.0;
  static const double pageHeight = 1414.0;
  static const double pageGap = 20.0;
  int _pageCount = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final title = Provider.of<CanvasProvider>(context, listen: false).currentNote?.title;
      _titleController.text = title ?? 'Untitled';
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _titleController.dispose();
    _snapTimer?.cancel();
    super.dispose();
  }

  void _startSnapTimer(BuildContext context, Offset position) {
    _snapTimer?.cancel();
    _lastPointerPos = position;
    _snapTimer = Timer(const Duration(milliseconds: 600), () {
      final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
      if (canvasProvider.activeTool == CanvasTool.pen && canvasProvider.activePoints.isNotEmpty) {
        // Logic handled in provider via recognizeShape
      }
    });
  }

  void _cancelSnapTimer() {
    _snapTimer?.cancel();
    _snapTimer = null;
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double scale = _transformationController.value.getMaxScaleOnAxis();
      final Offset delta = event.scrollDelta;
      final Matrix4 matrix = _transformationController.value.clone();
      matrix.translate(-delta.dx / scale, -delta.dy / scale);
      _transformationController.value = matrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    final textBlocks = canvasProvider.currentNote?.textBlocks ?? [];
    final bool isHandTool = canvasProvider.activeTool == CanvasTool.hand;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double pagesHeight = (_pageCount * pageHeight) + ((_pageCount - 1) * pageGap);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[300], 
      body: Stack(
        children: [
          Listener(
            onPointerSignal: _handleScroll,
            child: InteractiveViewer(
              transformationController: _transformationController,
              constrained: false, 
              boundaryMargin: EdgeInsets.zero, 
              minScale: 0.1, 
              maxScale: 5.0,
              panEnabled: isHandTool, 
              scaleEnabled: true,
              child: Container(
                padding: const EdgeInsets.all(100), 
                child: SizedBox(
                  width: pageWidth,
                  height: pagesHeight + 100,
                  child: Column(
                    children: [
                      SizedBox(
                        height: pagesHeight,
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                for (int i = 0; i < _pageCount; i++)
                                  Container(
                                    width: pageWidth,
                                    height: pageHeight,
                                    margin: EdgeInsets.only(bottom: i == _pageCount - 1 ? 0 : pageGap),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))],
                                    ),
                                  ),
                              ],
                            ),
                            Positioned.fill(child: const CanvasGestureDetector()),
                            ...textBlocks.map((block) => TextBlockWidget(key: ValueKey(block.id), block: block)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _pageCount++),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Page"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40, left: 20, right: 20,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.of(context).pop()),
                const Spacer(),
                if (_isEditingTitle)
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _titleController,
                      autofocus: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: InputBorder.none),
                      onSubmitted: (val) {
                        canvasProvider.currentNote?.title = val;
                        canvasProvider.saveNote();
                        setState(() => _isEditingTitle = false);
                      },
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _isEditingTitle = true),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canvasProvider.currentNote?.title ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (canvasProvider.isSyncing)
                          const Text("Syncing...", style: TextStyle(fontSize: 10, color: Colors.grey))
                        else 
                          const Text("Saved", style: TextStyle(fontSize: 10, color: Colors.green)),
                      ],
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  onPressed: () async {
                    if (canvasProvider.currentNote != null) await PdfService().exportNote(canvasProvider.currentNote!);
                  },
                ),
              ],
            ),
          ),
          if (!audioProvider.isPlaying) const Positioned(bottom: 30, left: 0, right: 0, child: Center(child: BottomToolbar())),
          if (audioProvider.isRecording)
            Positioned(
              top: 100, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [Icon(Icons.fiber_manual_record, color: Colors.white, size: 16), SizedBox(width: 5), Text('Recording...', style: TextStyle(color: Colors.white))]),
              ),
            ),
          if (canvasProvider.currentNote?.audioPath != null || audioProvider.isPlaying)
            const Positioned(bottom: 100, left: 20, right: 20, child: PlaybackControl()),
        ],
      ),
    );
  }
}

class CanvasGestureDetector extends StatelessWidget {
  const CanvasGestureDetector({super.key});

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    int? playbackTime = canvasProvider.playbackTime;
    if (audioProvider.isPlaying) playbackTime = audioProvider.currentPosition.inMilliseconds;

    return IgnorePointer(
      ignoring: canvasProvider.activeTool == CanvasTool.hand,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          if (canvasProvider.activeTool == CanvasTool.text) {
            canvasProvider.addTextBlock(details.localPosition, timestamp: audioProvider.isRecording ? audioProvider.elapsedRecordingMillis : null);
          }
        },
        onPanStart: (details) {
          // Access state methods
          final state = context.findAncestorStateOfType<_CanvasScreenState>();
          state?._cancelSnapTimer();

          if (canvasProvider.activeTool == CanvasTool.select) {
            canvasProvider.startResize(details.localPosition);
            if (!canvasProvider.isResizing) {
              canvasProvider.startMove(); // Snapshot for moving
            }
          }
          if (canvasProvider.isResizing) return;
          if (canvasProvider.activeTool == CanvasTool.pen || canvasProvider.activeTool == CanvasTool.highlighter) {
            canvasProvider.startStroke(details.localPosition, 1.0, timestamp: audioProvider.isRecording ? audioProvider.elapsedRecordingMillis : null);
          } else if (canvasProvider.activeTool == CanvasTool.eraser) {
            canvasProvider.eraseAt(details.localPosition);
          }
        },
        onPanUpdate: (details) {
          if (canvasProvider.isResizing) { canvasProvider.resizeSelection(details.localPosition); return; }
          if (canvasProvider.activeTool == CanvasTool.pen || canvasProvider.activeTool == CanvasTool.highlighter) {
            canvasProvider.updateStroke(details.localPosition, 1.0);
          } else if (canvasProvider.activeTool == CanvasTool.eraser) {
            canvasProvider.eraseAt(details.localPosition);
          } else if (canvasProvider.activeTool == CanvasTool.select) {
            canvasProvider.moveSelection(details.delta);
          }
        },
        onPanEnd: (details) {
          if (canvasProvider.isResizing) { canvasProvider.endResize(); return; }
          if (canvasProvider.activeTool == CanvasTool.pen || canvasProvider.activeTool == CanvasTool.highlighter) {
            canvasProvider.endStroke(timestamp: audioProvider.isRecording ? audioProvider.elapsedRecordingMillis : null);
          } else if (canvasProvider.activeTool == CanvasTool.select) {
            canvasProvider.saveNote();
          }
        },
        child: CustomPaint(
          painter: DrawingPainter(
            strokes: canvasProvider.currentNote?.strokes ?? [],
            selectedStrokes: canvasProvider.selectedStrokes,
            activePoints: canvasProvider.activePoints,
            activeColor: canvasProvider.currentColor,
            activeWidth: canvasProvider.currentWidth,
            playbackTime: playbackTime,
            ghostPoints: canvasProvider.ghostShape?.points,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class BottomToolbar extends StatelessWidget {
  const BottomToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colors
            ...AppTheme.noteColors.map((color) {
              final bool isSelected = canvasProvider.currentColor.value == color.value;
              return GestureDetector(
                onTap: () => canvasProvider.setColor(color),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: AppTheme.primaryPurple, width: 2) : null,
                  ),
                ),
              );
            }).toList(),
            
            const VerticalDivider(width: 20, indent: 5, endIndent: 5),

            _ToolButton(
              icon: Icons.undo,
              isSelected: false,
              onTap: canvasProvider.canUndo ? () => canvasProvider.undo() : () {},
              color: canvasProvider.canUndo ? null : Colors.grey.withOpacity(0.3),
            ),
            _ToolButton(
              icon: Icons.redo,
              isSelected: false,
              onTap: canvasProvider.canRedo ? () => canvasProvider.redo() : () {},
              color: canvasProvider.canRedo ? null : Colors.grey.withOpacity(0.3),
            ),

            const VerticalDivider(width: 20, indent: 5, endIndent: 5),
            
            const _AudioToolButton(),
          ],
        ),
      ),
    );
  }
}

class _AudioToolButton extends StatelessWidget {
  const _AudioToolButton();
  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    return _ToolButton(
      icon: audioProvider.isRecording ? Icons.stop : Icons.mic,
      isSelected: audioProvider.isRecording,
      color: audioProvider.isRecording ? Colors.red : null,
      onTap: () async {
        if (audioProvider.isRecording) { await audioProvider.stopRecording(); } 
        else { 
          final path = await audioProvider.startRecording(); 
          if (path != null && canvasProvider.currentNote != null) { canvasProvider.currentNote!.audioPath = path; canvasProvider.saveNote(); }
        }
      },
    );
  }
}

class PlaybackControl extends StatelessWidget {
  const PlaybackControl({super.key});
  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final canvasProvider = Provider.of<CanvasProvider>(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]),
      child: Row(
        children: [
          IconButton(
            icon: Icon(audioProvider.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () { if (audioProvider.isPlaying) { audioProvider.pause(); } else if (canvasProvider.currentNote?.audioPath != null) { audioProvider.play(canvasProvider.currentNote!.audioPath!); } },
          ),
          Expanded(child: Slider(value: audioProvider.currentPosition.inMilliseconds.toDouble(), max: audioProvider.totalDuration.inMilliseconds.toDouble() > 0 ? audioProvider.totalDuration.inMilliseconds.toDouble() : 1.0, onChanged: (val) { audioProvider.seek(Duration(milliseconds: val.toInt())); canvasProvider.setPlaybackTime(val.toInt()); })),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  const _ToolButton({required this.icon, required this.isSelected, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? (color?.withOpacity(0.2) ?? AppTheme.primaryPurple.withOpacity(0.2)) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? (isSelected ? AppTheme.primaryPurple : Theme.of(context).iconTheme.color)),
      ),
    );
  }
}
