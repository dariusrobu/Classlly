import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/canvas/screens/canvas_screen.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/features/auth/screens/profile_screen.dart';
import 'package:classlly/features/library/screens/settings_screen.dart';
import 'package:classlly/features/library/screens/course_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static void openNote(BuildContext context, Note note) {
    Provider.of<CanvasProvider>(context, listen: false).setNote(note);
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CanvasScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    Future.microtask(() => libraryProvider.initSync());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 1000) const _DashboardSidebar(),
          Expanded(
            child: Column(
              children: [
                const _DashboardHeader(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _MainContentSwitch(view: libraryProvider.currentView)),
                      if (MediaQuery.of(context).size.width > 1300 && libraryProvider.currentView == LibraryView.dashboard)
                        const _RightDashboardSidebar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: AppTheme.primaryPurple, onPressed: () => openNote(context, Note.create()), child: const Icon(Icons.add, color: Colors.white, size: 30)),
    );
  }
}

class _MainContentSwitch extends StatelessWidget {
  final LibraryView view;
  const _MainContentSwitch({required this.view});
  @override
  Widget build(BuildContext context) {
    switch (view) {
      case LibraryView.dashboard: return const _DashboardView();
      case LibraryView.tasks: return const _TasksView();
      case LibraryView.courses: return const _CoursesView();
      case LibraryView.calendar: return const _CalendarView();
      case LibraryView.archive: return const _ArchiveView();
      case LibraryView.allNotes: return const _AllNotesView();
      default: return const Center(child: Text("Coming Soon"));
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: "Active Courses", subtitle: "Manage your academic progress and notes."),
          const SizedBox(height: 24),
          const _CoursesGrid(),
          const SizedBox(height: 48),
          const _SectionTitle(title: "Recent Quick Notes"),
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
              const _SectionTitle(title: "Archived Items", subtitle: "View your past courses and notes."),
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
              _ArchivedCourseCard(title: "Biology 100", meta: "Fall 2022 • Dr. Stone", icon: Icons.biotech, lastNote: "Final Exam Prep"),
              _ArchivedCourseCard(title: "Calculus I", meta: "Spring 2022 • Prof. Webber", icon: Icons.calculate, lastNote: "Derivatives Summary"),
              _ArchivedCourseCard(title: "World History", meta: "Fall 2021 • Dr. Grant", icon: Icons.history_edu, lastNote: "Industrial Revolution"),
            ],
          ),
          const SizedBox(height: 48),
          const _SectionTitle(title: "Archived Notes"),
          const SizedBox(height: 24),
          const _ArchivedNoteTile(title: "Freshman Orientation Notes", meta: "Aug 25, 2021 • General"),
          const SizedBox(height: 12),
          const _ArchivedNoteTile(title: "Dorm Meeting Minutes", meta: "Sep 05, 2021 • Personal"),
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
              const _SectionTitle(title: "My Courses", subtitle: "Access all your enrolled classes and materials."),
              Row(children: [_HeaderButton(icon: Icons.sort, label: "Sort by", onPressed: () {}), const SizedBox(width: 8), _IconButton(icon: Icons.filter_list, onPressed: () {})]),
            ],
          ),
          const SizedBox(height: 24),
          const _CoursesGrid(fullList: true),
        ],
      ),
    );
  }
}

class _TasksView extends StatelessWidget {
  const _TasksView();
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
              const _SectionTitle(title: "Task Board", subtitle: "Manage your academic tasks and milestones."),
              Row(children: [_HeaderButton(icon: Icons.filter_list, label: "Filter", onPressed: () {}), const SizedBox(width: 8), _IconButton(icon: Icons.sort, onPressed: () {})]),
            ],
          ),
          const SizedBox(height: 32),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TaskColumn(title: "To Do", count: 3, color: Colors.grey, tasks: [
                _TaskCard(title: "Biology Lab Report", desc: "Complete analysis.", tag: "Science", priority: "High", due: "Tomorrow"),
                _TaskCard(title: "Calculus Problem Set #4", desc: "Practice integrals.", tag: "Math", priority: "Medium", due: "Oct 27"),
              ])),
              SizedBox(width: 24),
              Expanded(child: _TaskColumn(title: "In Progress", count: 2, color: AppTheme.primaryPurple, tasks: [
                _TaskCard(title: "Group Presentation Slides", desc: "Design deck.", tag: "Project", priority: "High", due: "Oct 29"),
              ])),
              SizedBox(width: 24),
              Expanded(child: _TaskColumn(title: "Done", count: 2, color: Colors.green, tasks: [
                _TaskCard(title: "Essay Outline Draft", desc: "Initial structure.", tag: "Arts", priority: "Medium", due: "Completed", isDone: true),
              ])),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: "Study Calendar", subtitle: "Organize your lectures and sessions."),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)), child: const Column(children: [Text("October 2023", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height: 20), Text("Calendar Grid Placeholder")]))),
              const SizedBox(width: 32),
              Expanded(flex: 1, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)), child: const Text("Schedule Panel"))),
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
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, Box<Note> box, _) {
        var notes = box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: libraryProvider.selectedTag != null ? "Notes: ${libraryProvider.selectedTag}" : "My Notes", subtitle: "${notes.length} notes found"),
              const SizedBox(height: 24),
              Expanded(child: ListView.builder(itemCount: notes.length, itemBuilder: (context, index) => _RecentNoteItem(note: notes[index]))),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar();
  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    return Container(
      width: 260,
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(right: BorderSide(color: Theme.of(context).dividerColor))),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(24), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primaryPurple, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit_note, color: Colors.white)), const SizedBox(width: 12), const Text("Classlly", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
          _SidebarItem(icon: Icons.grid_view, label: "Dashboard", isActive: libraryProvider.currentView == LibraryView.dashboard, onTap: () => libraryProvider.setView(LibraryView.dashboard)),
          _SidebarItem(icon: Icons.school, label: "Courses", isActive: libraryProvider.currentView == LibraryView.courses, onTap: () => libraryProvider.setView(LibraryView.courses)),
          _SidebarItem(icon: Icons.task_alt, label: "Tasks", isActive: libraryProvider.currentView == LibraryView.tasks, onTap: () => libraryProvider.setView(LibraryView.tasks)),
          _SidebarItem(icon: Icons.calendar_today, label: "Calendar", isActive: libraryProvider.currentView == LibraryView.calendar, onTap: () => libraryProvider.setView(LibraryView.calendar)),
          _SidebarItem(icon: Icons.archive, label: "Archive", isActive: libraryProvider.currentView == LibraryView.archive, onTap: () => libraryProvider.setView(LibraryView.archive)),
          const Spacer(),
          Padding(padding: const EdgeInsets.all(16), child: _UserCard()),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon; final String label; final bool isActive; final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label, this.isActive = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(color: isActive ? AppTheme.primaryPurple.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: isActive ? const Border(right: BorderSide(color: AppTheme.primaryPurple, width: 3)) : null),
      child: ListTile(leading: Icon(icon, color: isActive ? AppTheme.vibrantPurple : Colors.grey, size: 22), title: Text(label, style: TextStyle(color: isActive ? AppTheme.vibrantPurple : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 14)), onTap: onTap, dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }
}

class _UserCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)), child: const Row(children: [CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=alex')), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Alex Johnson", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), Text("Computer Science", style: TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)]))])),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();
  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isArchive = libraryProvider.currentView == LibraryView.archive;

    return Container(
      height: 64, padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9), border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(
        children: [
          Expanded(child: Container(constraints: const BoxConstraints(maxWidth: 400), child: TextField(decoration: InputDecoration(hintText: isArchive ? "Search archive..." : "Search notes...", hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: EdgeInsets.zero)))),
          const SizedBox(width: 24),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.grey)),
          if (isArchive)
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.delete_sweep, size: 18), label: const Text("Empty Trash"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))
          else
            ElevatedButton.icon(onPressed: () => LibraryScreen.openNote(context, Note.create()), icon: const Icon(Icons.add, size: 18), label: const Text("Quick Add"), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
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
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
      return GridView.count(
        crossAxisCount: crossAxisCount, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 1.1,
        children: [
          const _CourseCard(title: "Biology 101", prof: "Dr. Emily Stone", color: Colors.blue, icon: Icons.biotech, tag: "Science", lastNote: "Cellular Respiration Lab"),
          const _CourseCard(title: "Calculus II", prof: "Prof. Mark Webber", color: Colors.amber, icon: Icons.calculate, tag: "Math", lastNote: "Substitution"),
          const _CourseCard(title: "Modern Lit", prof: "Dr. Sarah Jenkins", color: Colors.green, icon: Icons.menu_book, tag: "Arts", lastNote: "Gatsby"),
          if (fullList) ...[const _CourseCard(title: "World History", prof: "Prof. Grant", color: Colors.pink, icon: Icons.history_edu, tag: "History", lastNote: "Revolution")],
        ],
      );
    });
  }
}

class _CourseCard extends StatelessWidget {
  final String title; final String prof; final Color color; final IconData icon; final String tag; final String lastNote;
  const _CourseCard({required this.title, required this.prof, required this.color, required this.icon, required this.tag, required this.lastNote});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(title: title, prof: prof, color: color))),
      child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(tag.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)))]), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)), child: Text(lastNote, style: const TextStyle(fontSize: 12)))]))
    );
  }
}

class _RecentNotesList extends StatelessWidget {
  const _RecentNotesList();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(), builder: (context, Box<Note> box, _) {
      var notes = box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Column(children: notes.take(5).map((n) => _RecentNoteItem(note: n)).toList());
    });
  }
}

class _RecentNoteItem extends StatelessWidget {
  final Note note;
  const _RecentNoteItem({required this.note});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)), child: InkWell(onTap: () => LibraryScreen.openNote(context, note), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(note.title.isNotEmpty ? note.title : 'Untitled Note', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text(DateFormat.yMMMd().format(note.updatedAt), style: const TextStyle(color: Colors.grey))])), const Icon(Icons.chevron_right, color: Colors.grey)])));
  }
}

class _RightDashboardSidebar extends StatelessWidget {
  const _RightDashboardSidebar();
  @override
  Widget build(BuildContext context) {
    return Container(width: 320, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(left: BorderSide(color: Theme.of(context).dividerColor))), child: Column(children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)), child: const Text("Calendar Placeholder")), const SizedBox(height: 40), const _DeadlineTile(title: "Biology Lab", time: "Tomorrow", color: Colors.red), _PremiumRocketCard()]));
  }
}

class _DeadlineTile extends StatelessWidget {
  final String title; final String time; final Color color;
  const _DeadlineTile({required this.title, required this.time, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12))]))]));
  }
}

class _PremiumRocketCard extends StatelessWidget {
  const _PremiumRocketCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2))), child: const Text("Premium Card"));
  }
}

class _SectionTitle extends StatelessWidget {
  final String title; final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 14))]);
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onPressed;
  const _HeaderButton({required this.icon, required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: Text(label), style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).cardColor));
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onPressed;
  const _IconButton({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon, size: 18), onPressed: onPressed);
  }
}

class _TaskColumn extends StatelessWidget {
  final String title; final int count; final Color color; final List<Widget> tasks;
  const _TaskColumn({required this.title, required this.count, required this.color, required this.tasks});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), const SizedBox(height: 12), ...tasks]);
  }
}

class _TaskCard extends StatelessWidget {
  final String title; final String desc; final String tag; final String priority; final String due; final bool isDone;
  const _TaskCard({required this.title, required this.desc, required this.tag, required this.priority, required this.due, this.isDone = false});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Text(title));
  }
}

class _ArchivedCourseCard extends StatelessWidget {
  final String title; final String meta; final IconData icon; final String lastNote;
  const _ArchivedCourseCard({required this.title, required this.meta, required this.icon, required this.lastNote});
  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: 0.75, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.grey, size: 24)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)), child: const Text("ARCHIVED", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))]), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)), Text(meta, style: const TextStyle(color: Colors.grey, fontSize: 11)), const Spacer(), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("LAST ACCESSED", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)), Text(lastNote, style: const TextStyle(fontSize: 12, color: Colors.white54), overflow: TextOverflow.ellipsis)]))])));
  }
}

class _ArchivedNoteTile extends StatelessWidget {
  final String title; final String meta;
  const _ArchivedNoteTile({required this.title, required this.meta});
  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: 0.8, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)), child: Row(children: [const Icon(Icons.description, color: Colors.grey, size: 20), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)), Text(meta, style: const TextStyle(color: Colors.grey, fontSize: 12))])), const Icon(Icons.chevron_right, color: Colors.white10)])));
  }
}
