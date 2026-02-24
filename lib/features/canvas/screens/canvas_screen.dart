import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/canvas/widgets/drawing_painter.dart';
import 'package:classlly/features/canvas/widgets/text_block_widget.dart';
import 'package:classlly/features/canvas/widgets/canvas_template_painter.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/core/services/pdf_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:classlly/l10n/app_localizations.dart';
import 'package:classlly/features/canvas/widgets/advanced_pdf_crop_dialog.dart';
import 'package:classlly/core/services/presence_service.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/canvas/widgets/cursor_painter.dart';


class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final TextEditingController _titleController = TextEditingController();
  bool _isSidebarVisible = true;
  bool _isInit = true;
  final PresenceService _presenceService = PresenceService();
  List<Map<String, dynamic>> _remoteUsers = [];
  StreamSubscription? _presenceSub;
  Timer? _cursorThrottle;

  static const double pageWidth = 1000.0;
  static const double pageHeight = 1414.0;
  static const double pageGap = 40.0;
  int _pageCount = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final title = Provider.of<CanvasProvider>(
        context,
        listen: false,
      ).currentNote?.title;
      _titleController.text = title ?? AppLocalizations.of(context)!.untitled;

      // Initialize Presence
      final note = Provider.of<CanvasProvider>(context, listen: false).currentNote;
      final profile = Provider.of<ProfileProvider>(context, listen: false).studentProfile;
      if (note != null) {
        _presenceService.joinNote(note.id, profile.name ?? 'Student');
        _presenceSub = _presenceService.presenceStream.listen((users) {
          if (mounted) setState(() => _remoteUsers = users);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth < 800) {
        setState(() {
          _isSidebarVisible = false;
        });
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    Provider.of<CanvasProvider>(context, listen: false).stopStudyTracking();
    _transformationController.dispose();
    _titleController.dispose();
    _presenceSub?.cancel();
    _presenceService.dispose();
    _cursorThrottle?.cancel();
    super.dispose();
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double scale = _transformationController.value.getMaxScaleOnAxis();
      final Offset delta = event.scrollDelta;
      final Matrix4 matrix = _transformationController.value.clone();
      // ignore: deprecated_member_use
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final double pagesHeight =
        (_pageCount * pageHeight) + ((_pageCount - 1) * pageGap);
    int? playbackTime = canvasProvider.playbackTime;
    if (audioProvider.isPlaying) {
      playbackTime = audioProvider.currentPosition.inMilliseconds;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            canvasProvider.undo(),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () =>
            canvasProvider.redo(),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () =>
            canvasProvider.undo(),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): () =>
            canvasProvider.redo(),
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
        body: Stack(
          children: [
            Row(
              children: [
                if (_isSidebarVisible)
                  _buildSidebar(isDark, canvasProvider, primaryColor),
                Expanded(
                  child: Stack(
                    children: [

                      Expanded(
                        child: Stack(
                          children: [
                            Listener(
                              onPointerSignal: _handleScroll,
                              child: InteractiveViewer(
                                transformationController:
                                    _transformationController,
                                constrained: false,
                                boundaryMargin: const EdgeInsets.all(500),
                                minScale: 0.1,
                                maxScale: 5.0,
                                panEnabled: isHandTool,
                                scaleEnabled: true,
                                onInteractionUpdate: (details) {
                                  if (_cursorThrottle?.isActive ?? false) return;
                                  _cursorThrottle = Timer(const Duration(milliseconds: 100), () {
                                    final scenePoint = _transformationController.toScene(
                                      details.focalPoint,
                                    );
                                    _presenceService.updateLocalPresence(cursor: scenePoint);
                                  });
                                },
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
                                              Column(
                                                children: [
                                                  for (
                                                    int i = 0;
                                                    i < _pageCount;
                                                    i++
                                                  )
                                                    _buildPage(
                                                      i,
                                                      isDark,
                                                      canvasProvider
                                                              .currentNote
                                                              ?.templateType ??
                                                          'dot',
                                                    ),
                                                ],
                                              ),
                                               _buildCanvasGestureDetector(
                                                canvasProvider,
                                                audioProvider,
                                                playbackTime,
                                                pageWidth,
                                                pageHeight,
                                              ),
                                              // Image Layer
                                              ...canvasProvider
                                                      .currentNote
                                                      ?.images
                                                      .map(
                                                        (img) =>
                                                            _buildImageWidget(
                                                              img,
                                                              canvasProvider,
                                                              primaryColor,
                                                            ),
                                                      ) ??
                                                  [],
                                                ...textBlocks.map(
                                                  (block) => TextBlockWidget(
                                                    key: ValueKey(block.id),
                                                    block: block,
                                                  ),
                                                ),

                                                // Remote Cursors
                                                ..._remoteUsers
                                                    .where((u) => u['cursor_x'] != null)
                                                    .map((u) {
                                                  return Positioned(
                                                    left: u['cursor_x'],
                                                    top: u['cursor_y'],
                                                    child: IgnorePointer(
                                                      child: Column(
                                                        children: [
                                                          const Icon(
                                                            Icons.navigation_rounded,
                                                            color: Colors.blueAccent,
                                                            size: 20,
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blueAccent,
                                                              borderRadius:
                                                                  BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              u['name'] ?? 'Other',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 40),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              setState(() => _pageCount++),
                                          icon: const Icon(Icons.add),
                                          label: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.addPage,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Right Side Tool Dock
                            Positioned(
                              right: 24,
                              top: MediaQuery.of(context).size.height / 3, // Roughly middle
                              child: _RightSideDock(
                                isDark: isDark, 
                                primaryColor: primaryColor,
                                onToggleSidebar: () {
                                  setState(() {
                                    _isSidebarVisible = !_isSidebarVisible;
                                  });
                                },
                                onAddText: () {
                                  canvasProvider.setActiveTool(CanvasTool.text);
                                },
                                onAddImage: () async {
                                  try {
                                    final sWidth = MediaQuery.of(context).size.width;
                                    final sHeight = MediaQuery.of(context).size.height;
                                    canvasProvider.setActiveTool(CanvasTool.image);
                                    final picker = ImagePicker();
                                    final xFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (xFile != null) {
                                      final bytes = await xFile.readAsBytes();
                                      final matrix = _transformationController.value;
                                      final inverseMatrix = Matrix4.inverted(matrix);
                                      final screenCenter = Offset(sWidth / 2, sHeight / 2);
                                      final canvasCenter = MatrixUtils.transformPoint(
                                        inverseMatrix,
                                        screenCenter,
                                      );

                                      canvasProvider.addImage(
                                        base64Encode(bytes),
                                        canvasCenter,
                                        timestamp: audioProvider.isRecording
                                            ? audioProvider.elapsedRecordingMillis
                                            : null,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to add image: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            // Bottom Toolbar
                            Positioned(
                              bottom: 32,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CanvasToolbars(
                                      transformationController:
                                          _transformationController,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildTopHeader(
                          canvasProvider,
                          audioProvider,
                          isDark,
                          primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(
    ImageBlock img,
    CanvasProvider provider,
    Color primaryColor,
  ) {
    bool isSelected = provider.selectedImages.contains(img);
    return Positioned(
      left: img.x,
      top: img.y,
      child: GestureDetector(
        onTap: () => provider.selectItemAt(
          Offset(img.x + 5, img.y + 5),
          Provider.of<AudioProvider>(context, listen: false),
        ),
        onPanStart: (details) {
          if (provider.activeTool == CanvasTool.select) {
            if (!provider.selectedImages.contains(img)) {
              provider.selectItemAt(
                Offset(img.x + 5, img.y + 5),
                Provider.of<AudioProvider>(context, listen: false),
              );
            }
          }
        },
        onPanUpdate: (details) {
          if (provider.activeTool == CanvasTool.select) {
            provider.moveSelection(details.delta);
          }
        },
        onPanEnd: (details) {
          if (provider.activeTool == CanvasTool.select) {
            provider.saveNote();
          }
        },
        child: Container(
          width: img.width,
          height: img.height,
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: primaryColor, width: 2)
                : null,
          ),
          child: Image.memory(
            base64Decode(img.base64Data),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.error_outline, color: Colors.red),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(
    bool isDark,
    CanvasProvider canvasProvider,
    Color primaryColor,
  ) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A0A0B).withOpacity(0.4)
            : Colors.white.withOpacity(0.4),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.outlinePages,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.add_circle, color: primaryColor, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _pageCount,
                  itemBuilder: (context, index) => _buildPageThumbnail(
                    index,
                    isDark,
                    canvasProvider.currentNote?.templateType ?? 'dot',
                    primaryColor,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white10, height: 32),
                      Text(
                        AppLocalizations.of(context)!.pageTemplate,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sidebarTemplateItem(
                        context,
                        AppLocalizations.of(context)!.dotGrid,
                        Icons.apps,
                        'dot',
                        canvasProvider,
                      ),
                      _sidebarTemplateItem(
                        context,
                        AppLocalizations.of(context)!.squared,
                        Icons.grid_4x4,
                        'grid',
                        canvasProvider,
                      ),
                      _sidebarTemplateItem(
                        context,
                        AppLocalizations.of(context)!.lined,
                        Icons.reorder,
                        'lined',
                        canvasProvider,
                      ),
                      _sidebarTemplateItem(
                        context,
                        AppLocalizations.of(context)!.cornell,
                        Icons.dashboard_customize,
                        'cornell',
                        canvasProvider,
                      ),
                      _sidebarTemplateItem(
                        context,
                        AppLocalizations.of(context)!.blank,
                        Icons.check_box_outline_blank,
                        'blank',
                        canvasProvider,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarTemplateItem(
    BuildContext context,
    String label,
    IconData icon,
    String type,
    CanvasProvider provider,
  ) {
    bool isActive = provider.currentNote?.templateType == type;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => provider.setTemplate(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? primaryColor : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? primaryColor : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageThumbnail(
    int index,
    bool isDark,
    String template,
    Color primaryColor,
  ) {
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
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? primaryColor
                      : Colors.white.withOpacity(0.1),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.15),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: CustomPaint(
                painter: CanvasTemplatePainter(
                  type: template,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  spacing: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Page ${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index, bool isDark, String template) {
    return Container(
      width: pageWidth,
      height: pageHeight,
      margin: EdgeInsets.only(bottom: index == _pageCount - 1 ? 0 : pageGap),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: isDark ? Border.all(color: Colors.white12) : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CanvasTemplatePainter(
          type: template,
          color: isDark ? const Color(0xFF2D3748) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    CanvasProvider canvasProvider,
    AudioProvider audioProvider,
    bool isDark,
    Color primaryColor,
  ) {

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Pill: Pen Icon & Title & Undo/Redo
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: isDark ? Colors.white : Colors.black87,
                    iconSize: 20,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  _AvatarStack(users: _remoteUsers),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mode_edit_outline, size: 16, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    canvasProvider.currentNote?.title ?? AppLocalizations.of(context)!.untitled,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Right Pill: Export & Save
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Export Button
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: InkWell(
                    onTap: () => PdfService().exportNote(canvasProvider.currentNote!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.output_rounded, size: 16, color: Colors.grey[700]), // Export icon
                        const SizedBox(width: 6),
                        Text(
                          'Export PDF',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save Module Button
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      canvasProvider.saveNote();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Module Saved!'))
                      );
                      Navigator.pop(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text(
                          'Save Module',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete Button
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.black87,
                    onPressed: () async {
                      if (canvasProvider.currentNote == null) return;
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Note?'),
                          content: const Text('Are you sure you want to delete this note? This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await NotesRepository().deleteNote(canvasProvider.currentNote!.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Note deleted')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasGestureDetector(
    CanvasProvider canvasProvider,
    AudioProvider audioProvider,
    int? playbackTime,
    double pageWidth,
    double pageHeight,
  ) {
    return IgnorePointer(
      ignoring: canvasProvider.activeTool == CanvasTool.hand,
      child: Listener(
        onPointerMove: (event) {
          // 1. Throttled Presence Update
          if (!(_cursorThrottle?.isActive ?? false)) {
            _cursorThrottle = Timer(const Duration(milliseconds: 50), () {
              _presenceService.updateLocalPresence(
                cursor: event.localPosition,
              );
            });
          }

          // 2. Standard Canvas Logic
          if (canvasProvider.isStylusOnly &&
              event.kind == PointerDeviceKind.touch) {
            return;
          }
          final offset = event.localPosition;

          if (canvasProvider.isResizing) {
            canvasProvider.resizeSelection(offset);
            return;
          }
          if (_isPenType(canvasProvider.activeTool)) {
            canvasProvider.updateStroke(
              offset,
              event.pressureMin > 0 ? event.pressure : 1.0,
            );
          } else if (canvasProvider.activeTool == CanvasTool.eraser) {
            canvasProvider.eraseAt(offset);
          } else if (canvasProvider.activeTool == CanvasTool.select) {
            if (canvasProvider.lassoPath.isNotEmpty) {
              canvasProvider.updateLasso(offset);
            } else {
              canvasProvider.moveSelection(event.delta, absolutePosition: offset);
            }
          }
        },
        onPointerDown: (event) async {
          if (canvasProvider.isStylusOnly &&
              event.kind == PointerDeviceKind.touch) {
            return;
          }

          final offset = event.localPosition;

          if (canvasProvider.activeTool == CanvasTool.text) {
            canvasProvider.addTextBlock(
              offset,
              timestamp: audioProvider.isRecording
                  ? audioProvider.elapsedRecordingMillis
                  : null,
            );
          } else if (canvasProvider.activeTool == CanvasTool.select) {
            bool hitExisting = canvasProvider.hitTestSelection(offset);
            if (hitExisting) {
              canvasProvider.startResize(offset);
              if (!canvasProvider.isResizing) canvasProvider.startMove(offset);
            } else {
              bool hitNew = canvasProvider.selectItemAt(offset, audioProvider);
              if (hitNew) {
                canvasProvider.startResize(offset);
                if (!canvasProvider.isResizing) canvasProvider.startMove(offset);
              } else {
                canvasProvider.startLasso(offset);
              }
            }
          } else if (canvasProvider.activeTool == CanvasTool.image) {
            final picker = ImagePicker();
            final xFile = await picker.pickImage(source: ImageSource.gallery);
            if (xFile != null) {
              final bytes = await xFile.readAsBytes();
              canvasProvider.addImage(
                base64Encode(bytes),
                offset,
                timestamp: audioProvider.isRecording
                    ? audioProvider.elapsedRecordingMillis
                    : null,
              );
            }
          } else if (_isPenType(canvasProvider.activeTool)) {
            canvasProvider.startStroke(
              offset,
              event.pressureMin > 0
                  ? event.pressure
                  : 1.0, // Default pressure if not supported
              timestamp: audioProvider.isRecording
                  ? audioProvider.elapsedRecordingMillis
                  : null,
            );
          } else if (canvasProvider.activeTool == CanvasTool.eraser) {
            canvasProvider.eraseAt(offset);
          }
        },
        onPointerUp: (event) {
          if (canvasProvider.isStylusOnly &&
              event.kind == PointerDeviceKind.touch) {
            return;
          }
          if (canvasProvider.isResizing) {
            canvasProvider.endResize();
            return;
          }
          if (_isPenType(canvasProvider.activeTool)) {
            canvasProvider.endStroke(
              timestamp: audioProvider.isRecording
                  ? audioProvider.elapsedRecordingMillis
                  : null,
            );
          } else if (canvasProvider.activeTool == CanvasTool.select) {
             if (canvasProvider.lassoPath.isNotEmpty) {
              canvasProvider.endLasso();
            } else {
              canvasProvider.endMove();
              canvasProvider.saveNote();
            }
          }
        },
        child: CustomPaint(
          painter: DrawingPainter(
            strokes: canvasProvider.currentNote?.strokes ?? [],
            selectedStrokes: canvasProvider.selectedStrokes,
            selectedImages: canvasProvider.selectedImages,
            selectedTextBlocks: canvasProvider.selectedTextBlocks,
            activePoints: canvasProvider.activePoints,
            activeColor: canvasProvider.currentColor,
            activeWidth: canvasProvider.currentWidth,
            playbackTime: playbackTime,
            ghostPoints: canvasProvider.ghostShape?.points,
            lassoPath: canvasProvider.lassoPath,
          ),
          child: Container(),
        ),
      ),
    );
  }

  bool _isPenType(CanvasTool tool) => {
    CanvasTool.pen,
    CanvasTool.monoline,
    CanvasTool.fountain,
    CanvasTool.reed,
    CanvasTool.watercolor,
    CanvasTool.pencil,
    CanvasTool.marker,
    CanvasTool.brush,
    CanvasTool.highlighter,
  }.contains(tool);

}

class _RightSideDock extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onToggleSidebar;
  final VoidCallback onAddText;
  final VoidCallback onAddImage;

  const _RightSideDock({
    required this.isDark, 
    required this.primaryColor,
    required this.onToggleSidebar,
    required this.onAddText,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDockItem('LAYERS', Icons.layers_outlined, context, onTap: onToggleSidebar),
          const SizedBox(height: 24),
          _buildDockItem('TEXT', Icons.text_fields_rounded, context, onTap: onAddText),
          const SizedBox(height: 24),
          _buildDockItem('IMG', Icons.image_outlined, context, onTap: onAddImage),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),
          const SizedBox(height: 24),
          _buildDockItem('', Icons.grid_4x4_rounded, context, showText: false, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildDockItem(String label, IconData icon, BuildContext context, {bool showText = true, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showText) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
      ],
      ),
    );
  }
}

class _CanvasToolbars extends StatefulWidget {
  final TransformationController transformationController;
  const _CanvasToolbars({required this.transformationController});

  @override
  State<_CanvasToolbars> createState() => _CanvasToolbarsState();
}

class _CanvasToolbarsState extends State<_CanvasToolbars> {
  void _showColorPicker(BuildContext context, CanvasProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pickColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: provider.currentColor,
            onColorChanged: (color) => provider.setColor(color),
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.addDone),
            onPressed: () {
              provider.addColor(provider.currentColor);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickPdfSnippet(
    BuildContext context,
    CanvasProvider canvasProvider,
    AudioProvider audioProvider,
  ) async {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      if (!context.mounted) return;

      // Open PDF document
      final document = await PdfDocument.openFile(path);

      if (!context.mounted) {
        await document.close();
        return;
      }

      // Visual dialog to pick page with thumbnails
      final pageNumber = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.insertPdfPage),
          backgroundColor: Theme.of(context).cardColor,
          content: SizedBox(
            width: 500,
            height: 600,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: document.pagesCount,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: () async {
                    final page = await document.getPage(index + 1);
                    final img = await page.render(
                      width: page.width,
                      height: page.height,
                      format: PdfPageImageFormat.png,
                    );
                    await page.close();
                    return img?.bytes;
                  }(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, index + 1),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                '${AppLocalizations.of(context)!.week.split(' ')[0]} ${index + 1}', // Page
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      );

      if (pageNumber != null && context.mounted) {
        final page = await document.getPage(pageNumber);
        final pageImage = await page.render(
          width: page.width * 2, // High res
          height: page.height * 2,
          format: PdfPageImageFormat.png,
        );

        if (pageImage != null && context.mounted) {
          // Show Advanced Crop Dialog
          final croppedBytes = await showDialog<Uint8List>(
            context: context,
            builder: (context) => AdvancedPdfCropDialog(imageBytes: pageImage.bytes),
          );

          if (croppedBytes != null && context.mounted) {
            // Calculate position
            final matrix = widget.transformationController.value;
            final inverseMatrix = Matrix4.inverted(matrix);
            final screenCenter = Offset(screenWidth / 2, screenHeight / 2);
            final canvasCenter = MatrixUtils.transformPoint(
              inverseMatrix,
              screenCenter,
            );

            canvasProvider.addImage(
              base64Encode(croppedBytes),
              canvasCenter,
              width: page.width,
              height: page.height,
              timestamp: audioProvider.isRecording
                  ? audioProvider.elapsedRecordingMillis
                  : null,
            );
          }
        }
        await page.close();
      }
      await document.close();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking PDF: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Column(
        key: const ValueKey('drawing_toolbar_col'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canvasProvider.activeTool == CanvasTool.eraser)
            _EraserSettingsPanel(isDark: isDark),
          _DrawingToolsPanel(
            key: const ValueKey('drawing_toolbar'),
            onPickColor: () => _showColorPicker(context, canvasProvider),
            onPickPdf: () =>
                _pickPdfSnippet(context, canvasProvider, audioProvider),
            transformationController: widget.transformationController,
            isDark: isDark
          ),
        ],
      ),
    );
  }
}

class _EraserSettingsPanel extends StatelessWidget {
  final bool isDark;
  const _EraserSettingsPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EraserModeButton(
              icon: Icons.auto_fix_normal,
              label: AppLocalizations.of(context)!.pixel,
              isActive: canvasProvider.eraserMode == EraserMode.pixel,
              onTap: () => canvasProvider.setEraserMode(EraserMode.pixel),
              activeColor: primaryColor,
              isDark: isDark
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: isDark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(width: 12),
            _EraserModeButton(
              icon: Icons.delete_sweep,
              label: AppLocalizations.of(context)!.object,
              isActive: canvasProvider.eraserMode == EraserMode.object,
              onTap: () => canvasProvider.setEraserMode(EraserMode.object),
              activeColor: primaryColor,
              isDark: isDark
            ),
          ],
        ),
      ),
    );
  }
}

class _EraserModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isDark;

  const _EraserModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? activeColor : (isDark ? Colors.white70 : Colors.grey[700])),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? activeColor : (isDark ? Colors.white70 : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}



class _DrawingToolsPanel extends StatelessWidget {
  final VoidCallback onPickColor;
  final VoidCallback onPickPdf;
  final TransformationController transformationController;
  final bool isDark;

  const _DrawingToolsPanel({
    super.key,
    required this.onPickColor,
    required this.onPickPdf,
    required this.transformationController,
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final allColors = [...AppTheme.noteColors, ...canvasProvider.savedColors];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tools
            _ToolIcon(
              icon: Icons.pan_tool_outlined,
              isActive: canvasProvider.activeTool == CanvasTool.hand,
              isDark: isDark,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.hand),
            ),
            const SizedBox(width: 4),
            _ToolIcon(
              icon: Icons.highlight_alt_rounded,
              isActive: canvasProvider.activeTool == CanvasTool.select,
              isDark: isDark,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.select),
            ),
            _vDivider(isDark: isDark),
            _ToolIcon(
              icon: Icons.edit_rounded,
              isActive: canvasProvider.activeTool == CanvasTool.pencil,
              isDark: isDark,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.pencil),
            ),
            const SizedBox(width: 4),
            _ToolIcon(
              icon: Icons.border_color_rounded,
              isActive: canvasProvider.activeTool == CanvasTool.highlighter,
              isDark: isDark,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.highlighter),
            ),
            const SizedBox(width: 4),
            _ToolIcon(
              icon: Icons.healing_rounded, // or cleaning_services
              isActive: canvasProvider.activeTool == CanvasTool.eraser,
              isDark: isDark,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.eraser),
            ),
            _vDivider(isDark: isDark),
            // Properties
            _PropertySlider(
              label: AppLocalizations.of(context)!.width,
              value: canvasProvider.currentWidth,
              min: 1,
              max: 20,
              onChanged: (v) => canvasProvider.setWidth(v),
            ),
            const SizedBox(width: 8),
            _PropertySlider(
              label: AppLocalizations.of(context)!.opacity,
              value: canvasProvider.currentOpacity,
              min: 0.1,
              max: 1.0,
              onChanged: (v) => canvasProvider.setOpacity(v),
            ),
            _vDivider(isDark: isDark),
            // Colors
            ...allColors.map((color) {
              final isSaved = canvasProvider.savedColors.contains(color);
              return GestureDetector(
                onLongPress: isSaved
                    ? () {
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(
                              AppLocalizations.of(context)!.deleteColor,
                            ),
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.removeColorFromPalette,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  canvasProvider.removeColor(color);
                                  Navigator.pop(c);
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.delete,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                child: _ColorCircle(
                  color: color,
                  isSelected:
                      canvasProvider.currentColor.toARGB32() ==
                      color.toARGB32(),
                  onTap: () => canvasProvider.setColor(color),
                ),
              );
            }),
            const SizedBox(width: 4),
            _ToolIcon(icon: Icons.add, isActive: false, isDark: isDark, onTap: onPickColor),
          ],
        ),
      ),
    );
  }

  Widget _vDivider({required bool isDark}) => Container(
    width: 1,
    height: 24,
    color: isDark ? Colors.white10 : Colors.grey[300],
    margin: const EdgeInsets.symmetric(horizontal: 16),
  );
}

class _PropertySlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _PropertySlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        SizedBox(
          width: 80,
          height: 24,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              trackHeight: 2,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: primaryColor,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _ToolIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.isDark
  });
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? primaryColor : (isDark ? Colors.white70 : Colors.grey[700]),
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  const _GlassContainer({
    required this.child,
    required this.padding,
    this.borderRadius,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class PlaybackControl extends StatelessWidget {
  const PlaybackControl({super.key});
  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    return _GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else if (canvasProvider.currentNote?.audioPath != null) {
                audioProvider.play(canvasProvider.currentNote!.audioPath!);
              }
            },
          ),
          SizedBox(
            width: 150,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              ),
              child: Slider(
                value: audioProvider.currentPosition.inMilliseconds.toDouble(),
                max: audioProvider.totalDuration.inMilliseconds.toDouble() > 0
                    ? audioProvider.totalDuration.inMilliseconds.toDouble()
                    : 1.0,
                activeColor: primaryColor,
                onChanged: (val) {
                  audioProvider.seek(Duration(milliseconds: val.toInt()));
                  canvasProvider.setPlaybackTime(val.toInt());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AvatarStack extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const _AvatarStack({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < users.length && i < 3; i++)
          Align(
            widthFactor: 0.6,
            child: _UserAvatar(
              name: users[i]['name'] ?? 'U',
              color: Colors.accents[i * 2 % Colors.accents.length],
            ),
          ),
        if (users.length > 3)
          Align(
            widthFactor: 0.6,
            child: _UserAvatar(
              name: '+${users.length - 3}',
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final Color color;
  const _UserAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
