import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/canvas/screens/canvas_screen.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:classlly/features/library/screens/course_detail_screen.dart';
import 'package:classlly/features/library/widgets/dashboard_sidebar.dart';
import 'package:classlly/features/library/screens/add_course_screen.dart';
import 'package:classlly/features/library/screens/tasks_screen.dart';
import 'package:classlly/features/library/screens/calendar_screen.dart';
import 'package:classlly/features/library/screens/dashboard_screen.dart';
import 'package:classlly/features/library/widgets/empty_state.dart';
import 'package:classlly/features/text_editor/screens/text_editor_screen.dart';
import 'package:classlly/features/library/widgets/create_note_dialog.dart';
import 'package:classlly/l10n/app_localizations.dart';
import 'package:classlly/core/services/notification_service.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static void openNote(BuildContext context, Note note) {
    if (note.type == Note.typeText) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TextEditorScreen(note: note)),
      );
    } else {
      Provider.of<CanvasProvider>(context, listen: false).setNote(note);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CanvasScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    Future.microtask(() {
      libraryProvider.initSync();
      NotificationService().scheduleDailyNotification(
        id: 888,
        title: AppLocalizations.of(context)!.dailyAgenda,
        body: AppLocalizations.of(context)!.dailyAgendaBody,
        time: const TimeOfDay(hour: 17, minute: 30),
      );
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: MediaQuery.of(context).size.width <= 1000
          ? const Drawer(child: DashboardSidebar())
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (MediaQuery.of(context).size.width > 1000)
            const DashboardSidebar(),
          Expanded(
            child: SafeArea(
              child: _MainContentSwitch(view: libraryProvider.currentView),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainContentSwitch extends StatelessWidget {
  final LibraryView view;
  const _MainContentSwitch({required this.view});
  @override
  Widget build(BuildContext context) {
    switch (view) {
      case LibraryView.dashboard:
        return const DashboardScreen();
      case LibraryView.tasks:
        return const TasksScreen();
      case LibraryView.courses:
        return const _CoursesView();
      case LibraryView.calendar:
        return const CalendarScreen();
      case LibraryView.archive:
        return const _ArchiveView();
      case LibraryView.allNotes:
        return const _AllNotesView();
    }
  }
}

class _ArchiveView extends StatelessWidget {
  const _ArchiveView();
  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final deletedNotes = notesProvider.deletedNotes;
    final deletedTasks = taskProvider.deletedTasks;
    final deletedFolders = notesProvider.deletedFolders;

    final isEmpty =
        deletedNotes.isEmpty && deletedTasks.isEmpty && deletedFolders.isEmpty;

    if (isEmpty) {
      return Column(
        children: [
          if (MediaQuery.of(context).size.width <= 1000)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: EmptyState(
              icon: Icons.delete_outline,
              title: AppLocalizations.of(context)!.trashIsEmpty,
              subtitle:
                  AppLocalizations.of(context)!.trashEmptyDesc,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        if (MediaQuery.of(context).size.width <= 1000)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ],
            ),
          ),
        _SectionTitle(
          title: AppLocalizations.of(context)!.trash,
          subtitle:
              AppLocalizations.of(context)!.trashDesc,
        ),
        const SizedBox(height: 32),
        if (deletedFolders.isNotEmpty) ...[
          const Text(
            'Folders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...deletedFolders.map(
            (f) => _ArchiveTile(
              title: f.title,
              icon: Icons.folder,
              onRestore: () => notesProvider.restoreFolder(f.id),
              onDelete: () => notesProvider.permanentlyDeleteFolder(f.id),
            ),
          ),
          const SizedBox(height: 32),
        ],
        if (deletedNotes.isNotEmpty) ...[
          const Text(
            'Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...deletedNotes.map(
            (n) => _ArchiveTile(
              title: n.title,
              icon: Icons.description,
              onRestore: () => notesProvider.restoreNote(n.id),
              onDelete: () => notesProvider.permanentlyDeleteNote(n.id),
            ),
          ),
          const SizedBox(height: 32),
        ],
        if (deletedTasks.isNotEmpty) ...[
          const Text(
            'Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...deletedTasks.map(
            (t) => _ArchiveTile(
              title: t.title,
              icon: Icons.check_circle,
              onRestore: () => taskProvider.restoreTask(t.id),
              onDelete: () => taskProvider.permanentlyDeleteTask(t.id),
            ),
          ),
        ],
        // Add Empty Trash button at the bottom
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.emptyTrash),
                  content: Text(
                    AppLocalizations.of(context)!.emptyTrashConfirm,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        libraryProvider.emptyTrash();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.trashEmptied),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(AppLocalizations.of(context)!.emptyTrash),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: Text(AppLocalizations.of(context)!.emptyTrash),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _ArchiveTile({
    required this.title,
    required this.icon,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.green),
              onPressed: onRestore,
              tooltip: 'Restore',
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete Permanently',
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursesView extends StatelessWidget {
  const _CoursesView();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (width <= 1000)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              const Flexible(
                child: _SectionTitle(
                  title: 'My Courses',
                  subtitle: 'Access all your enrolled classes and materials.',
                ),
              ),
              if (isMobile) const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderButton(
                    icon: Icons.add_circle_outline,
                    label: 'Add Course',
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddCourseScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _CoursesGrid(fullList: true),
        ],
      ),
    );
  }
}

class _AllNotesView extends StatelessWidget {
  const _AllNotesView();
  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: Hive.box<Folder>(
        NotesRepository.folderBoxName,
      ).listenable(),
      builder: (context, Box<Folder> folderBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
          builder: (context, Box<Note> noteBox, _) {
            final repo = NotesRepository();
            final currentFolderId = notesProvider.currentFolderId;

            final folders = repo.getFolders(
              parentId: currentFolderId,
              type: FolderType.notebook,
            );
            final notes = repo.getNotesInFolder(currentFolderId);

            String title = 'My Notes';
            if (currentFolderId != null) {
              final currentFolder = folderBox.values
                  .where((f) => !f.isDeleted && f.id == currentFolderId)
                  .firstOrNull;
              title = currentFolder?.title ?? 'Folder';
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (MediaQuery.of(context).size.width <= 1000)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  Flex(
                    direction: MediaQuery.of(context).size.width < 700
                        ? Axis.vertical
                        : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: MediaQuery.of(context).size.width < 700
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentFolderId != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                final currentFolder = folderBox.values
                                    .where(
                                      (f) =>
                                          !f.isDeleted &&
                                          f.id == currentFolderId,
                                    )
                                    .firstOrNull;
                                notesProvider.navigateToFolder(
                                  currentFolder?.parentId,
                                );
                              },
                            ),
                          Flexible(
                            child: _SectionTitle(
                              title: title,
                              subtitle:
                                  '${folders.length} folders, ${notes.length} notes',
                            ),
                          ),
                        ],
                      ),
                      if (MediaQuery.of(context).size.width < 700)
                        const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HeaderButton(
                            icon: Icons.create_new_folder_outlined,
                            label: 'New Folder',
                            onPressed: () =>
                                _showCreateFolderDialog(context, notesProvider),
                          ),
                          const SizedBox(width: 12),
                          _HeaderButton(
                            icon: Icons.note_add_outlined,
                            label: 'New Note',
                            onPressed: () async {
                              final note = await showDialog<Note>(
                                context: context,
                                builder: (context) => const CreateNoteDialog(),
                              );
                              if (note != null && context.mounted) {
                                LibraryScreen.openNote(context, note);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (folders.isEmpty && notes.isEmpty)
                    Expanded(
                      child: EmptyState(
                        icon: Icons.folder_open_outlined,
                        title: 'Empty Folder',
                        subtitle:
                            'Organize your studies by creating folders or starting a new note.',
                        actionLabel: 'New Note',
                        onAction: () async {
                          final note = await showDialog<Note>(
                            context: context,
                            builder: (context) => const CreateNoteDialog(),
                          );
                          if (note != null && context.mounted) {
                            LibraryScreen.openNote(context, note);
                          }
                        },
                      ),
                    )
                  else ...[
                    if (folders.isNotEmpty) ...[
                      const Text(
                        'FOLDERS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.5,
                            ),
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return GestureDetector(
                            onTap: () =>
                                notesProvider.navigateToFolder(folder.id),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.folder,
                                        color: colorScheme.primary,
                                        size: 32,
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        onSelected: (value) {
                                          if (value == 'rename') {
                                            _showRenameFolderDialog(
                                              context,
                                              notesProvider,
                                              folder,
                                            );
                                          } else if (value == 'move') {
                                            _showMoveDialog(
                                              context,
                                              notesProvider,
                                              folderToMove: folder,
                                            );
                                          } else if (value == 'delete') {
                                            _showDeleteFolderDialog(
                                              context,
                                              notesProvider,
                                              folder,
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'rename',
                                            child: Text(AppLocalizations.of(context)!.rename),
                                          ),
                                          PopupMenuItem(
                                            value: 'move',
                                            child: Text(AppLocalizations.of(context)!.move),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              AppLocalizations.of(context)!.delete,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    folder.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (notes.isNotEmpty) ...[
                      const Text(
                        'NOTES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: notes.length,
                          itemBuilder: (context, index) =>
                              _RecentNoteItem(note: notes[index]),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context, NotesProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newFolder),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.folderName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createFolder(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(
    BuildContext context,
    NotesProvider provider,
    Folder folder,
  ) {
    final controller = TextEditingController(text: folder.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.renameFolder),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.folderName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameFolder(folder, controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(
    BuildContext context,
    NotesProvider provider,
    Folder folder,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteFolder),
        content: Text(
          AppLocalizations.of(context)!.deleteFolderConfirm(folder.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteFolder(folder.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(
    BuildContext context,
    NotesProvider provider, {
    Folder? folderToMove,
    Note? noteToMove,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.moveTo),
          content: SizedBox(
            width: 300,
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Folder>(
                NotesRepository.folderBoxName,
              ).listenable(),
              builder: (context, Box<Folder> box, _) {
                final folders = box.values
                    .where((f) => !f.isDeleted && f.type == FolderType.notebook)
                    .toList();

                if (folderToMove != null) {
                  folders.removeWhere((f) => f.id == folderToMove.id);
                }

                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: Text(AppLocalizations.of(context)!.myNotesRoot),
                      onTap: () {
                        if (folderToMove != null) {
                          provider.moveFolder(folderToMove, null);
                        } else if (noteToMove != null) {
                          provider.moveNote(noteToMove, null);
                        }
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ...folders.map(
                      (f) => ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(f.title),
                        onTap: () {
                          if (folderToMove != null) {
                            provider.moveFolder(folderToMove, f.id);
                          } else if (noteToMove != null) {
                            provider.moveNote(noteToMove, f.id);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
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
        );
      },
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  final bool fullList;
  const _CoursesGrid({this.fullList = false});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Course>(
        NotesRepository.courseBoxName,
      ).listenable(),
      builder: (context, Box<Course> box, _) {
        var courses = box.values.toList();

        if (!fullList) {
          courses = courses.take(3).toList();
        }

        if (courses.isEmpty) {
          return EmptyState(
            icon: Icons.school_outlined,
            title: 'No courses yet',
            subtitle: 'Add your first course to start tracking your schedule.',
            actionLabel: 'Add Course',
            onAction: () => showDialog(
              context: context,
              builder: (context) => const AddCourseScreen(),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = width > 1200
                ? 4
                : (width > 800 ? 3 : (width > 500 ? 2 : 1));

            // Adjust aspect ratio based on column count to ensure cards look good on all screens
            double aspectRatio = 1.2;
            if (crossAxisCount == 1) {
              aspectRatio = 1.8; // Wider cards for single column
            } else if (crossAxisCount == 2) {
              aspectRatio = 1.3;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: aspectRatio,
              children: courses.map((c) => _CourseCard(course: c)).toList(),
            );
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(course.color);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(course: course),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(course.icon, color: color, size: 24),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[800],
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              course.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              course.professor.isNotEmpty ? course.professor : 'No Professor',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text.rich(
              TextSpan(
                text: 'Next: ',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[600] : Colors.grey[900],
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text:
                        course.courseDay.isNotEmpty &&
                            course.courseTime.isNotEmpty
                        ? '${course.courseDay} ${course.courseTime}'
                        : (course.schedule.isNotEmpty
                              ? course.schedule
                              : 'Check Calendar'),
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: Hive.box<Task>(
                NotesRepository.taskBoxName,
              ).listenable(),
              builder: (context, Box<Task> taskBox, _) {
                final courseTasks = taskBox.values
                    .where((t) => !t.isDeleted && t.courseId == course.id)
                    .toList();
                double progress = 0.0;
                if (courseTasks.isNotEmpty) {
                  final completed = courseTasks
                      .where((t) => t.isCompleted)
                      .length;
                  progress = completed / courseTasks.length;
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.black : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentNoteItem extends StatelessWidget {
  final Note note;
  const _RecentNoteItem({required this.note});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => LibraryScreen.openNote(context, note),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isNotEmpty ? note.title : 'Untitled Note',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat.yMMMd().format(note.updatedAt)} • ${note.strokes.length} strokes',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[800],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[800],
                  ),
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameDialog(context, notesProvider);
                    } else if (value == 'move') {
                      _showMoveDialog(context, notesProvider);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, notesProvider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(value: 'move', child: Text('Move')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.moveNoteTo),
          content: SizedBox(
            width: 300,
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Folder>(
                NotesRepository.folderBoxName,
              ).listenable(),
              builder: (context, Box<Folder> box, _) {
                final folders = box.values
                    .where((f) => !f.isDeleted && f.type == FolderType.notebook)
                    .toList();

                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: Text(AppLocalizations.of(context)!.myNotesRoot),
                      onTap: () {
                        provider.moveNote(note, null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ...folders.map(
                      (f) => ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(f.title),
                        onTap: () {
                          provider.moveNote(note, f.id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
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
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, NotesProvider provider) {
    final controller = TextEditingController(text: note.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.renameNote),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.noteTitle,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameNote(note, controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNote),
        content: Text(
          AppLocalizations.of(context)!.deleteNoteConfirm(note.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteNote(note.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey[700],
              fontSize: 14,
            ),
            softWrap: true,
          ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }
}
