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
import 'package:classlly/main.dart'; 

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
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 900)
            const _LeftSidebar(),

          Expanded(
            child: Column(
              children: [
                const _TopHeader(),
                Expanded(
                  child: _MainContentSwitch(view: libraryProvider.currentView),
                ),
              ],
            ),
          ),

          if (MediaQuery.of(context).size.width > 1200 && libraryProvider.currentView == LibraryView.dashboard)
            const _RightSidebar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () => openNote(context, Note.create()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

void _showCreateNotebookDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("New Course/Notebook"),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: "Course Title (e.g. Biology 101)"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(
          onPressed: () async {
            if (controller.text.isNotEmpty) {
              final nb = Notebook.create(title: controller.text);
              await NotesRepository().saveNotebook(nb);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text("Create"),
        ),
      ],
    ),
  );
}

class _MainContentSwitch extends StatelessWidget {
  final LibraryView view;
  const _MainContentSwitch({required this.view});

  @override
  Widget build(BuildContext context) {
    switch (view) {
      case LibraryView.dashboard:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: "Active Courses", subtitle: "Manage your academic progress."),
              const SizedBox(height: 24),
              const _CoursesGrid(),
              const SizedBox(height: 32),
              const _SectionHeader(title: "Recent Quick Notes"),
              const SizedBox(height: 16),
              const _RecentNotesList(limit: 5),
            ],
          ),
        );
      case LibraryView.allNotes:
        return const _AllNotesView();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text("Coming Soon", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ],
          ),
        );
    }
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

        if (libraryProvider.searchQuery.isNotEmpty) {
          notes = notes.where((n) => 
            n.title.toLowerCase().contains(libraryProvider.searchQuery.toLowerCase())
          ).toList();
        }
        
        if (libraryProvider.selectedTag != null) {
           notes = notes.where((n) => 
            n.title.toLowerCase().contains(libraryProvider.selectedTag!.toLowerCase())
          ).toList();
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: libraryProvider.selectedTag != null ? "Notes: ${libraryProvider.selectedTag}" : "My Notes", 
                subtitle: "${notes.length} notes found"
              ),
              const SizedBox(height: 24),
              Expanded(
                child: notes.isEmpty 
                  ? Center(child: Text("No notes found", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (context, index) => _QuickNoteItem(note: notes[index], isGrid: true),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeftSidebar extends StatelessWidget {
  const _LeftSidebar();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text("Classlly", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          _NavItem(icon: Icons.grid_view, label: "Dashboard", isActive: provider.currentView == LibraryView.dashboard, onTap: () => provider.setView(LibraryView.dashboard)),
          _NavItem(icon: Icons.description, label: "My Notes", isActive: provider.currentView == LibraryView.allNotes, onTap: () => provider.setView(LibraryView.allNotes)),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("COURSES", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => _showCreateNotebookDialog(context),
                ),
              ],
            ),
          ),

          ValueListenableBuilder(
            valueListenable: Hive.box<Notebook>(NotesRepository.notebookBoxName).listenable(),
            builder: (context, Box<Notebook> box, _) {
              final notebooks = box.values.toList()..sort((a, b) => a.title.compareTo(b.title));
              return Column(
                children: notebooks.map((nb) => _NavItem(
                  icon: Icons.folder_open, 
                  label: nb.title, 
                  isActive: provider.selectedTag == nb.title,
                  onTap: () => provider.filterByTag(nb.title),
                )).toList(),
              );
            },
          ),

          _NavItem(icon: Icons.task_alt, label: "Tasks", isActive: provider.currentView == LibraryView.tasks, onTap: () => provider.setView(LibraryView.tasks)),
          _NavItem(icon: Icons.archive, label: "Archive", isActive: provider.currentView == LibraryView.archive, onTap: () => provider.setView(LibraryView.archive)),

          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Alex Johnson", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text("Computer Science", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryPurple;
    final inactiveColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? activeColor : inactiveColor),
        title: Text(label, style: TextStyle(color: isActive ? activeColor : inactiveColor, fontWeight: FontWeight.w500)),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                onChanged: (value) {
                  provider.setSearchQuery(value);
                  if (provider.currentView != LibraryView.allNotes) {
                    provider.setView(LibraryView.allNotes);
                  }
                },
                decoration: InputDecoration(
                  hintText: "Search notes...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
          ),
          const SizedBox(width: 24),
          if (provider.lastSynced != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_done, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text("Synced", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    "at ${DateFormat.jm().format(provider.lastSynced!)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications, color: Colors.grey)),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode,
              color: Colors.grey,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme(
                Theme.of(context).brightness == Brightness.light,
              );
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => LibraryScreen.openNote(context, Note.create()),
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Quick Add"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
        IconButton(icon: const Icon(Icons.filter_list, color: Colors.grey), onPressed: () {}),
      ],
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  const _CoursesGrid();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context, listen: false);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 1.1,
          children: [
            _CourseCard(title: "Biology 101", prof: "Dr. Emily Stone", color: Colors.blue, icon: Icons.biotech, tag: "Science", lastNote: "Cellular Respiration Lab", onTap: () => provider.filterByTag("Science")),
            _CourseCard(title: "Calculus II", prof: "Prof. Mark Webber", color: Colors.amber, icon: Icons.calculate, tag: "Math", lastNote: "Integrals by Substitution", onTap: () => provider.filterByTag("Math")),
            _CourseCard(title: "Modern Lit", prof: "Dr. Sarah Jenkins", color: Colors.green, icon: Icons.menu_book, tag: "Arts", lastNote: "Analysis of The Great Gatsby", onTap: () => provider.filterByTag("Arts")),
          ],
        );
      },
    );
  }
}

class _RecentNotesList extends StatelessWidget {
  final int? limit;
  const _RecentNotesList({super.key, this.limit});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, Box<Note> box, _) {
        var notes = box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (limit != null) notes = notes.take(limit!).toList();
        
        return Column(
          children: notes.map((note) => _QuickNoteItem(note: note)).toList(),
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final String prof;
  final Color color;
  final IconData icon;
  final String tag;
  final String lastNote;
  final VoidCallback onTap;

  const _CourseCard({required this.title, required this.prof, required this.color, required this.icon, required this.tag, required this.lastNote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(tag.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(prof, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), 
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(color: Theme.of(context).dividerColor)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("LATEST NOTE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(lastNote, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNoteItem extends StatelessWidget {
  final Note note;
  final bool isGrid;
  const _QuickNoteItem({required this.note, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: () => LibraryScreen.openNote(context, note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isGrid ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(note.title.isNotEmpty ? note.title : 'Untitled Note', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ),
                if (!isGrid) const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            if (isGrid) const Spacer(),
            Row(
              children: [
                Text(DateFormat.yMMMd().format(note.updatedAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (note.audioPath != null) ...[
                  const Spacer(),
                  const Icon(Icons.mic, size: 16, color: AppTheme.primaryPurple),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RightSidebar extends StatelessWidget {
  const _RightSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("October 2023", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(30, (index) => Center(
                    child: Text(
                      "${index + 1}", 
                      style: TextStyle(
                        color: index == 24 ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : Colors.grey, 
                        fontWeight: index == 24 ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming Deadlines", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Text("See all", style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          const _DeadlineItem(title: "Biology Lab Report", time: "Tomorrow, 11:59 PM", color: Colors.red),
          const _DeadlineItem(title: "Calc Quiz (Ch 4)", time: "Oct 27, 09:00 AM", color: Colors.amber),
          const _DeadlineItem(title: "Lit Essay Draft", time: "Oct 30, 05:00 PM", color: Colors.blue),
        ],
      ),
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final String title;
  final String time;
  final Color color;

  const _DeadlineItem({required this.title, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}