import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';

class TextBlockWidget extends StatefulWidget {
  final TextBlock block;
  const TextBlockWidget({super.key, required this.block});
  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    if (widget.block.text.isEmpty) {
      _isEditing = true;
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);

    // Auto-exit editing if deselected externally (e.g. tapping canvas background)
    if (!canvasProvider.selectedTextBlocks.contains(widget.block) &&
        _isEditing) {
      // We must schedule this to avoid setState during build, or just do it?
      // Better to do it in a post-frame callback or just use the FocusNode to check?
      // Actually, if we just unfocus, the keyboard closes.
      // Let's use a post-frame callback to avoid build errors.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isEditing) {
          setState(() => _isEditing = false);
          _focusNode.unfocus();
        }
      });
    }

    return Positioned(
      left: widget.block.x,
      top: widget.block.y,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (canvasProvider.activeTool == CanvasTool.select) {
            canvasProvider.moveTextBlock(
              widget.block.id,
              Offset(
                widget.block.x + details.delta.dx,
                widget.block.y + details.delta.dy,
              ),
            );
          }
        },
        onTap: () {
          final audioProvider = Provider.of<AudioProvider>(
            context,
            listen: false,
          );
          // Select this block by simulating a tap inside it
          canvasProvider.selectItemAt(
            Offset(widget.block.x + 10, widget.block.y + 10),
            audioProvider,
          );

          setState(() {
            _isEditing = true;
            _focusNode.requestFocus();
          });
        },
        child: IntrinsicWidth(
          child: Container(
            constraints: const BoxConstraints(minWidth: 50),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: _isEditing,
              maxLines: null,
              style: TextStyle(
                fontSize: widget.block.fontSize,
                color: Color(widget.block.color),
                fontWeight: widget.block.isBold
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: widget.block.isItalic
                    ? FontStyle.italic
                    : FontStyle.normal,
                decoration: widget.block.isUnderline
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.all(4),
                filled: widget.block.hasBackground,
                fillColor: widget.block.hasBackground
                    ? Colors.yellow.withValues(alpha: 0.3)
                    : null,
              ),
              onChanged: (text) =>
                  canvasProvider.updateTextBlock(widget.block.id, text),
              onSubmitted: (_) => setState(() => _isEditing = false),
            ),
          ),
        ),
      ),
    );
  }
}
