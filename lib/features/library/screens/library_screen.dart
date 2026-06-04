import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:classlly/features/library/screens/course_detail_screen.dart';
import 'package:classlly/features/library/widgets/dashboard_sidebar.dart';
import 'package:classlly/features/library/screens/add_course_screen.dart';
import 'package:classlly/features/library/screens/tasks_screen.dart';
import 'package:classlly/features/library/screens/calendar_screen.dart';
import 'package:classlly/features/library/screens/dashboard_screen.dart';
import 'package:classlly/features/library/screens/search_screen.dart';
import 'package:classlly/features/library/widgets/empty_state.dart';
import 'package:classlly/features/text_editor/screens/text_editor_screen.dart';
import 'package:classlly/features/library/widgets/create_note_dialog.dart';
import 'package:classlly/l10n/app_localizations.dart';
import 'package:classlly/core/services/notification_service.dart';
import 'package:classlly/core/widgets/glass_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();

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
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final courseProvider = Provider.of<CourseProvider>(
          context,
          listen: false,
        );
        libraryProvider.initSync();
        courseProvider.recalculateStats();
        if (!kIsWeb) {
          NotificationService().scheduleDailyNotification(
            id: 888,
            title: AppLocalizations.of(context)!.dailyAgenda,
            body: AppLocalizations.of(context)!.dailyAgendaBody,
            time: const TimeOfDay(hour: 6, minute: 0),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: MediaQuery.of(context).size.width <= 1000
          ? const Drawer(child: DashboardSidebar())
          : null,
      bottomNavigationBar: MediaQuery.of(context).size.width <= 1000
          ? const _MobileBottomNavBar()
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0A0A0A), Color(0xFF1C1C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.8,
                  colors: [
                    Color(0xFFE0F2FE), // sky-100
                    Color(0xFFF1F5F9), // slate-100
                    Color(0xFFFDF2F8), // pink-50
                  ],
                  stops: [0.0, 0.4, 0.8],
                ),
        ),
        child: Row(
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
          Expanded(
            child: EmptyState(
              icon: Icons.delete_outline,
              title: AppLocalizations.of(context)!.trashIsEmpty,
              subtitle: AppLocalizations.of(context)!.trashEmptyDesc,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(
              title: AppLocalizations.of(context)!.trash,
              subtitle: AppLocalizations.of(context)!.trashDesc,
            ),
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.emptyTrash),
                    content: Text(AppLocalizations.of(context)!.trashEmptyDesc),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(AppLocalizations.of(context)!.delete),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notesProvider.permanentlyDeleteAll();
                }
              },
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              label: Text(
                AppLocalizations.of(context)!.emptyTrash,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
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
                            content: Text(
                              AppLocalizations.of(context)!.trashEmptied,
                            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              isMobile
                  ? const _SectionTitle(
                      title: 'My Courses',
                      subtitle:
                          'Access all your enrolled classes and materials.',
                    )
                  : const Flexible(
                      child: _SectionTitle(
                        title: 'My Courses',
                        subtitle:
                            'Access all your enrolled classes and materials.',
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
          const SizedBox(height: 20),
          // ── Search Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search courses by name, professor, or code...',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _CoursesGrid(fullList: true),
        ],
      ),
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  final bool fullList;
  const _CoursesGrid({this.fullList = false});

  static const _categoryColors = {
    'Science': Color(0xFF10B981),
    'Tech': Color(0xFF3B82F6),
    'Mathematics': Color(0xFF8B5CF6),
    'Finance': Color(0xFFF59E0B),
    'Arts': Color(0xFFEC4899),
    'Language': Color(0xFF06B6D4),
    'Business': Color(0xFFF97316),
  };

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
                : (width > 900 ? 3 : (width > 600 ? 2 : 1));

            double aspectRatio = 1.15;
            if (crossAxisCount == 1) {
              aspectRatio = width > 400 ? 2.0 : 1.6;
            } else if (crossAxisCount == 2) {
              aspectRatio = 1.25;
            }

            final itemCount = fullList ? courses.length + 1 : courses.length;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: aspectRatio,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (fullList && index == courses.length) {
                  return _EnrollPlaceholderCard();
                }
                final c = courses[index];
                final cat = c.semester.isNotEmpty ? c.semester : 'General';
                final catColor =
                    _categoryColors[cat] ?? const Color(0xFF3B82F6);
                return _CourseCard(course: c, categoryColor: catColor);
              },
            );
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Color categoryColor;
  const _CourseCard({required this.course, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(course.color);
    final category = course.semester.isNotEmpty
        ? course.semester.toUpperCase()
        : 'COURSE';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(course: course),
        ),
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(course.icon, color: color, size: 22),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: categoryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              course.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              course.professor.isNotEmpty ? course.professor : 'No Professor',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
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
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text:
                        course.courseDay.isNotEmpty &&
                            course.courseTime.isNotEmpty
                        ? '${course.courseDay}, ${course.courseTime}'
                        : (course.schedule.isNotEmpty
                              ? course.schedule
                              : 'Check Calendar'),
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
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
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollPlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => const AddCourseScreen(),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ENROLL IN NEW COURSE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllNotesView extends StatefulWidget {
  const _AllNotesView();
  @override
  State<_AllNotesView> createState() => _AllNotesViewState();
}

class _AllNotesViewState extends State<_AllNotesView> {
  // Pastel colors for note card thumbnails
  static const List<Color> _pastelColors = [
    Color(0xFFBFDBFE), // blue
    Color(0xFFFBCFE8), // pink
    Color(0xFFBBF7D0), // green
    Color(0xFFFDE68A), // yellow
    Color(0xFFE9D5FF), // purple
    Color(0xFFFED7AA), // orange
  ];

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

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
            var notes = repo.getNotesInFolder(currentFolderId);

            String title = 'My Notes';
            if (currentFolderId != null) {
              final currentFolder = folderBox.values
                  .where((f) => !f.isDeleted && f.id == currentFolderId)
                  .firstOrNull;
              title = currentFolder?.title ?? 'Folder';
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + Title row
                  Row(
                    children: [
                      if (currentFolderId != null)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            final currentFolder = folderBox.values
                                .where(
                                  (f) =>
                                      !f.isDeleted && f.id == currentFolderId,
                                )
                                .firstOrNull;
                            notesProvider.navigateToFolder(
                              currentFolder?.parentId,
                            );
                          },
                        ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // New Folder button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              _showCreateFolderDialog(context, notesProvider),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.create_new_folder_outlined,
                                size: 16,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'New Folder',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Search button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SearchScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 16,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Search',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
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
                  const SizedBox(height: 20),

                  // Folders section
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
                          child: GlassCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.rename,
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'move',
                                          child: Text(
                                            AppLocalizations.of(context)!.move,
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.delete,
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

                  // Notes Gallery Grid
                  if (notes.isEmpty && folders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64),
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
                      ),
                    )
                  else if (notes.isNotEmpty) ...[
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int crossAxisCount = width > 1200
                            ? 4
                            : (width > 900 ? 3 : 2); // Mobile gets 2 columns

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: notes.length + 1, // +1 for placeholder
                          itemBuilder: (context, index) {
                            // Create New Note placeholder
                            if (index == notes.length) {
                              return _CreateNotePlaceholder();
                            }

                            final note = notes[index];
                            final pastelColor =
                                _pastelColors[index % _pastelColors.length];

                            return _NoteGalleryCard(
                              note: note,
                              pastelColor: pastelColor,
                            );
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
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

/// Gallery-style note card with colored thumbnail header
class _NoteGalleryCard extends StatelessWidget {
  final Note note;
  final Color pastelColor;
  const _NoteGalleryCard({required this.note, required this.pastelColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat.MMMd().format(note.updatedAt);

    return GestureDetector(
      onTap: () => LibraryScreen.openNote(context, note),
      child: GlassCard(
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored thumbnail header
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? pastelColor.withValues(alpha: 0.2)
                    : pastelColor.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.description_outlined,
                  size: 28,
                  color: isDark
                      ? pastelColor.withValues(alpha: 0.6)
                      : pastelColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge + date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: pastelColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NOTE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Bottom: status icon + more
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
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
}

/// Dashed "Create New Note" placeholder card
class _CreateNotePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () async {
        final note = await showDialog<Note>(
          context: context,
          builder: (context) => const CreateNoteDialog(),
        );
        if (note != null && context.mounted) {
          LibraryScreen.openNote(context, note);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.add, color: primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'CREATE NEW NOTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
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

class _MobileBottomNavBar extends StatelessWidget {
  const _MobileBottomNavBar();

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedIndex = 0;
    switch (libraryProvider.currentView) {
      case LibraryView.dashboard:
        selectedIndex = 0;
        break;
      case LibraryView.calendar:
        selectedIndex = 1;
        break;
      case LibraryView.courses:
        selectedIndex = 2;
        break;
      case LibraryView.tasks:
        selectedIndex = 3;
        break;
      default:
        selectedIndex = 4;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
          currentIndex: selectedIndex,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) {
            if (index == 0) {
              libraryProvider.setView(LibraryView.dashboard);
            } else if (index == 1) {
              libraryProvider.setView(LibraryView.calendar);
            } else if (index == 2) {
              libraryProvider.setView(LibraryView.courses);
            } else if (index == 3) {
              libraryProvider.setView(LibraryView.tasks);
            } else if (index == 4) {
              Scaffold.of(context).openDrawer();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_outlined),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded),
              ),
              label: AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.calendar_month_outlined),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.calendar_month_rounded),
              ),
              label: AppLocalizations.of(context)?.calendar ?? 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.auto_stories_outlined),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.auto_stories_rounded),
              ),
              label: AppLocalizations.of(context)?.courses ?? 'Courses',
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_outlined),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fact_check_rounded),
              ),
              label: AppLocalizations.of(context)?.tasks ?? 'Tasks',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.menu_rounded),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.menu_open_rounded),
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
