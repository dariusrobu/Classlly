import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:classlly/l10n/app_localizations.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TextEditorScreen extends StatefulWidget {
  final Note note;

  const TextEditorScreen({super.key, required this.note});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  final NotesRepository _repository = NotesRepository();
  late CloudStorageService _cloudService;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  final FocusNode _editorFocusNode = FocusNode();
  Course? _course;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cloudService = Provider.of<CloudStorageService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    if (widget.note.notebookId != null) {
      _course = _repository.getCourse(widget.note.notebookId!);
    }
    _loadContent();
  }

  void _loadContent() {
    Document doc;
    if (widget.note.textBlocks.isNotEmpty) {
      final content = widget.note.textBlocks.first.text;
      try {
        // Try to parse as Delta JSON
        final json = jsonDecode(content);
        doc = Document.fromJson(json);
      } catch (e) {
        // Fallback to plain text if not JSON
        doc = Document()..insert(0, content);
      }
    } else {
      doc = Document();
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _quillController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.removeListener(_onContentChanged);
    _quillController.dispose();
    _editorFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onContentChanged() {
    _save();
  }

  void _save() async {
    widget.note.title = _titleController.text;

    // Serialize Delta to JSON
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());

    final newBlock = TextBlock(
      id: 'main_content',
      text: deltaJson, // Store rich text JSON here
      x: 0,
      y: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    widget.note.textBlocks.clear();
    widget.note.textBlocks.add(newBlock);
    widget.note.updatedAt = DateTime.now();

    await _repository.saveNote(widget.note);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      if (mounted) setState(() => _isSyncing = true);
      await _cloudService.syncNotes();
      if (mounted) setState(() => _isSyncing = false);
    });
  }

  void _onColorButtonPressed(BuildContext context, bool background) {
    Color currentColor = Colors.black;
    // Try to get current color from selection
    final style = _quillController.getSelectionStyle();
    final attribute = background
        ? style.attributes['background']
        : style.attributes['color'];

    if (attribute != null && attribute.value != null) {
      try {
        String hex = attribute.value;
        hex = hex.replaceFirst('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        currentColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pickColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              currentColor = color;
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.addDone),
            onPressed: () {
              final hex =
                  '#${currentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              if (background) {
                _quillController.formatSelection(BackgroundAttribute(hex));
              } else {
                _quillController.formatSelection(ColorAttribute(hex));
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Premium light gray
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEditorHeader(),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 24, bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildFloatingToolbar(),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  24,
                                  24,
                                  24,
                                ),
                                child: QuillEditor.basic(
                                  controller: _quillController,
                                  config: const QuillEditorConfig(
                                    placeholder: 'Start typing...',
                                    autoFocus: true,
                                    expands: false,
                                    scrollable: true,
                                    padding: EdgeInsets.only(bottom: 50),
                                  ),
                                  focusNode: _editorFocusNode,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final now = DateTime.now();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dateFormatted = isMobile
        ? DateFormat('MMM d, yyyy').format(now)
        : DateFormat(
            "EEEE, MMMM d'rc'",
          ).format(now).replaceFirst('rc', _getDaySuffix(now.day));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 24.0,
        vertical: 12.0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
            color: Colors.grey[700],
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            dateFormatted,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              final plainText = _quillController.document.toPlainText();
              final pdf = pw.Document();

              pdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _titleController.text,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Text(plainText),
                    ],
                  ),
                ),
              );

              await Printing.sharePdf(
                bytes: await pdf.save(),
                filename: '${_titleController.text}.pdf',
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[800],
              elevation: 0,
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildEditorHeader() {
    final breadcrumb = _course != null
        ? '${_course!.title.toUpperCase()} / NOTES'
        : 'GENERAL / NOTES';
    const lastEdited =
        'Last edited just now'; // Ideally calculate from widget.note.updatedAt

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          breadcrumb,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Untitled Note',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          onChanged: (val) => _save(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              lastEdited,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 12),
            if (_isSyncing)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'AUTOSAVED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingToolbar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuillSimpleToolbar(
              controller: _quillController,
              config: QuillSimpleToolbarConfig(
                showFontFamily: false,
                showSearchButton: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showUndo: false,
                showRedo: false,
                showAlignmentButtons: false,
                showIndent: false,
                showStrikeThrough: false,
                showClearFormat: false,
                showHeaderStyle: false,
                showQuote: false,
                showCodeBlock: false,
                showColorButton: true,
                showBackgroundColorButton: true,
                toolbarSectionSpacing: 0,
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  color: QuillToolbarColorButtonOptions(
                    afterButtonPressed: () =>
                        _onColorButtonPressed(context, false),
                  ),
                  backgroundColor: QuillToolbarColorButtonOptions(
                    afterButtonPressed: () =>
                        _onColorButtonPressed(context, true),
                  ),
                ),
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
