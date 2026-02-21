import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/l10n/app_localizations.dart';
import 'package:classlly/core/widgets/glass_card.dart';

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.createNewNote,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.noteTitle,
                hintText: 'e.g., Lecture 1 - Introduction',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
                    Text(
                      AppLocalizations.of(context)!.courseOptional,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCourseId,
                          isExpanded: true,
                          hint: Text(AppLocalizations.of(context)!.none),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(AppLocalizations.of(context)!.none),
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
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            Text(
              AppLocalizations.of(context)!.noteType,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeSelectionCard(
                    label: AppLocalizations.of(context)!.drawing,
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
                    label: AppLocalizations.of(context)!.text,
                    icon: Icons.text_fields,
                    isSelected: _selectedType == Note.typeText,
                    onTap: () => setState(() => _selectedType = Note.typeText),
                    color: primaryColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = _titleController.text.trim().isEmpty
                      ? AppLocalizations.of(context)!.untitled
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context)!.create,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 12),
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
