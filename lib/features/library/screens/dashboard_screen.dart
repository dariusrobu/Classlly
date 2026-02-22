import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/core/widgets/glass_card.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/library/screens/add_attendance_screen.dart';
import 'package:classlly/features/library/screens/course_detail_screen.dart';

import 'package:classlly/features/library/widgets/create_note_dialog.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:classlly/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: Column(
        children: [
          const DashboardHeader(),
          const SizedBox(height: 24),
          // Inline Quick Actions Row
          const _InlineQuickActions(),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1100) {
                // Large Desktop
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _PerformanceSection(),
                          SizedBox(height: 24),
                          ScheduleCard(),
                          SizedBox(height: 24),
                          _TasksForToday(),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          CalendarCard(),
                          SizedBox(height: 24),
                          RecentNotesCard(),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (constraints.maxWidth > 700) {
                // Tablet / Small Desktop
                return const Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _PerformanceSection()),
                        SizedBox(width: 24),
                        Expanded(child: CalendarCard()),
                      ],
                    ),
                    SizedBox(height: 24),
                    ScheduleCard(),
                    SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TasksForToday()),
                        SizedBox(width: 24),
                        Expanded(child: RecentNotesCard()),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile
                return const Column(
                  children: [
                    _PerformanceSection(),
                    SizedBox(height: 24),
                    ScheduleCard(),
                    SizedBox(height: 24),
                    CalendarCard(),
                    SizedBox(height: 24),
                    _TasksForToday(),
                    SizedBox(height: 24),
                    RecentNotesCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Inline Quick Actions Row ──────────────────────────────────────────────
class _InlineQuickActions extends StatelessWidget {
  const _InlineQuickActions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final spacing = isSmall ? 6.0 : 10.0;

        return Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.check_circle_outline,
                label: AppLocalizations.of(context)!.addTask,
                color: Theme.of(context).colorScheme.primary,
                isSmall: isSmall,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddTaskScreen(),
                ),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: QuickActionButton(
                icon: Icons.grade_outlined,
                label: AppLocalizations.of(context)!.addGrade,
                color: Colors.amber.shade700,
                isSmall: isSmall,
                onTap: () async {
                  final provider = Provider.of<CourseProvider>(
                    context,
                    listen: false,
                  );
                  final courses = provider.courses;
                  if (courses.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.addCourseFirst,
                        ),
                      ),
                    );
                    return;
                  }
                  String? selectedCourseId;
                  if (courses.length == 1) {
                    selectedCourseId = courses.first.id;
                  } else {
                    selectedCourseId = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text(AppLocalizations.of(context)!.selectCourse),
                        children: courses
                            .map(
                              (c) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, c.id),
                                child: Text(c.title),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }
                  if (selectedCourseId != null && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AddGradeDialog(courseId: selectedCourseId!),
                    );
                  }
                },
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: QuickActionButton(
                icon: Icons.how_to_reg_outlined,
                label: AppLocalizations.of(context)!.attendance,
                color: Colors.green,
                isSmall: isSmall,
                onTap: () async {
                  final provider = Provider.of<CourseProvider>(
                    context,
                    listen: false,
                  );
                  final courses = provider.courses;
                  if (courses.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.addCourseFirst,
                        ),
                      ),
                    );
                    return;
                  }
                  String? selectedCourseId;
                  if (courses.length == 1) {
                    selectedCourseId = courses.first.id;
                  } else {
                    selectedCourseId = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text(AppLocalizations.of(context)!.selectCourse),
                        children: courses
                            .map(
                              (c) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, c.id),
                                child: Text(c.title),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }
                  if (selectedCourseId != null && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AddAttendanceScreen(
                        initialCourseId: selectedCourseId,
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: QuickActionButton(
                icon: Icons.note_add_outlined,
                label: AppLocalizations.of(context)!.addNote,
                color: Colors.purple,
                isSmall: isSmall,
                onTap: () async {
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
          ],
        );
      },
    );
  }
}

// ─── Reusable Quick Action Button ──────────────────────────────────────────
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isSmall ? 20 : 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 10 : 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Header ──────────────────────────────────────────────────────
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final profile = provider.studentProfile;
    final name = profile.name ?? 'Student';
    final weekInfo = calendarProvider.getWeekInfo(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.welcomeBack(name),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 350
                      ? 20
                      : (MediaQuery.of(context).size.width < 600 ? 24 : 32),
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Your academic journey is looking bright today.',
                style: TextStyle(
                  color: isDark ? const Color(0xFFA1A1AA) : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              MediaQuery.of(context).size.width < 500
                  ? DateFormat('MMM d, yyyy').format(DateTime.now())
                  : DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFA1A1AA)
                    : const Color(0xFF0F172A),
              ),
            ),
            if (weekInfo != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      weekInfo['week'] != null
                          ? 'WEEK ${weekInfo['week']} • ${weekInfo['label'].toUpperCase()}'
                          : weekInfo['label'].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Performance Section (Two Gauges) ──────────────────────────────────────
class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection();

  double _calculateAttendance(List<Course> courses) {
    if (courses.isEmpty) return 0.0;
    double total = 0.0;
    for (var c in courses) {
      total += c.cachedAttendanceRate;
    }
    return total / courses.length;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.performanceOverview,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'This Semester',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Consumer<CourseProvider>(
            builder: (context, courseProvider, _) {
              final attendanceRate = _calculateAttendance(
                courseProvider.courses,
              );

              return Consumer<TaskProvider>(
                builder: (context, taskProvider, _) {
                  final tasks = taskProvider.tasks;
                  final completed = tasks.where((t) => t.isCompleted).length;
                  final taskRate = tasks.isNotEmpty
                      ? (completed / tasks.length) * 100
                      : 0.0;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final gaugeSize = math.min(
                        constraints.maxWidth / 2.5,
                        160.0,
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _DonutGauge(
                            size: gaugeSize,
                            percentage: attendanceRate,
                            label: 'ATTENDANCE',
                            color: Theme.of(context).colorScheme.primary,
                            subtitle:
                                'You missed only ${(100 - attendanceRate).toInt() > 0 ? ((100 - attendanceRate) * courseProvider.courses.length / 100).ceil() : 0} classes',
                          ),
                          _DonutGauge(
                            size: gaugeSize,
                            percentage: taskRate,
                            label: 'TASK SUCCESS',
                            color: Theme.of(context).colorScheme.primary,
                            subtitle:
                                '$completed/${tasks.length} Tasks completed',
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Single Donut Gauge Widget ─────────────────────────────────────────────
class _DonutGauge extends StatelessWidget {
  final double size;
  final double percentage;
  final String label;
  final Color color;
  final String subtitle;

  const _DonutGauge({
    required this.size,
    required this.percentage,
    required this.label,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(
              percentage: percentage / 100,
              color: color,
              bgColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              strokeWidth: size * 0.08,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: size * 0.065,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFA1A1AA)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: size + 20,
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFA1A1AA)
                  : Colors.grey,
            ),
            textAlign: TextAlign.center,
            child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _DonutPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percentage;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      percentage != oldDelegate.percentage || color != oldDelegate.color;
}

// ─── Schedule Card (with colored left borders) ─────────────────────────────
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final weekInfo = calendarProvider.getWeekInfo(now);

    final todaysLectures = <Course>[];
    if (weekInfo != null) {
      for (var course in courseProvider.courses) {
        if (course.courseDay == dayName) {
          bool show =
              course.courseFrequency == 'Weekly' ||
              (course.courseFrequency == 'Bi-Weekly (odd)' &&
                  weekInfo['isOdd']) ||
              (course.courseFrequency == 'Bi-Weekly (even)' &&
                  !weekInfo['isOdd']);
          if (show) {
            todaysLectures.add(course);
          }
        }
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.todaysSchedule,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<LibraryProvider>(
                    context,
                    listen: false,
                  ).setView(LibraryView.calendar);
                },
                child: Text(
                  AppLocalizations.of(context)!.viewCalendar,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (todaysLectures.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noLecturesToday,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.relaxOrStudy,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFA1A1AA)
                          : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: todaysLectures.map((course) {
                final courseColor = Color(course.color);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.08),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Colored left border bar
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: courseColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: courseColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                color: courseColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              course.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${course.location.isNotEmpty ? '${course.location} · ' : ''}${course.courseTime}',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFA1A1AA)
                                    : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              course.courseTime,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFA1A1AA)
                                    : Colors.grey[500],
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CourseDetailScreen(course: course),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Tasks for Today (2-column grid) ───────────────────────────────────────
class _TasksForToday extends StatelessWidget {
  const _TasksForToday();

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks for Today',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<LibraryProvider>(
                    context,
                    listen: false,
                  ).setView(LibraryView.tasks);
                },
                child: Text(
                  'View All Tasks',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: Hive.box<Task>(
              NotesRepository.taskBoxName,
            ).listenable(),
            builder: (context, Box<Task> box, _) {
              final allTasks = box.values
                  .where((t) => !t.isDeleted && !t.isCompleted)
                  .toList();
              allTasks.sort((a, b) => b.priority.compareTo(a.priority));
              final displayTasks = allTasks.take(4).toList();

              if (displayTasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'All caught up! 🎉',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFA1A1AA)
                            : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 500
                      ? 1
                      : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 16,
                  childAspectRatio: MediaQuery.of(context).size.width < 500
                      ? 6.5
                      : 4.5,
                ),
                itemCount: displayTasks.length,
                itemBuilder: (context, index) {
                  final task = displayTasks[index];
                  return GestureDetector(
                    onTap: () => taskProvider.toggleTask(task),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Recent Notes Card ─────────────────────────────────────────────────────
class RecentNotesCard extends StatelessWidget {
  const RecentNotesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentNotes,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<LibraryProvider>(
                    context,
                    listen: false,
                  ).setView(LibraryView.allNotes);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: Hive.box<Note>(
              NotesRepository.boxName,
            ).listenable(),
            builder: (context, Box<Note> box, _) {
              final notes = box.values.where((n) => !n.isDeleted).toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              final recent = notes.take(2).toList();
              if (recent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noNotesYet,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: recent
                    .map(
                      (note) => GestureDetector(
                        onTap: () => LibraryScreen.openNote(context, note),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title.isNotEmpty
                                          ? note.title
                                          : AppLocalizations.of(
                                              context,
                                            )!.untitled,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.noteMetadata(
                                        DateFormat.Md().format(note.updatedAt),
                                        note.strokes.length,
                                      ),
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFFA1A1AA)
                                            : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Card (Compact Mini-Calendar) ─────────────────────────────────
class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key});

  List<dynamic> _getEventsForDay(
    DateTime day,
    AcademicCalendarProvider calendarProvider,
    List<Task> tasks,
  ) {
    final events = <dynamic>[];
    for (var event in calendarProvider.events) {
      if (isSameDay(event.date, day)) {
        events.add(event);
      }
    }
    for (var period in calendarProvider.periods) {
      if ((day.isAtSameMomentAs(period.startDate) ||
              day.isAfter(period.startDate)) &&
          (day.isAtSameMomentAs(period.endDate) ||
              day.isBefore(period.endDate))) {
        if (period.type != AcademicPeriodType.teaching) {
          events.add(period);
        }
      }
    }
    for (var task in tasks) {
      if (task.dueDate != null && isSameDay(task.dueDate!, day)) {
        events.add(task);
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            rowHeight: 36,
            eventLoader: (day) =>
                _getEventsForDay(day, calendarProvider, taskProvider.tasks),
            headerVisible: false,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              markersMaxCount: 0,
              defaultTextStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13,
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13,
              ),
              outsideTextStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              cellMargin: const EdgeInsets.all(2),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              weekendStyle: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kept for backwards compatibility with tests ───────────────────────────

// StatsGrid kept as thin alias for backwards compat
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PerformanceSection();
  }
}

// TasksCard kept for backwards compat
class TasksCard extends StatelessWidget {
  const TasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TasksForToday();
  }
}
