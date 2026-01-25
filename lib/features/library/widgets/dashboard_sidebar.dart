import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/auth/screens/profile_screen.dart';
import 'package:classlly/features/library/screens/settings_screen.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      color: isDark ? AppTheme.sidebarDark : Theme.of(context).cardColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Classlly',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SidebarItem(
                      icon: Icons.dashboard,
                      label: AppLocalizations.of(context)!.dashboard,
                      isActive:
                          libraryProvider.currentView == LibraryView.dashboard,
                      onTap: () => _navigate(
                        context,
                        libraryProvider,
                        LibraryView.dashboard,
                      ),
                    ),
                    SidebarItem(
                      icon: Icons.description,
                      label: AppLocalizations.of(context)!.notes,
                      isActive:
                          libraryProvider.currentView == LibraryView.allNotes,
                      onTap: () => _navigate(
                        context,
                        libraryProvider,
                        LibraryView.allNotes,
                      ),
                    ),
                    SidebarItem(
                      icon: Icons.book,
                      label: AppLocalizations.of(context)!.courses,
                      isActive:
                          libraryProvider.currentView == LibraryView.courses,
                      onTap: () => _navigate(
                        context,
                        libraryProvider,
                        LibraryView.courses,
                      ),
                    ),
                    SidebarItem(
                      icon: Icons.check_circle,
                      label: AppLocalizations.of(context)!.tasks,
                      isActive:
                          libraryProvider.currentView == LibraryView.tasks,
                      onTap: () => _navigate(
                        context,
                        libraryProvider,
                        LibraryView.tasks,
                      ),
                    ),
                    SidebarItem(
                      icon: Icons.calendar_today,
                      label: AppLocalizations.of(context)!.calendar,
                      isActive:
                          libraryProvider.currentView == LibraryView.calendar,
                      onTap: () => _navigate(
                        context,
                        libraryProvider,
                        LibraryView.calendar,
                      ),
                    ),
                    SidebarItem(
                      icon: Icons.folder,
                      label: AppLocalizations.of(context)!.archive,
                      isActive:
                          libraryProvider.currentView == LibraryView.archive,
                      onTap: () => _navigate(
                        context,
                        libraryProvider,
                        LibraryView.archive,
                      ),
                    ),
                    SidebarItem(
                      icon: Icons.settings,
                      label: AppLocalizations.of(context)!.settings,
                      isActive: false,
                      onTap: () {
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                          Navigator.pop(context);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.all(16), child: UserCard()),
          ],
        ),
      ),
    );
  }

  void _navigate(
    BuildContext context,
    LibraryProvider provider,
    LibraryView view,
  ) {
    provider.setView(view);
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
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
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isActive
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.grey[500],
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isActive ? Colors.white : Colors.grey[500],
                  ),
                ),
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
    final provider = Provider.of<ProfileProvider>(context);
    final profile = provider.studentProfile;
    final name = profile.name ?? 'Alex';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  initials +
                      (name.split(' ').length > 1
                          ? name.split(' ')[1][0].toUpperCase()
                          : ''),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    profile.major.isNotEmpty ? profile.major : 'Student',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
