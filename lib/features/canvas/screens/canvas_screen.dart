import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:classlly/l10n/app_localizations.dart';

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
    });
  }

  @override
  void dispose() {
    Provider.of<CanvasProvider>(context, listen: false).stopStudyTracking();
    _transformationController.dispose();
    _titleController.dispose();
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
        backgroundColor: isDark ? Colors.black : Colors.grey[300],
        body: Stack(
          children: [
            Row(
              children: [
                if (_isSidebarVisible)
                  _buildSidebar(isDark, canvasProvider, primaryColor),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopHeader(
                        canvasProvider,
                        audioProvider,
                        isDark,
                        primaryColor,
                      ),
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
                                              const Positioned.fill(
                                                child: CanvasGestureDetector(),
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
                                              // Text Layer
                                              ...textBlocks.map(
                                                (block) => TextBlockWidget(
                                                  key: ValueKey(block.id),
                                                  block: block,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 40),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              setState(() => _pageCount++),
                                          icon: const Icon(Icons.add),
                                          label: Text(AppLocalizations.of(context)!.addPage),
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
                            Positioned(
                              bottom: 32,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // if (audioProvider.isPlaying ||
                                    //     canvasProvider.playbackTime != null)
                                    //   const Padding(
                                    //     padding: EdgeInsets.only(bottom: 12),
                                    //     child: PlaybackControl(),
                                    //   ),
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
                color: Colors.red.withValues(alpha: 0.1),
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
            ? const Color(0xFF0A0A0B).withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.4),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
              ? primaryColor.withValues(alpha: 0.1)
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
                      : Colors.white.withValues(alpha: 0.1),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: CustomPaint(
                painter: CanvasTemplatePainter(
                  type: template,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A0A0B).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),

        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),

      child: SafeArea(
        bottom: false,
        top: true,
        minimum: const EdgeInsets.only(top: 8),
        child: Container(
          height: 72,

          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,

                  size: 20,

                  color: Colors.grey,
                ),

                onPressed: () => Navigator.pop(context),

                tooltip: AppLocalizations.of(context)!.backToLibrary,
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: Icon(
                  _isSidebarVisible ? Icons.menu_open : Icons.menu,

                  color: Colors.grey,
                ),

                onPressed: () =>
                    setState(() => _isSidebarVisible = !_isSidebarVisible),

                tooltip: AppLocalizations.of(context)!.toggleSidebar,
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: Icon(
                  Icons.undo,

                  color: canvasProvider.canUndo
                      ? Colors.grey
                      : Colors.grey.withValues(alpha: 0.3),
                ),

                onPressed: canvasProvider.canUndo ? canvasProvider.undo : null,

                tooltip: AppLocalizations.of(context)!.undo,
              ),

              IconButton(
                icon: Icon(
                  Icons.redo,

                  color: canvasProvider.canRedo
                      ? Colors.grey
                      : Colors.grey.withValues(alpha: 0.3),
                ),

                onPressed: canvasProvider.canRedo ? canvasProvider.redo : null,

                tooltip: AppLocalizations.of(context)!.redo,
              ),

              const VerticalDivider(width: 48, indent: 24, endIndent: 24),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    GestureDetector(
                      onTap: () {
                        // Logic to edit title could go here
                      },

                      child: Text(
                        canvasProvider.currentNote?.title.toUpperCase() ??
                            AppLocalizations.of(context)!.untitled.toUpperCase(),

                        style: const TextStyle(
                          fontSize: 13,

                          fontWeight: FontWeight.w900,

                          color: Colors.grey,

                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Row(
                      children: [
                        Container(
                          width: 6,

                          height: 6,

                          decoration: BoxDecoration(
                            color: canvasProvider.isSyncing
                                ? Colors.orange
                                : Colors.greenAccent,

                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          canvasProvider.isSyncing
                              ? AppLocalizations.of(context)!.syncing
                              : AppLocalizations.of(context)!.autoSavedAt(DateFormat.Hm().format(DateTime.now())),

                          style: TextStyle(
                            fontSize: 10,

                            color: Colors.grey[600],

                            fontWeight: FontWeight.bold,

                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  canvasProvider.isStylusOnly
                      ? Icons.do_not_touch
                      : Icons.touch_app,

                  color: canvasProvider.isStylusOnly
                      ? primaryColor
                      : Colors.grey,
                ),

                onPressed: canvasProvider.toggleStylusOnly,

                tooltip: AppLocalizations.of(context)!.stylusOnlyMode,
              ),

              const SizedBox(width: 16),
              const _AvatarStack(),
              const SizedBox(width: 16),

              ElevatedButton.icon(
                onPressed: () =>
                    PdfService().exportNote(canvasProvider.currentNote!),

                icon: const Icon(Icons.ios_share_rounded, size: 18),

                label: Text(
                  AppLocalizations.of(context)!.export,

                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,

                  foregroundColor: Colors.white,

                  elevation: 4,

                  shadowColor: primaryColor.withValues(alpha: 0.3),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,

                    vertical: 12,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
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

        if (pageImage != null) {
          // Calculate position
          final matrix = widget.transformationController.value;
          final inverseMatrix = Matrix4.inverted(matrix);
          final screenCenter = Offset(screenWidth / 2, screenHeight / 2);
          final canvasCenter = MatrixUtils.transformPoint(
            inverseMatrix,
            screenCenter,
          );

          canvasProvider.addImage(
            base64Encode(pageImage.bytes),
            canvasCenter,
            width: page.width,
            height: page.height,
            timestamp: audioProvider.isRecording
                ? audioProvider.elapsedRecordingMillis
                : null,
          );
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
    final bool showTextToolbar =
        canvasProvider.activeTool == CanvasTool.text ||
        canvasProvider.selectedTextBlocks.isNotEmpty;

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
      child: showTextToolbar
          ? const _TextToolsPanel(key: ValueKey('text_toolbar'))
          : Column(
              key: const ValueKey('drawing_toolbar_col'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canvasProvider.activeTool == CanvasTool.eraser)
                  const _EraserSettingsPanel(),
                _DrawingToolsPanel(
                  key: const ValueKey('drawing_toolbar'),
                  onPickColor: () => _showColorPicker(context, canvasProvider),
                  onPickPdf: () =>
                      _pickPdfSnippet(context, canvasProvider, audioProvider),
                  transformationController: widget.transformationController,
                ),
              ],
            ),
    );
  }
}

class _EraserSettingsPanel extends StatelessWidget {
  const _EraserSettingsPanel();

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: _GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EraserModeButton(
              icon: Icons.auto_fix_normal,
              label: AppLocalizations.of(context)!.pixel,
              isActive: canvasProvider.eraserMode == EraserMode.pixel,
              onTap: () => canvasProvider.setEraserMode(EraserMode.pixel),
              activeColor: primaryColor,
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: Colors.white24),
            const SizedBox(width: 12),
            _EraserModeButton(
              icon: Icons.delete_sweep,
              label: AppLocalizations.of(context)!.object,
              isActive: canvasProvider.eraserMode == EraserMode.object,
              onTap: () => canvasProvider.setEraserMode(EraserMode.object),
              activeColor: primaryColor,
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

  const _EraserModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? activeColor : Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? activeColor : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextToolsPanel extends StatelessWidget {
  const _TextToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final allColors = [...AppTheme.noteColors, ...canvasProvider.savedColors];
    final TextBlock? selectedBlock =
        canvasProvider.selectedTextBlocks.isNotEmpty
        ? canvasProvider.selectedTextBlocks.first
        : null;

    return _GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(32),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.text_fields, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            _vDivider(),
            _ToolIcon(
              icon: Icons.format_bold,
              isActive: selectedBlock?.isBold ?? false,
              onTap: () {
                if (selectedBlock != null) {
                  canvasProvider.updateTextBlockStyle(
                    selectedBlock.id,
                    isBold: !selectedBlock.isBold,
                  );
                }
              },
            ),
            _ToolIcon(
              icon: Icons.format_italic,
              isActive: selectedBlock?.isItalic ?? false,
              onTap: () {
                if (selectedBlock != null) {
                  canvasProvider.updateTextBlockStyle(
                    selectedBlock.id,
                    isItalic: !selectedBlock.isItalic,
                  );
                }
              },
            ),
            _ToolIcon(
              icon: Icons.format_underlined,
              isActive: selectedBlock?.isUnderline ?? false,
              onTap: () {
                if (selectedBlock != null) {
                  canvasProvider.updateTextBlockStyle(
                    selectedBlock.id,
                    isUnderline: !selectedBlock.isUnderline,
                  );
                }
              },
            ),
            _ToolIcon(
              icon: Icons.format_paint,
              isActive: selectedBlock?.hasBackground ?? false,
              onTap: () {
                if (selectedBlock != null) {
                  canvasProvider.updateTextBlockStyle(
                    selectedBlock.id,
                    hasBackground: !selectedBlock.hasBackground,
                  );
                }
              },
            ),
            _vDivider(),
            _PropertySlider(
              label: AppLocalizations.of(context)!.size,
              value: selectedBlock?.fontSize ?? 16.0,
              min: 10,
              max: 60,
              onChanged: (val) {
                if (selectedBlock != null) {
                  canvasProvider.updateTextBlockStyle(
                    selectedBlock.id,
                    fontSize: val,
                  );
                }
              },
            ),
            _vDivider(),
            ...allColors.map(
              (color) => _ColorCircle(
                color: color,
                isSelected: selectedBlock?.color == color.toARGB32(),
                onTap: () {
                  if (selectedBlock != null) {
                    canvasProvider.updateTextBlockStyle(
                      selectedBlock.id,
                      color: color.toARGB32(),
                    );
                  }
                },
              ),
            ),
            _vDivider(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.check, color: Colors.white, size: 20),
                onPressed: () {
                  canvasProvider.clearSelection();
                  canvasProvider.setActiveTool(CanvasTool.select);
                },
                tooltip: AppLocalizations.of(context)!.save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 24,
    color: Colors.white10,
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );
}

class _DrawingToolsPanel extends StatelessWidget {
  final VoidCallback onPickColor;
  final VoidCallback onPickPdf;
  final TransformationController transformationController;

  const _DrawingToolsPanel({
    super.key,
    required this.onPickColor,
    required this.onPickPdf,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    final allColors = [...AppTheme.noteColors, ...canvasProvider.savedColors];

    return _GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(32),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tools
            _ToolIcon(
              icon: Icons.pan_tool,
              isActive: canvasProvider.activeTool == CanvasTool.hand,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.hand),
            ),
            _ToolIcon(
              icon: Icons.gesture,
              isActive: canvasProvider.activeTool == CanvasTool.select,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.select),
            ),
            _vDivider(),
            _ToolIcon(
              icon: Icons.edit,
              isActive: canvasProvider.activeTool == CanvasTool.pencil,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.pencil),
            ),
            _ToolIcon(
              icon: Icons.border_color,
              isActive: canvasProvider.activeTool == CanvasTool.highlighter,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.highlighter),
            ),
            _ToolIcon(
              icon: Icons.cleaning_services,
              isActive: canvasProvider.activeTool == CanvasTool.eraser,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.eraser),
            ),
            _vDivider(),
            // Insert
            _ToolIcon(
              icon: Icons.text_fields,
              isActive: canvasProvider.activeTool == CanvasTool.text,
              onTap: () => canvasProvider.setActiveTool(CanvasTool.text),
            ),
            _ToolIcon(
              icon: Icons.image,
              isActive: canvasProvider.activeTool == CanvasTool.image,
              onTap: () async {
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
                    final matrix = transformationController.value;
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
            _ToolIcon(
              icon: Icons.picture_as_pdf_outlined,
              isActive: false,
              onTap: onPickPdf,
            ),
            _vDivider(),
            // Properties
            _PropertySlider(
              label: AppLocalizations.of(context)!.width,
              value: canvasProvider.currentWidth,
              min: 1,
              max: 20,
              onChanged: (v) => canvasProvider.setWidth(v),
            ),
            _PropertySlider(
              label: AppLocalizations.of(context)!.opacity,
              value: canvasProvider.currentOpacity,
              min: 0.1,
              max: 1.0,
              onChanged: (v) => canvasProvider.setOpacity(v),
            ),
            _vDivider(),
            // Colors
            ...allColors.map((color) {
              final isSaved = canvasProvider.savedColors.contains(color);
              return GestureDetector(
                onLongPress: isSaved
                    ? () {
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.deleteColor),
                            content: Text(
                              AppLocalizations.of(context)!.removeColorFromPalette,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  canvasProvider.removeColor(color);
                                  Navigator.pop(c);
                                },
                                child: Text(AppLocalizations.of(context)!.delete),
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
            _ToolIcon(icon: Icons.add, isActive: false, onTap: onPickColor),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 24,
    color: Colors.white10,
    margin: const EdgeInsets.symmetric(horizontal: 12),
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
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)]
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
  const _ToolIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? primaryColor : Colors.white70,
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

class CanvasGestureDetector extends StatelessWidget {
  const CanvasGestureDetector({super.key});
  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    int? playbackTime = canvasProvider.playbackTime;
    if (audioProvider.isPlaying) {
      playbackTime = audioProvider.currentPosition.inMilliseconds;
    }

    return IgnorePointer(
      ignoring: canvasProvider.activeTool == CanvasTool.hand,
      child: Listener(
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
            canvasProvider.selectItemAt(offset, audioProvider);
            canvasProvider.startResize(offset);
            if (!canvasProvider.isResizing) canvasProvider.startMove();
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
        onPointerMove: (event) {
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
            canvasProvider.moveSelection(event.delta);
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
            canvasProvider.saveNote();
          }
        },
        child: CustomPaint(
          painter: DrawingPainter(
            strokes: canvasProvider.currentNote?.strokes ?? [],
            selectedStrokes: canvasProvider.selectedStrokes,
            selectedImages: canvasProvider.selectedImages,
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

  bool _isPenType(CanvasTool tool) => [
    CanvasTool.pen,
    CanvasTool.monoline,
    CanvasTool.fountain,
    CanvasTool.reed,
    CanvasTool.watercolor,
    CanvasTool.pencil,
    CanvasTool.marker,
    CanvasTool.brush,
    CanvasTool.highlighter,
  ].contains(tool);
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
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _avatar('A', Colors.blue),
        const SizedBox(width: -8),
        _avatar('B', Colors.green),
        const SizedBox(width: -8),
        _avatar('C', Colors.orange),
        const SizedBox(width: 8),
        Text(
          '+2',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _avatar(String initial, Color color) {
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
