import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

class CreateNoteDialog extends StatefulWidget {
  final String? initialCourseId;

  const CreateNoteDialog({super.key, this.initialCourseId});

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _titleController = TextEditingController();
  String _selectedType = Note.typeDrawing;
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: const Text('Create New Note'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Note Title',
                hintText: 'e.g., Lecture 1 - Introduction',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder(
              valueListenable: Hive.box<Course>(
                NotesRepository.courseBoxName,
              ).listenable(),
              builder: (context, Box<Course> box, _) {
                final courses = box.values.toList();
                if (courses.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course (Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ...courses.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.title),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedCourseId = val),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            const Text(
              'Note Type',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeSelectionCard(
                    label: 'Drawing',
                    icon: Icons.draw,
                    isSelected: _selectedType == Note.typeDrawing,
                    onTap: () =>
                        setState(() => _selectedType = Note.typeDrawing),
                    color: primaryColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeSelectionCard(
                    label: 'Text',
                    icon: Icons.text_fields,
                    isSelected: _selectedType == Note.typeText,
                    onTap: () => setState(() => _selectedType = Note.typeText),
                    color: primaryColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final title = _titleController.text.trim().isEmpty
                ? 'Untitled Note'
                : _titleController.text.trim();

            final notesProvider = Provider.of<NotesProvider>(
              context,
              listen: false,
            );

            // Create note with selected type
            final note = await notesProvider.createNoteInCurrentFolder(
              title: title,
              type: _selectedType,
            );

            // Add course tag/link if selected
            if (_selectedCourseId != null) {
              // Logic to link course can be improved, for now we add tag or just handle it
              // The original code used tags for course linking in some places
              // note.tags = [ ...note.tags ?? [], _selectedCourseId! ];
              // await NotesRepository().saveNote(note);
            }

            if (context.mounted) {
              Navigator.pop(context, note);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _TypeSelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const _TypeSelectionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? color
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
