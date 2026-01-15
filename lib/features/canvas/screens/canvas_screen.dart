import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/features/canvas/widgets/drawing_painter.dart';
import 'package:classlly/features/canvas/widgets/text_block_widget.dart';
import 'package:classlly/features/canvas/widgets/canvas_template_painter.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/core/services/pdf_service.dart';
import 'package:image_picker/image_picker.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final TransformationController _transformationController = TransformationController();
  final TextEditingController _titleController = TextEditingController();
  bool _isEditingTitle = false;
  bool _isSidebarVisible = true;
  
  static const double pageWidth = 1000.0;
  static const double pageHeight = 1414.0;
  static const double pageGap = 40.0;
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
    super.dispose();
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
      backgroundColor: isDark ? const Color(0xFF0F0F11) : Colors.grey[300], 
      body: Stack(
        children: [
          Row(
            children: [
              if (_isSidebarVisible) _buildSidebar(isDark, canvasProvider),
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(canvasProvider, audioProvider, isDark),
                    Expanded(
                      child: Stack(
                        children: [
                          Listener(
                            onPointerSignal: _handleScroll,
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              constrained: false, 
                              boundaryMargin: const EdgeInsets.all(500), 
                              minScale: 0.1, maxScale: 5.0,
                              panEnabled: isHandTool, scaleEnabled: true,
                              child: Container(
                                padding: const EdgeInsets.all(100), 
                                child: SizedBox(
                                  width: pageWidth,
                                  height: pagesHeight + 200,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: pagesHeight,
                                        child: Stack(
                                          children: [
                                            Column(children: [for (int i = 0; i < _pageCount; i++) _buildPage(i, isDark, canvasProvider.currentNote?.templateType ?? 'dot')]),
                                            Positioned.fill(child: const CanvasGestureDetector()),
                                            // Image Layer
                                            ...canvasProvider.currentNote?.images.map((img) => _buildImageWidget(img, canvasProvider)) ?? [],
                                            // Text Layer
                                            ...textBlocks.map((block) => TextBlockWidget(key: ValueKey(block.id), block: block)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      ElevatedButton.icon(
                                        onPressed: () => setState(() => _pageCount++),
                                        icon: const Icon(Icons.add), label: const Text("Add Page"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 32, left: 0, right: 0,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (audioProvider.isPlaying || canvasProvider.playbackTime != null)
                                    const Padding(padding: EdgeInsets.only(bottom: 12), child: PlaybackControl()),
                                  const _ClassllyUnifiedToolbar(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(ImageBlock img, CanvasProvider provider) {
    bool isSelected = provider.selectedImages.contains(img);
    return Positioned(
      left: img.x, top: img.y,
      child: Container(
        width: img.width, height: img.height,
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: AppTheme.primaryPurple, width: 2) : null,
        ),
        child: Image.memory(base64Decode(img.base64Data), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSidebar(bool isDark, CanvasProvider canvasProvider) {
    return Container(
      width: 240,
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0A0A0B).withOpacity(0.4) : Colors.white.withOpacity(0.4), border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05)))),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48), 
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("OUTLINE & PAGES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)), IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle, color: AppTheme.primaryPurple, size: 18))]),
          const SizedBox(height: 16),
          Expanded(child: ListView.builder(itemCount: _pageCount, itemBuilder: (context, index) => _buildPageThumbnail(index, isDark, canvasProvider.currentNote?.templateType ?? 'dot'))),
          const Divider(color: Colors.white10, height: 32),
          const Text("PAGE TEMPLATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _sidebarTemplateItem(context, "Dot Grid", Icons.apps, 'dot', canvasProvider),
          _sidebarTemplateItem(context, "Squared", Icons.grid_4x4, 'grid', canvasProvider),
          _sidebarTemplateItem(context, "Lined", Icons.reorder, 'lined', canvasProvider),
          _sidebarTemplateItem(context, "Cornell", Icons.dashboard_customize, 'cornell', canvasProvider),
          _sidebarTemplateItem(context, "Blank", Icons.check_box_outline_blank, 'blank', canvasProvider),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarTemplateItem(BuildContext context, String label, IconData icon, String type, CanvasProvider provider) {
    bool isActive = provider.currentNote?.templateType == type;
    return GestureDetector(
      onTap: () => provider.setTemplate(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: isActive ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, size: 16, color: isActive ? AppTheme.primaryPurple : Colors.grey), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 12, color: isActive ? AppTheme.primaryPurple : Colors.white70, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))]),
      ),
    );
  }

  Widget _buildPageThumbnail(int index, bool isDark, String template) {
    bool isActive = index == 0; 
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1 / 1.4,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? AppTheme.primaryPurple : Colors.white.withOpacity(0.1), width: isActive ? 2 : 1),
                boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.15), blurRadius: 10)] : null,
              ),
              child: CustomPaint(painter: CanvasTemplatePainter(type: template, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), spacing: 12)),
            ),
          ),
          const SizedBox(height: 8),
          Text("Page ${index + 1}", style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppTheme.primaryPurple : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPage(int index, bool isDark, String template) {
    return Container(
      width: pageWidth, height: pageHeight,
      margin: EdgeInsets.only(bottom: index == _pageCount - 1 ? 0 : pageGap),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0A0A0B) : Colors.white, boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))]),
      child: CustomPaint(painter: CanvasTemplatePainter(type: template, color: isDark ? const Color(0xFF1F2937) : Colors.grey[300]!)),
    );
  }

  Widget _buildTopHeader(CanvasProvider canvasProvider, AudioProvider audioProvider, bool isDark) {
    return Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0A0A0B).withOpacity(0.8) : Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey), onPressed: () => Navigator.pop(context)),
          const VerticalDivider(width: 16, indent: 20, endIndent: 20),
          IconButton(icon: const Icon(Icons.menu_open, color: Colors.grey), onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible)),
          const VerticalDivider(width: 32, indent: 16, endIndent: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(canvasProvider.currentNote?.title.toUpperCase() ?? 'UNTITLED', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
              Text("Auto-saved at ${DateFormat.Hm().format(DateTime.now())}", style: const TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          const _AvatarStack(),
          TextButton(onPressed: () {}, child: const Text("Share", style: TextStyle(color: Colors.grey, fontSize: 13))),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => PdfService().exportNote(canvasProvider.currentNote!),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Export", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ClassllyUnifiedToolbar extends StatefulWidget {
  const _ClassllyUnifiedToolbar();
  @override
  State<_ClassllyUnifiedToolbar> createState() => _ClassllyUnifiedToolbarState();
}

class _ClassllyUnifiedToolbarState extends State<_ClassllyUnifiedToolbar> {
  bool _isPenMenuVisible = false;

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (_isPenMenuVisible)
          Positioned(
            bottom: 70, left: 40,
            child: _GlassContainer(
              padding: const EdgeInsets.all(8), borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SubToolIcon(label: "Monoline", icon: Icons.horizontal_rule, isActive: canvasProvider.activeTool == CanvasTool.monoline, onTap: () { canvasProvider.setActiveTool(CanvasTool.monoline); setState(() => _isPenMenuVisible = false); }),
                  _SubToolIcon(label: "Fountain", icon: Icons.history_edu, isActive: canvasProvider.activeTool == CanvasTool.fountain, onTap: () { canvasProvider.setActiveTool(CanvasTool.fountain); setState(() => _isPenMenuVisible = false); }),
                  _SubToolIcon(label: "Reed", icon: Icons.architecture, isActive: canvasProvider.activeTool == CanvasTool.reed, onTap: () { canvasProvider.setActiveTool(CanvasTool.reed); setState(() => _isPenMenuVisible = false); }),
                  _SubToolIcon(label: "Watercolor", icon: Icons.waves, isActive: canvasProvider.activeTool == CanvasTool.watercolor, onTap: () { canvasProvider.setActiveTool(CanvasTool.watercolor); setState(() => _isPenMenuVisible = false); }),
                  _SubToolIcon(label: "Pencil", icon: Icons.edit, isActive: canvasProvider.activeTool == CanvasTool.pencil, onTap: () { canvasProvider.setActiveTool(CanvasTool.pencil); setState(() => _isPenMenuVisible = false); }),
                  _SubToolIcon(label: "Marker", icon: Icons.border_top, isActive: canvasProvider.activeTool == CanvasTool.marker, onTap: () { canvasProvider.setActiveTool(CanvasTool.marker); setState(() => _isPenMenuVisible = false); }),
                ],
              ),
            ),
          ),
        _GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolIcon(icon: Icons.undo, isActive: false, onTap: canvasProvider.canUndo ? () => canvasProvider.undo() : () {}, color: canvasProvider.canUndo ? Colors.white : Colors.white24),
              _ToolIcon(icon: Icons.redo, isActive: false, onTap: canvasProvider.canRedo ? () => canvasProvider.redo() : () {}, color: canvasProvider.canRedo ? Colors.white : Colors.white24),
              _vDivider(),
              _ToolIcon(icon: Icons.edit, isActive: _isPenType(canvasProvider.activeTool), onTap: () { setState(() { _isPenMenuVisible = !_isPenMenuVisible; }); }),
              _ToolIcon(icon: Icons.brush, isActive: canvasProvider.activeTool == CanvasTool.brush, onTap: () => canvasProvider.setActiveTool(CanvasTool.brush)),
              _ToolIcon(icon: Icons.border_color, isActive: canvasProvider.activeTool == CanvasTool.highlighter, onTap: () => canvasProvider.setActiveTool(CanvasTool.highlighter)),
              _ToolIcon(icon: Icons.cleaning_services, isActive: canvasProvider.activeTool == CanvasTool.eraser, onTap: () => canvasProvider.setActiveTool(CanvasTool.eraser)),
              _ToolIcon(icon: Icons.gesture, isActive: canvasProvider.activeTool == CanvasTool.select, onTap: () => canvasProvider.setActiveTool(CanvasTool.select)),
              _ToolIcon(icon: Icons.text_fields, isActive: canvasProvider.activeTool == CanvasTool.text, onTap: () => canvasProvider.setActiveTool(CanvasTool.text)),
              _ToolIcon(icon: Icons.image, isActive: canvasProvider.activeTool == CanvasTool.image, onTap: () => canvasProvider.setActiveTool(CanvasTool.image)),
              _vDivider(),
              _PropertySlider(label: "WIDTH", value: canvasProvider.currentWidth, min: 1, max: 20, onChanged: (v) => canvasProvider.setWidth(v)),
              _PropertySlider(label: "OPACITY", value: canvasProvider.currentOpacity, min: 0.1, max: 1.0, onChanged: (v) => canvasProvider.setOpacity(v)),
              _vDivider(),
              ...AppTheme.noteColors.take(4).map((color) => _ColorCircle(color: color, isSelected: canvasProvider.currentColor.value == color.value, onTap: () => canvasProvider.setColor(color))),
              _vDivider(),
              _ToolIcon(icon: audioProvider.isRecording ? Icons.stop : Icons.mic, isActive: audioProvider.isRecording, color: audioProvider.isRecording ? Colors.red : AppTheme.primaryPurple, onTap: () async { if (audioProvider.isRecording) { await audioProvider.stopRecording(); } else { final path = await audioProvider.startRecording(); if (path != null && canvasProvider.currentNote != null) { canvasProvider.currentNote!.audioPath = path; canvasProvider.saveNote(); } } }),
            ],
          ),
        ),
      ],
    );
  }

  bool _isPenType(CanvasTool tool) => [CanvasTool.pen, CanvasTool.monoline, CanvasTool.fountain, CanvasTool.reed, CanvasTool.watercolor, CanvasTool.pencil, CanvasTool.marker].contains(tool);
  Widget _vDivider() => Container(width: 1, height: 24, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _SubToolIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _SubToolIcon({required this.label, required this.icon, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, size: 16, color: isActive ? AppTheme.primaryPurple : Colors.white70), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppTheme.primaryPurple : Colors.white70, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))]),
      ),
    );
  }
}

class _PropertySlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _PropertySlider({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)), SizedBox(width: 80, height: 24, child: SliderTheme(data: SliderTheme.of(context).copyWith(thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4), trackHeight: 2, overlayShape: const RoundSliderOverlayShape(overlayRadius: 10)), child: Slider(value: value, min: min, max: max, activeColor: AppTheme.primaryPurple, onChanged: onChanged)))]);
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _ColorCircle({required this.color, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 18, height: 18, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null, boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)] : null)));
  }
}

class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;
  const _ToolIcon({required this.icon, required this.isActive, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color ?? (isActive ? AppTheme.primaryPurple : Colors.white70))));
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  const _GlassContainer({required this.child, required this.padding, this.borderRadius});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius ?? BorderRadius.circular(16), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: Container(padding: padding, decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), border: Border.all(color: Colors.white.withOpacity(0.1)), borderRadius: borderRadius ?? BorderRadius.circular(16)), child: child)));
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();
  @override
  Widget build(BuildContext context) {
    return Row(children: [for (var i = 0; i < 2; i++) Align(widthFactor: 0.6, child: CircleAvatar(radius: 14, backgroundColor: i == 0 ? Colors.blue : Colors.teal, child: Text(i == 0 ? "JD" : "MK", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))), const SizedBox(width: 16)]);
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
        onTapDown: (details) async { 
          if (canvasProvider.activeTool == CanvasTool.text) { 
            canvasProvider.addTextBlock(details.localPosition, timestamp: audioProvider.isRecording ? audioProvider.elapsedRecordingMillis : null); 
          } else if (canvasProvider.activeTool == CanvasTool.select) { 
            canvasProvider.selectItemAt(details.localPosition, audioProvider); 
          } else if (canvasProvider.activeTool == CanvasTool.image) {
            final picker = ImagePicker();
            final xFile = await picker.pickImage(source: ImageSource.gallery);
            if (xFile != null) {
              final bytes = await xFile.readAsBytes();
              canvasProvider.addImage(
                base64Encode(bytes), 
                details.localPosition,
                timestamp: audioProvider.isRecording ? audioProvider.elapsedRecordingMillis : null,
              );
            }
          }
        },
        onPanStart: (details) { if (canvasProvider.activeTool == CanvasTool.select) { canvasProvider.startResize(details.localPosition); if (!canvasProvider.isResizing) canvasProvider.startMove(); } if (canvasProvider.isResizing) return; if (_isPenType(canvasProvider.activeTool)) { canvasProvider.startStroke(details.localPosition, 1.0, timestamp: audioProvider.isRecording ? audioProvider.elapsedRecordingMillis : null); } else if (canvasProvider.activeTool == CanvasTool.eraser) { canvasProvider.eraseAt(details.localPosition); } },
        onPanUpdate: (details) { if (canvasProvider.isResizing) { canvasProvider.resizeSelection(details.localPosition); return; } if (_isPenType(canvasProvider.activeTool)) { canvasProvider.updateStroke(details.localPosition, 1.0); } else if (canvasProvider.activeTool == CanvasTool.eraser) { canvasProvider.eraseAt(details.localPosition); } else if (canvasProvider.activeTool == CanvasTool.select) { canvasProvider.moveSelection(details.delta); } },
        onPanEnd: (details) { if (canvasProvider.isResizing) { canvasProvider.endResize(); return; } if (_isPenType(canvasProvider.activeTool)) { canvasProvider.endStroke(timestamp: audioProvider.isRecording ? audioProvider.elapsedRecordingMillis : null); } else if (canvasProvider.activeTool == CanvasTool.select) { canvasProvider.saveNote(); } },
        child: CustomPaint(painter: DrawingPainter(strokes: canvasProvider.currentNote?.strokes ?? [], selectedStrokes: canvasProvider.selectedStrokes, selectedImages: canvasProvider.selectedImages, activePoints: canvasProvider.activePoints, activeColor: canvasProvider.currentColor, activeWidth: canvasProvider.currentWidth, playbackTime: playbackTime, ghostPoints: canvasProvider.ghostShape?.points), child: Container()),
      ),
    );
  }
  bool _isPenType(CanvasTool tool) => [CanvasTool.pen, CanvasTool.monoline, CanvasTool.fountain, CanvasTool.reed, CanvasTool.watercolor, CanvasTool.pencil, CanvasTool.marker, CanvasTool.brush, CanvasTool.highlighter].contains(tool);
}

class PlaybackControl extends StatelessWidget {
  const PlaybackControl({super.key});
  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final canvasProvider = Provider.of<CanvasProvider>(context);
    return _GlassContainer(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), borderRadius: BorderRadius.circular(20), child: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(audioProvider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20), onPressed: () { if (audioProvider.isPlaying) { audioProvider.pause(); } else if (canvasProvider.currentNote?.audioPath != null) { audioProvider.play(canvasProvider.currentNote!.audioPath!); } }), SizedBox(width: 150, child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4)), child: Slider(value: audioProvider.currentPosition.inMilliseconds.toDouble(), max: audioProvider.totalDuration.inMilliseconds.toDouble() > 0 ? audioProvider.totalDuration.inMilliseconds.toDouble() : 1.0, activeColor: AppTheme.primaryPurple, onChanged: (val) { audioProvider.seek(Duration(milliseconds: val.toInt())); canvasProvider.setPlaybackTime(val.toInt()); })))],),);
  }
}
