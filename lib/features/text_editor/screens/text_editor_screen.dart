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
  late final CloudStorageService _cloudService;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cloudService = Provider.of<CloudStorageService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Untitled Note',
          ),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
          onChanged: (val) => _save(),
        ),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                _save();
                FocusScope.of(context).unfocus();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            QuillSimpleToolbar(
              controller: _quillController,
              config: QuillSimpleToolbarConfig(
                showFontFamily: false,
                showSearchButton: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
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
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: QuillEditor.basic(
                  controller: _quillController,
                  config: const QuillEditorConfig(
                    placeholder: 'Start typing...',
                    autoFocus: true,
                    expands: false, // Let it scroll naturally
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
    );
  }
}
