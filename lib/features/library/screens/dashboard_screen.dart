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
import 'package:classlly/features/library/screens/add_course_screen.dart';
import 'package:classlly/features/library/widgets/create_note_dialog.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:classlly/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width < 400 ? 1 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio:
                    MediaQuery.of(context).size.width < 400 ? 3.0 : 1.5,
                children: [
                  _QuickActionTile(
                    icon: Icons.note_add_outlined,
                    label: AppLocalizations.of(context)!.addNote,
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      final note = await showDialog<Note>(
                        context: context,
                        builder: (context) => const CreateNoteDialog(),
                      );
                      if (note != null && context.mounted) {
                        LibraryScreen.openNote(context, note);
                      }
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.check_circle_outline,
                    label: AppLocalizations.of(context)!.addTask,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const AddTaskScreen(),
                      );
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.calendar_today_outlined,
                    label: AppLocalizations.of(context)!.attendance,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const AddAttendanceScreen(),
                      );
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.grade_outlined,
                    label: AppLocalizations.of(context)!.addGrade,
                    color: Colors.green,
                    onTap: () async {
                      Navigator.pop(context);
                      final provider = Provider.of<CourseProvider>(
                        context,
                        listen: false,
                      );
                      final courses = provider.courses;
                      if (courses.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(AppLocalizations.of(context)!.addCourseFirst),
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
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for Hive boxes
    if (!Hive.isBoxOpen(NotesRepository.gradeBoxName) ||
        !Hive.isBoxOpen(NotesRepository.taskBoxName) ||
        !Hive.isBoxOpen(NotesRepository.boxName) ||
        !Hive.isBoxOpen(NotesRepository.courseBoxName)) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: Column(
        children: [
          const DashboardHeader(),
          const SizedBox(height: 24),
          // Quick Actions Button
          GestureDetector(
            onTap: () => _showQuickActions(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                          StatsGrid(),
                          SizedBox(height: 24),
                          ScheduleCard(),
                          SizedBox(height: 24),
                          RecentNotesCard(),
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
                          TasksCard(),
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
                        Expanded(child: StatsGrid()),
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
                        Expanded(child: RecentNotesCard()),
                        SizedBox(width: 24),
                        Expanded(child: TasksCard()),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile
                return const Column(
                  children: [
                    StatsGrid(),
                    SizedBox(height: 24),
                    ScheduleCard(),
                    SizedBox(height: 24),
                    RecentNotesCard(),
                    SizedBox(height: 24),
                    CalendarCard(),
                    SizedBox(height: 24),
                    TasksCard(),
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

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final profile = provider.studentProfile;
    final name = profile.name ?? 'Student';
    final weekInfo = calendarProvider.getWeekInfo(DateTime.now());

    return Row(
      children: [
        if (MediaQuery.of(context).size.width <= 1000)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (weekInfo != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'WEEK ${weekInfo['week']} • ${weekInfo['label'].toUpperCase()}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.welcomeBack(name),
                style: TextStyle(
                  fontSize:
                      MediaQuery.of(context).size.width < 600 ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const PerformanceRing();
  }
}

class PerformanceRing extends StatelessWidget {
  const PerformanceRing({super.key});

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
      padding: const EdgeInsets.all(32),
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.performanceOverview,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Consumer<CourseProvider>(
              builder: (context, courseProvider, _) {
                // Stats are now handled by provider and helper method

                return Consumer<TaskProvider>(
                  builder: (context, taskProvider, _) {
                    final tasks = taskProvider.tasks;
                    final completed = tasks.where((t) => t.isCompleted).length;
                    double taskRate = tasks.isNotEmpty
                        ? (completed / tasks.length) * 100
                        : 0.0;
                    
                    final averageGrade = courseProvider.totalAverageGrade;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.min(constraints.maxWidth, 240.0);
                        return Center(
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: CustomPaint(
                              painter: _PerformanceRingPainter(
                                attendanceParams: _RingParams(
                                  // Use actual total attendance rate if available in provider, or recalculate
                                  // For now, let's look at how we got totalAttRate before.
                                  // We should probably expose totalAttendanceRate from provider too, but let's stick to what we have locally or add getter.
                                  // Wait, I replaced the local calc loop. I need to get attendance too.
                                  // Let's add totalAttendanceRate to provider or recalculate it briefly here since I removed the loop?
                                  // Actually, I should probably use `courseProvider.totalAverageGrade` but I still need attendance.
                                  // Let me verify if I removed the loop in my Plan. 
                                  // The User's previous code had a loop calculating BOTH.
                                  // My ReplacementContent replaces the INNER Consumer logic but I need to make sure I have access to stats.
                                  // I will use getters from Provider if available. I added totalAverageGrade. 
                                  // I did NOT add totalAttendanceRate to provider yet.
                                  // I should probably assume I can add it or just loop here. 
                                  // Ideally I should utilize the Provider.
                                  // Let's use the provider's courses list to calc attendance here for now to be safe, or add another getter.
                                  // Adding getter is cleaner.
                                  percentage: _calculateAttendance(courseProvider.courses) / 100,
                                  color: Theme.of(context).colorScheme.primary,
                                  isDashed: _calculateAttendance(courseProvider.courses) < 75,
                                  strokeWidth: size * 0.06,
                                ),
                                taskParams: _RingParams(
                                  percentage: taskRate / 100,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.6),
                                  isDashed: taskRate < 75,
                                  strokeWidth: size * 0.025,
                                ),
                                backgroundColor: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      NumberFormat('0.0').format(averageGrade),
                                      style: TextStyle(
                                        fontSize: size * 0.25,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: size * 0.05,
                                        left: 2,
                                      ),
                                      child: Text(
                                        '+',
                                        style: TextStyle(
                                          fontSize: size * 0.08,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color
                                              ?.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                label: AppLocalizations.of(context)!.attendance,
                strokeWidth: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 24),
              _LegendItem(
                label: AppLocalizations.of(context)!.tasks,
                strokeWidth: 6,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final double strokeWidth;
  final Color color;
  const _LegendItem({
    required this.label,
    required this.strokeWidth,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: strokeWidth,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _RingParams {
  final double percentage;
  final Color color;
  final bool isDashed;
  final double strokeWidth;

  _RingParams({
    required this.percentage,
    required this.color,
    required this.isDashed,
    required this.strokeWidth,
  });
}

class _PerformanceRingPainter extends CustomPainter {
  final _RingParams attendanceParams;
  final _RingParams taskParams;
  final Color backgroundColor;

  _PerformanceRingPainter({
    required this.attendanceParams,
    required this.taskParams,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusOuter = (size.width / 2) - (attendanceParams.strokeWidth / 2);
    final radiusInner = radiusOuter - 24;

    _drawRing(canvas, center, radiusOuter, attendanceParams);
    _drawRing(canvas, center, radiusInner, taskParams);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    _RingParams params,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * params.percentage;

    // 1. Background Track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = params.strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Progress
    final progressPaint = Paint()
      ..color = params.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = params.strokeWidth
      ..strokeCap = StrokeCap.round;

    if (params.isDashed) {
      final path = Path()..addArc(rect, startAngle, sweepAngle);
      final dashedPath = _dashPath(path, 6, 6);
      canvas.drawPath(dashedPath, progressPaint);
    } else {
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  Path _dashPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashSpace;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_PerformanceRingPainter oldDelegate) => true;
}

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
          bool show = course.courseFrequency == 'Weekly' ||
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
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.todaysSchedule,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<LibraryProvider>(context, listen: false)
                      .setView(LibraryView.calendar);
                },
                child: Text(
                  AppLocalizations.of(context)!.viewCalendar,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: todaysLectures.isEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey,
                        ),
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
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCourseScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(AppLocalizations.of(context)!.createCourse),
                        ),
                      ],
                    )
                  : Column(
                      children: todaysLectures
                          .map(
                            (course) => ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(course.color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.school_outlined,
                                  color: Color(course.color),
                                ),
                              ),
                              title: Text(
                                course.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${course.location.isNotEmpty ? '${course.location} • ' : ''}${course.courseTime}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourseDetailScreen(course: course),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.grey,
                  size: 16,
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
                      (note) => Container(
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
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2),
                                ),
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
                                        : AppLocalizations.of(context)!.untitled,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.noteMetadata(
                                      DateFormat.Md().format(note.updatedAt),
                                      note.strokes.length,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        eventLoader: (day) =>
            _getEventsForDay(day, calendarProvider, taskProvider.tasks),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.grey),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: const TextStyle(color: Colors.grey),
          weekendTextStyle: const TextStyle(color: Colors.grey),
          outsideTextStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class TasksCard extends StatelessWidget {
  const TasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.tasks,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: Hive.box<Task>(
                                  NotesRepository.taskBoxName,
                                ).listenable(),
                                builder: (context, Box<Task> box, _) {
                                  final tasks = box.values
                                      .where((t) => !t.isDeleted)
                                      .toList();
                                  final completed = tasks
                                      .where((t) => t.isCompleted)
                                      .length;
                                  final completionRate = tasks.isNotEmpty
                                      ? (completed / tasks.length) * 100
                                      : 0.0;
                                  return Text(
                                    AppLocalizations.of(context)!
                                        .percentCompleted(completionRate.toInt()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],              ),
              ValueListenableBuilder(
                valueListenable: Hive.box<Task>(
                  NotesRepository.taskBoxName,
                ).listenable(),
                builder: (context, Box<Task> box, _) {
                  final pendingCount = box.values
                      .where((t) => !t.isCompleted && !t.isDeleted)
                      .length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                      // width constraint?
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.pendingCount(pendingCount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder(
            valueListenable: Hive.box<Task>(
              NotesRepository.taskBoxName,
            ).listenable(),
            builder: (context, Box<Task> box, _) {
              final tasks = box.values
                  .where((t) => !t.isDeleted && !t.isCompleted)
                  .toList();
              tasks.sort((a, b) => b.priority.compareTo(a.priority));
              final displayTasks = tasks.take(4).toList();
              if (displayTasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      AppLocalizations.of(context)!.allCaughtUp,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: displayTasks
                    .map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => provider.toggleTask(task),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: task.priority == 2
                                        ? Colors.redAccent
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: task.isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (task.dueDate != null)
                                      Text(
                                        DateFormat.MMMd().format(task.dueDate!),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: task.priority == 2
                                              ? Colors.redAccent
                                              : Colors.grey,
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
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddTaskScreen(),
                );
              },
                          child: Text(
                            AppLocalizations.of(context)!.addTask,
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
