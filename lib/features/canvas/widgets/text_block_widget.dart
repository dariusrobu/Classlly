import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';

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
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
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
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.all(4),
              ),
              onChanged: (text) =>
                  canvasProvider.updateTextBlock(widget.block.id, text),
              onSubmitted: (_) => setState(() => _isEditing = false),
              onTapOutside: (_) {
                setState(() => _isEditing = false);
                _focusNode.unfocus();
              },
            ),
          ),
        ),
      ),
    );
  }
}
