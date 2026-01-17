import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/canvas/screens/canvas_screen.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/screens/course_detail_screen.dart';
import 'package:classlly/features/library/widgets/dashboard_sidebar.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/library/screens/add_course_screen.dart';
import 'package:classlly/features/library/screens/tasks_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static void openNote(BuildContext context, Note note) {
    Provider.of<CanvasProvider>(context, listen: false).setNote(note);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CanvasScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    Future.microtask(() => libraryProvider.initSync());

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
            child: Column(
              children: [
                const _DashboardHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _MainContentSwitch(
                          view: libraryProvider.currentView,
                        ),
                      ),
                      if (MediaQuery.of(context).size.width > 1300 &&
                          libraryProvider.currentView == LibraryView.dashboard)
                        const _RightDashboardSidebar(),
                    ],
                  ),
                ),
              ],
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
        return const _DashboardView();
      case LibraryView.tasks:
        return const TasksScreen();
      case LibraryView.courses:
        return const _CoursesView();
      case LibraryView.calendar:
        return const _CalendarView();
      case LibraryView.archive:
        return const _ArchiveView();
      case LibraryView.allNotes:
        return const _AllNotesView();
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(DateTime.now()),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[500] : Colors.grey[700],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome back, Alex!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have 3 lectures today. Ready to take some notes?',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(
                title: 'Dashboard Overview',
                subtitle: 'Track your progress and stay organized.',
              ),
              _IconButton(icon: Icons.filter_list, onPressed: () {}),
            ],
          ),
          const SizedBox(height: 24),
          const _DashboardStatsGrid(),
          const SizedBox(height: 56),

          const _SectionTitle(
            title: 'Active Courses',
            subtitle: 'Manage your academic progress and notes.',
          ),
          const SizedBox(height: 24),
          const _CoursesGrid(),
          const SizedBox(height: 56),
          const _SectionTitle(
            title: 'Recent Quick Notes',
            subtitle: 'Pick up where you left off.',
          ),
          const SizedBox(height: 24),
          const _RecentNotesList(),
        ],
      ),
    );
  }
}

class _ArchiveView extends StatelessWidget {
  const _ArchiveView();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(
                title: 'Archived Items',
                subtitle: 'View your past courses and notes.',
              ),
              _IconButton(icon: Icons.filter_list, onPressed: () {}),
            ],
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 1.1,
            children: const [
              _ArchivedCourseCard(
                title: 'Biology 100',
                meta: 'Fall 2022 • Dr. Stone',
                icon: Icons.biotech,
                lastNote: 'Final Exam Prep',
              ),
              _ArchivedCourseCard(
                title: 'Calculus I',
                meta: 'Spring 2022 • Prof. Webber',
                icon: Icons.calculate,
                lastNote: 'Derivatives Summary',
              ),
              _ArchivedCourseCard(
                title: 'World History',
                meta: 'Fall 2021 • Dr. Grant',
                icon: Icons.history_edu,
                lastNote: 'Industrial Revolution',
              ),
            ],
          ),
          const SizedBox(height: 48),
          const _SectionTitle(title: 'Archived Notes'),
          const SizedBox(height: 24),
          const _ArchivedNoteTile(
            title: 'Freshman Orientation Notes',
            meta: 'Aug 25, 2021 • General',
          ),
          const SizedBox(height: 12),
          const _ArchivedNoteTile(
            title: 'Dorm Meeting Minutes',
            meta: 'Sep 05, 2021 • Personal',
          ),
        ],
      ),
    );
  }
}

class _CoursesView extends StatelessWidget {
  const _CoursesView();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(
                title: 'My Courses',
                subtitle: 'Access all your enrolled classes and materials.',
              ),
              Row(
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

class _CalendarView extends StatelessWidget {
  const _CalendarView();
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Study Calendar',
            subtitle: 'Organize your lectures and sessions.',
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: DateTime.now(),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      weekendTextStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _DeadlineTile(
                        title: 'Biology 101',
                        time: '10:00 AM - 11:30 AM',
                        color: Colors.blue,
                      ),
                      _DeadlineTile(
                        title: 'Calculus II',
                        time: '1:00 PM - 2:30 PM',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllNotesView extends StatelessWidget {
  const _AllNotesView();
  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ValueListenableBuilder(
      valueListenable: Hive.box<Folder>(
        NotesRepository.folderBoxName,
      ).listenable(),
      builder: (context, Box<Folder> folderBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
          builder: (context, Box<Note> noteBox, _) {
            final repo = NotesRepository();
            final currentFolderId = libraryProvider.currentFolderId;

            final folders = repo.getFolders(
              parentId: currentFolderId,
              type: FolderType.notebook,
            );
            final notes = repo.getNotesInFolder(currentFolderId);

            String title = 'My Notes';
            if (currentFolderId != null) {
              // Find current folder name (inefficient but simple for now)
              final currentFolder = folderBox.values
                  .where((f) => f.id == currentFolderId)
                  .firstOrNull;
              title = currentFolder?.title ?? 'Folder';
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (currentFolderId != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                // Find parent of current folder to go back
                                final currentFolder = folderBox.values
                                    .where((f) => f.id == currentFolderId)
                                    .firstOrNull;
                                libraryProvider.navigateToFolder(
                                  currentFolder?.parentId,
                                );
                              },
                            ),
                          _SectionTitle(
                            title: title,
                            subtitle:
                                '${folders.length} folders, ${notes.length} notes',
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _HeaderButton(
                            icon: Icons.create_new_folder_outlined,
                            label: 'New Folder',
                            onPressed: () => _showCreateFolderDialog(
                              context,
                              libraryProvider,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _HeaderButton(
                            icon: Icons.note_add_outlined,
                            label: 'New Note',
                            onPressed: () async {
                              final note =
                                  await libraryProvider
                                      .createNoteInCurrentFolder();
                              if (context.mounted) {
                                LibraryScreen.openNote(context, note);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                          onTap:
                              () => libraryProvider.navigateToFolder(folder.id),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      color: primaryColor,
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
                                            libraryProvider,
                                            folder,
                                          );
                                        } else if (value == 'delete') {
                                          _showDeleteFolderDialog(
                                            context,
                                            libraryProvider,
                                            folder,
                                          );
                                        }
                                      },
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: 'rename',
                                              child: Text('Rename'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
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
                        itemBuilder:
                            (context, index) =>
                                _RecentNoteItem(note: notes[index]),
                      ),
                    ),
                  ] else if (folders.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Empty folder. Create a note or folder to get started.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateFolderDialog(
    BuildContext context,
    LibraryProvider provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('New Folder'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Folder Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    provider.createFolder(controller.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  void _showRenameFolderDialog(
    BuildContext context,
    LibraryProvider provider,
    Folder folder,
  ) {
    final controller = TextEditingController(text: folder.title);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Folder'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Folder Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    provider.renameFolder(folder, controller.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showDeleteFolderDialog(
    BuildContext context,
    LibraryProvider provider,
    Folder folder,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Folder'),
            content: Text(
              'Are you sure you want to delete "${folder.title}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();
  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isArchive = libraryProvider.currentView == LibraryView.archive;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (MediaQuery.of(context).size.width <= 1000) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          if (isArchive)
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text('Empty Trash'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'note') {
                  LibraryScreen.openNote(context, Note.create());
                }
                if (value == 'task') {
                  showDialog(
                    context: context,
                    builder: (context) => const AddTaskScreen(),
                  );
                }
                if (value == 'course') {
                  showDialog(
                    context: context,
                    builder: (context) => const AddCourseScreen(),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'note',
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 18),
                      SizedBox(width: 8),
                      Text('New Note'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'task',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      SizedBox(width: 8),
                      Text('New Task'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'course',
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 18),
                      SizedBox(width: 8),
                      Text('New Course'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Quick Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'No courses yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddCourseScreen(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Your First Course'),
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200
                ? 4
                : (constraints.maxWidth > 800
                      ? 3
                      : (constraints.maxWidth > 500 ? 2 : 1));
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.2,
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
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.65, // Mock value
                backgroundColor: isDark ? Colors.black : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentNotesList extends StatelessWidget {
  const _RecentNotesList();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, Box<Note> box, _) {
        var notes = box.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return Column(
          children: notes.take(5).map((n) => _RecentNoteItem(note: n)).toList(),
        );
      },
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[800],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RightDashboardSidebar extends StatelessWidget {
  const _RightDashboardSidebar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const _MiniCalendar(),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Deadlines',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See all', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Task>(
                NotesRepository.taskBoxName,
              ).listenable(),
              builder: (context, Box<Task> box, _) {
                final deadlines =
                    box.values
                        .where((t) => !t.isCompleted && t.dueDate != null)
                        .toList()
                      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
                final displayDeadlines = deadlines.take(3).toList();

                if (displayDeadlines.isEmpty) {
                  return const Center(
                    child: Text(
                      'No upcoming deadlines',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: displayDeadlines.length,
                  itemBuilder: (context, index) {
                    final task = displayDeadlines[index];
                    final isTomorrow =
                        task.dueDate!.day ==
                        DateTime.now().add(const Duration(days: 1)).day;
                    return _DeadlineTile(
                      title: task.title,
                      time: isTomorrow
                          ? 'Tomorrow, ${DateFormat.Hm().format(task.dueDate!)}'
                          : DateFormat.yMMMd().add_Hm().format(task.dueDate!),
                      color: isTomorrow
                          ? Colors.redAccent
                          : Theme.of(context).colorScheme.primary,
                    );
                  },
                );
              },
            ),
          ),
          const _PremiumRocketCard(),
        ],
      ),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          leftChevronIcon: Icon(Icons.chevron_left, size: 20),
          rightChevronIcon: Icon(Icons.chevron_right, size: 20),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          outsideTextStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        rowHeight: 36,
        availableGestures: AvailableGestures.all,
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  final String title;
  final String time;
  final Color color;
  const _DeadlineTile({
    required this.title,
    required this.time,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumRocketCard extends StatelessWidget {
  const _PremiumRocketCard();
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: const Text('Premium Card'),
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
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey[700],
              fontSize: 14,
            ),
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _IconButton({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon, size: 18), onPressed: onPressed);
  }
}

class _ArchivedCourseCard extends StatelessWidget {
  final String title;
  final String meta;
  final IconData icon;
  final String lastNote;
  const _ArchivedCourseCard({
    required this.title,
    required this.meta,
    required this.icon,
    required this.lastNote,
  });
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.75,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
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
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.grey, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ARCHIVED',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            Text(
              meta,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAST ACCESSED',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    lastNote,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedNoteTile extends StatelessWidget {
  final String title;
  final String meta;
  const _ArchivedNoteTile({required this.title, required this.meta});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.description, color: Colors.grey, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    meta,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white10),
          ],
        ),
      ),
    );
  }
}

class _DashboardStatsGrid extends StatelessWidget {
  const _DashboardStatsGrid();

  @override
  Widget build(BuildContext context) {
    // 4 columns on wide screens, 2 on medium, 1 on small
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int cols = width > 1400 ? 4 : (width > 900 ? 2 : 1);
        double ratio = width > 1400 ? 1.4 : (width > 900 ? 2.2 : 1.8);

        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          shrinkWrap: true,
          childAspectRatio: ratio,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _RecentNotesCard(),
            _GradeOverviewCard(),
            _AttendanceCard(),
            _TasksSummaryCard(),
          ],
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;
  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
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
        child: child,
      );
  }
}

class _RecentNotesCard extends StatelessWidget {
  const _RecentNotesCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, Box<Note> box, _) {
        final notes = box.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final recentNotes = notes.take(3).toList();

        return _DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_edu, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentNotes.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No notes yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentNotes.length,
                    itemBuilder: (context, index) {
                      final note = recentNotes[index];
                      return _miniNoteItem(
                        context,
                        note.title.isNotEmpty ? note.title : 'Untitled',
                        '${DateFormat.Md().format(note.updatedAt)} • ${note.strokes.length} strokes',
                        Icons.description_outlined,
                        colorScheme.primary,
                        onTap: () => LibraryScreen.openNote(context, note),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniNoteItem(
    BuildContext context,
    String title,
    String meta,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    meta,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

class _GradeOverviewCard extends StatelessWidget {
  const _GradeOverviewCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: Hive.box<Grade>(
        NotesRepository.gradeBoxName,
      ).listenable(),
      builder: (context, Box<Grade> box, _) {
        final grades = box.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        double avg = 0;
        if (grades.isNotEmpty) {
          avg =
              grades
                  .map((g) => (g.score / g.maxScore) * 100)
                  .reduce((a, b) => a + b) /
              grades.length;
        }

        final spots = grades.asMap().entries.map((e) {
          return FlSpot(
            e.key.toDouble(),
            (e.value.score / e.value.maxScore) * 6,
          ); // Scale to 0-6 for chart
        }).toList();

        if (spots.isEmpty) {
          // Dummy data for empty state
          spots.addAll(const [FlSpot(0, 3), FlSpot(1, 3)]);
        }

        return _DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grade Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.black87,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        grades.isEmpty
                            ? 'No Data'
                            : (avg >= 90
                                  ? 'Excellent'
                                  : (avg >= 80 ? 'Good' : 'Average')),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Avg: ${avg.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble() + 0.5,
                    minY: 0,
                    maxY: 6,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Start',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    'Current',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Attendance>(
        NotesRepository.attendanceBoxName,
      ).listenable(),
      builder: (context, Box<Attendance> box, _) {
        final records = box.values.toList();
        double attendance = 0;
        int percentage = 0;

        if (records.isNotEmpty) {
          final present = records
              .where((r) => r.status == AttendanceStatus.present)
              .length;
          attendance = present / records.length;
          percentage = (attendance * 100).toInt();
        } else {
          // Placeholder if no data
          attendance = 0;
          percentage = 0;
        }

        return _DashboardCard(
          child: Stack(
            children: [
              Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[200]
                      : Colors.black87,
                ),
              ),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: attendance,
                        strokeWidth: 10,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        color: percentage > 75
                            ? Colors.greenAccent
                            : (percentage > 50
                                  ? Colors.amber
                                  : Colors.redAccent),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'PRESENT',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    percentage > 90
                        ? 'Perfect Attendance!'
                        : (records.isEmpty
                              ? 'No records yet.'
                              : 'Keep tracking!'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TasksSummaryCard extends StatelessWidget {
  const _TasksSummaryCard();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>(NotesRepository.taskBoxName).listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values.toList();
        final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
        final displayTasks = tasks.take(3).toList();

        return _DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingTasks.length} Pending',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (displayTasks.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No tasks yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayTasks.length,
                    itemBuilder: (context, index) {
                      final task = displayTasks[index];
                      return _taskItem(
                        context,
                        task.title,
                        task.isCompleted,
                        colorScheme.primary,
                        onTap: () => provider.toggleTask(task),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _taskItem(
    BuildContext context,
    String title,
    bool isCompleted,
    Color primaryColor, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? primaryColor : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
