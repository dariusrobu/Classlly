import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/library/screens/add_attendance_screen.dart';
import 'package:classlly/features/library/screens/course_detail_screen.dart';
import 'package:classlly/features/library/widgets/create_note_dialog.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Safety check for Hive boxes
    if (!Hive.isBoxOpen(NotesRepository.gradeBoxName) ||
        !Hive.isBoxOpen(NotesRepository.taskBoxName)) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: Column(
        children: [
          const DashboardHeader(),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: math.max(
                    (MediaQuery.of(context).size.width - 64) / 4,
                    80,
                  ),
                  child: QuickActionButton(
                    icon: Icons.check_circle_outline,
                    label: AppLocalizations.of(context)!.tasks,
                    color: Colors.blue,
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => const AddTaskScreen(),
                    ),
                  ),
                ),
                SizedBox(
                  width: math.max(
                    (MediaQuery.of(context).size.width - 64) / 4,
                    80,
                  ),
                  child: QuickActionButton(
                    icon: Icons.calendar_today_outlined,
                    label: AppLocalizations.of(context)!.attendance,
                    color: Colors.orange,
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => const AddAttendanceScreen(),
                    ),
                  ),
                ),
                SizedBox(
                  width: math.max(
                    (MediaQuery.of(context).size.width - 64) / 4,
                    80,
                  ),
                  child: QuickActionButton(
                    icon: Icons.note_add_outlined,
                    label: AppLocalizations.of(context)!.notes,
                    color: Colors.purple,
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
                SizedBox(
                  width: math.max(
                    (MediaQuery.of(context).size.width - 64) / 4,
                    80,
                  ),
                  child: QuickActionButton(
                    icon: Icons.grade_outlined,
                    label: AppLocalizations.of(context)!.addGrade,
                    color: Colors.green,
                    onTap: () async {
                      final provider = Provider.of<CourseProvider>(
                        context,
                        listen: false,
                      );
                      final courses = provider.courses;
                      if (courses.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add a course first to log grades'),
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
                            title: const Text('Select Course'),
                            children: courses
                                .map(
                                  (c) => SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, c.id),
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
              ],
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

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final profile = provider.studentProfile;
    final name = profile.name ?? 'Student';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.welcomeBack(name),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
              ],
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Consumer<CourseProvider>(
              builder: (context, courseProvider, _) {
                final courses = courseProvider.courses;
                double totalGradeAvg = 0.0;
                double totalAttRate = 0.0;

                if (courses.isNotEmpty) {
                  for (var c in courses) {
                    totalGradeAvg += c.cachedAverageGrade;
                    totalAttRate += c.cachedAttendanceRate;
                  }
                  totalGradeAvg /= courses.length;
                  totalAttRate /= courses.length;
                }

                return Consumer<TaskProvider>(
                  builder: (context, taskProvider, _) {
                    final tasks = taskProvider.tasks;
                    final completed = tasks.where((t) => t.isCompleted).length;
                    double taskRate = tasks.isNotEmpty
                        ? (completed / tasks.length) * 100
                        : 0.0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.min(constraints.maxWidth, 240.0);
                        return Center(
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: CustomPaint(
                              painter: PerformanceRingPainter(
                                attendanceParams: _RingParams(
                                  percentage: totalAttRate / 100,
                                  color: Theme.of(context).colorScheme.primary,
                                  isDashed: totalAttRate < 75,
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
                                      NumberFormat('0.##').format(totalGradeAvg),
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
                label: 'Attendance',
                strokeWidth: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 24),
              _LegendItem(
                label: 'Tasks',
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

class PerformanceRingPainter extends CustomPainter {
  final _RingParams attendanceParams;
  final _RingParams taskParams;
  final Color backgroundColor;

  PerformanceRingPainter({
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
  bool shouldRepaint(PerformanceRingPainter oldDelegate) => true;
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

    final todaysLectures = <String>[];
    if (weekInfo != null) {
      for (var course in courseProvider.courses) {
        if (course.courseDay == dayName) {
          bool show = course.courseFrequency == 'Weekly' ||
              (course.courseFrequency == 'Bi-Weekly (odd)' &&
                  weekInfo['isOdd']) ||
              (course.courseFrequency == 'Bi-Weekly (even)' &&
                  !weekInfo['isOdd']);
          if (show) {
            todaysLectures.add(course.title);
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
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
                    "Today's Schedule",
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
                  'View Full',
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
                          'No lectures today',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Time to relax or catch up on study!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    )
                  : Column(
                      children: todaysLectures
                          .map((l) => ListTile(
                                leading: const Icon(Icons.school_outlined),
                                title: Text(l),
                              ))
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notes',
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
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No notes yet',
                      style: TextStyle(color: Colors.grey),
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
                                        : 'Untitled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat.Md().format(note.updatedAt)} • ${note.strokes.length} strokes',
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
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
                    'Tasks',
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
                        '${completionRate.toInt()}% Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
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
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount Pending',
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
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'All caught up!',
                      style: TextStyle(color: Colors.grey),
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
                'Add Task',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
