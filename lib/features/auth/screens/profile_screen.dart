import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/repositories/auth_repository.dart';
import 'package:classlly/features/auth/screens/auth_screen.dart';
import 'package:classlly/features/library/screens/settings_screen.dart';
import 'package:classlly/features/auth/screens/personal_info_screen.dart';
import 'package:classlly/features/auth/screens/academic_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<StudentProfile>(
          NotesRepository.profileBoxName,
        ).listenable(),
        builder: (context, box, _) {
          final repo = NotesRepository();
          final profile = repo.getStudentProfile();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildProfileHeader(
                  context,
                  isDark,
                  colorScheme,
                  user,
                  profile,
                ),
                const SizedBox(height: 32),
                _buildStatsRow(context, isDark, profile),
                const SizedBox(height: 32),
                _buildMenuSection(
                  context,
                  AppLocalizations.of(context)!.account,
                  [
                    _MenuItem(
                      icon: Icons.person_outline,
                      label: AppLocalizations.of(context)!.personalInfo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalInfoScreen(),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.school_outlined,
                      label: AppLocalizations.of(context)!.academicDetails,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AcademicDetailsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.logOut,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.deleteAccount,
                        ),
                        content: Text(
                          AppLocalizations.of(context)!.deleteAccountConfirm,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () async {
                              // 1. Delete data from Supabase and Sign out
                              final authRepo = AuthRepository();
                              await authRepo.deleteAccount();

                              // 2. Clear all local Hive boxes
                              await Hive.deleteFromDisk();

                              // 3. Re-init Hive boxes so they are ready for next user
                              await NotesRepository.openBoxes();

                              // 4. Navigate back to Auth Screen
                              if (context.mounted) {
                                Navigator.pop(context); // Close dialog
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const AuthScreen(),
                                  ),
                                  (route) => false,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Account deactivated and local data cleared.',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.deleteForever,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.deleteAccount,
                    style: TextStyle(
                      color: Colors.red.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    User? user,
    StudentProfile profile,
  ) {
    final name = profile.name ?? user?.userMetadata?['full_name'] ?? 'Alex';
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  initials.isNotEmpty ? initials : '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.edit, size: 14, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${profile.major} • ${profile.year}',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        Text(
          profile.university,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    bool isDark,
    StudentProfile profile,
  ) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, noteBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Course>(
            NotesRepository.courseBoxName,
          ).listenable(),
          builder: (context, courseBox, _) {
            return ValueListenableBuilder(
              valueListenable: Hive.box<Task>(
                NotesRepository.taskBoxName,
              ).listenable(),
              builder: (context, taskBox, _) {
                final repo = NotesRepository();
                final notesCount = repo.getAllNotes().length;
                final coursesCount = repo.getAllCourses().length;

                final studyHours = (profile.totalStudyTimeSeconds / 3600)
                    .toStringAsFixed(1);

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem(
                          coursesCount.toString(),
                          AppLocalizations.of(context)!.courses,
                        ),
                        _statItem(
                          notesCount.toString(),
                          AppLocalizations.of(context)!.notes,
                        ),
                        Consumer<CourseProvider>(
                          builder: (context, cp, _) => _statItem(
                            cp.totalAverageGrade.toStringAsFixed(1),
                            'AVG',
                          ),
                        ),
                        _statItem(
                          studyHours,
                          AppLocalizations.of(context)!.studyHrs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<CourseProvider>(
                      builder: (context, cp, _) => Text(
                        '${cp.totalCreditsEarned.toStringAsFixed(1)} ${AppLocalizations.of(context)!.credits}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<_MenuItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: items
                .map((item) => _buildMenuItemTile(context, item))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemTile(BuildContext context, _MenuItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(item.icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        item.label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: item.onTap,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  _MenuItem({required this.icon, required this.label, this.onTap});
}
