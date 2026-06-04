import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/auth/screens/profile_screen.dart';
import 'package:classlly/features/library/screens/settings_screen.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/l10n/app_localizations.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    // Sidebar with glassmorphism effect
    Widget sidebarContent = Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.sidebarDark.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.6),
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Logo & Brand
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classlly',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'STUDENT PORTAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: isDark
                              ? const Color(0xFFA1A1AA)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    const SizedBox(height: 8),
                    Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    const SizedBox(height: 8),
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
            // User Card at bottom
            const Padding(padding: EdgeInsets.all(16), child: UserCard()),
          ],
        ),
      ),
    );

    // Wrap with backdrop blur for glassmorphism (skip on web)
    if (kIsWeb) {
      return sidebarContent;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: sidebarContent,
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
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isActive
                ? BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
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
                  color: isActive
                      ? Colors.white
                      : (isDark ? const Color(0xFFA1A1AA) : Colors.grey[500]),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                    color: isActive
                        ? Colors.white
                        : (isDark ? const Color(0xFFA1A1AA) : Colors.grey[500]),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
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
                ).colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
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
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    profile.major.isNotEmpty ? profile.major : 'Student',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFA1A1AA)
                          : Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.settings_outlined,
              size: 16,
              color: isDark ? const Color(0xFFA1A1AA) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
