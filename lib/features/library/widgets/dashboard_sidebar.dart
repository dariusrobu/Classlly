import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/auth/screens/profile_screen.dart';
import 'package:classlly/features/library/screens/settings_screen.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Classlly',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            isActive: libraryProvider.currentView == LibraryView.dashboard,
            onTap: () =>
                _navigate(context, libraryProvider, LibraryView.dashboard),
          ),
          SidebarItem(
            icon: Icons.description_rounded,
            label: 'Notes',
            isActive: libraryProvider.currentView == LibraryView.allNotes,
            onTap: () =>
                _navigate(context, libraryProvider, LibraryView.allNotes),
          ),
          SidebarItem(
            icon: Icons.school_rounded,
            label: 'Courses',
            isActive: libraryProvider.currentView == LibraryView.courses,
            onTap: () =>
                _navigate(context, libraryProvider, LibraryView.courses),
          ),
          SidebarItem(
            icon: Icons.task_alt_rounded,
            label: 'Tasks',
            isActive: libraryProvider.currentView == LibraryView.tasks,
            onTap: () => _navigate(context, libraryProvider, LibraryView.tasks),
          ),
          SidebarItem(
            icon: Icons.calendar_today_rounded,
            label: 'Calendar',
            isActive: libraryProvider.currentView == LibraryView.calendar,
            onTap: () =>
                _navigate(context, libraryProvider, LibraryView.calendar),
          ),
          SidebarItem(
            icon: Icons.archive_rounded,
            label: 'Archive',
            isActive: libraryProvider.currentView == LibraryView.archive,
            onTap: () =>
                _navigate(context, libraryProvider, LibraryView.archive),
          ),
          SidebarItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isActive: false,
            onTap: () {
              if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                Navigator.pop(context);
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Spacer(),
          const Padding(padding: EdgeInsets.all(24), child: UserCard()),
        ],
      ),
    );
  }

  void _navigate(
    BuildContext context,
    LibraryProvider provider,
    LibraryView view,
  ) {
    provider.setView(view);

    // If used in a drawer, close it
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }

    // If we are not on the library screen (e.g. course detail), pop until we are.
    // This assumes LibraryScreen is the root of the navigation stack for these views.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? colorScheme.primary : Colors.grey[500],
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? colorScheme.primary : Colors.grey[500],
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary,
                child: const Text(
                  'AJ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alex Johnson',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Computer Science',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
