import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/library/widgets/empty_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<dynamic> _getEventsForDay(
    DateTime day,
    AcademicCalendarProvider calendarProvider,
    List<Task> tasks,
    List<Course> courses,
  ) {
    final events = <dynamic>[];

    // 1. Add Academic Events (Holidays, etc.)
    for (var event in calendarProvider.events) {
      if (isSameDay(event.date, day)) {
        events.add(event);
      }
    }

    // 3. Add Tasks
    for (var task in tasks) {
      if (task.dueDate != null && isSameDay(task.dueDate!, day)) {
        events.add(task);
      }
    }

    // 3. Add Course Sessions (Lectures/Seminars)
    final dayName = DateFormat('EEEE').format(day);
    final weekInfo = calendarProvider.getWeekInfo(day);

    if (weekInfo != null) {
      for (var course in courses) {
        // Lecture
        if (course.courseDay == dayName) {
          bool show = false;
          if (course.courseFrequency == 'Weekly') {
            show = true;
          } else {
            if (course.courseFrequency == 'Bi-Weekly (odd)' &&
                weekInfo['isOdd']) {
              show = true;
            } else if (course.courseFrequency == 'Bi-Weekly (even)' &&
                !weekInfo['isOdd']) {
              show = true;
            }
          }
          if (show) events.add({'type': 'lecture', 'course': course});
        }

        // Seminar
        if (course.seminarDay == dayName) {
          bool show = false;
          if (course.seminarFrequency == 'Weekly') {
            show = true;
          } else {
            if (course.seminarFrequency == 'Bi-Weekly (odd)' &&
                weekInfo['isOdd']) {
              show = true;
            } else if (course.seminarFrequency == 'Bi-Weekly (even)' &&
                !weekInfo['isOdd']) {
              show = true;
            }
          }
          if (show) events.add({'type': 'seminar', 'course': course});
        }
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final borderMuted = Theme.of(context).dividerColor.withValues(alpha: 0.5);
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final weekInfo = calendarProvider.getWeekInfo(_selectedDay);

    return Container(
      color: scaffoldBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCalendarHeader(
            context,
            weekInfo,
            primary,
            textColor,
            subTextColor,
            cardBg,
            borderMuted,
          ),

          // Calendar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderMuted),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => _getEventsForDay(
                    day,
                    calendarProvider,
                    taskProvider.tasks,
                    courseProvider.courses,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  availableGestures: AvailableGestures.all,
                  headerVisible: false,
                  daysOfWeekHeight: 50,
                  rowHeight:
                      100, // Increased row height for even better visibility
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    tableBorder: TableBorder.all(
                      color: borderMuted,
                      width: 0.5,
                    ),
                    defaultTextStyle: TextStyle(color: subTextColor),
                    weekendTextStyle: TextStyle(color: subTextColor),
                    outsideTextStyle: TextStyle(
                      color: subTextColor.withValues(alpha: 0.5),
                    ),
                    todayDecoration: const BoxDecoration(),
                    todayTextStyle: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: const BoxDecoration(),
                    selectedTextStyle: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    markerDecoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderMuted)),
                    ),
                    weekdayStyle: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    weekendStyle: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildCell(
                        day,
                        Colors.transparent,
                        false,
                        textColor,
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildCell(day, primary, true, Colors.white);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return _buildCell(
                        day,
                        Colors.black26,
                        false,
                        subTextColor.withValues(alpha: 0.5),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      return _buildMarkers(day, events);
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Daily Agenda
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                            AppLocalizations.of(context)!.dailyAgenda,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMM d').format(_selectedDay),
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'add') {
                            showDialog(
                              context: context,
                              builder: (context) => const AddTaskScreen(),
                            );
                          } else if (value == 'clear') {
                            final box = Hive.box<Task>(
                              NotesRepository.taskBoxName,
                            );
                            final today = DateTime.now();
                            final completedToday = box.values
                                .where(
                                  (t) =>
                                      !t.isDeleted &&
                                      t.isCompleted &&
                                      t.dueDate != null &&
                                      t.dueDate!.year == today.year &&
                                      t.dueDate!.month == today.month &&
                                      t.dueDate!.day == today.day,
                                )
                                .toList();
                            for (var task in completedToday) {
                              taskProvider.deleteTask(task.id);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'add',
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.addTask),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'clear',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_sweep, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.clearCompleted),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_horiz,
                          color: subTextColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildAgendaTimeline(
                      context,
                      _selectedDay,
                      weekInfo,
                      primary,
                      borderMuted,
                      cardBg,
                      scaffoldBg,
                      textColor,
                      subTextColor,
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

  Widget _buildCalendarHeader(
    BuildContext context,
    Map<String, dynamic>? weekInfo,
    Color primary,
    Color textColor,
    Color subTextColor,
    Color cardBg,
    Color borderMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
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
                    DateFormat('MMMM yyyy').format(_focusedDay),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekInfo != null
                        ? '${AppLocalizations.of(context)!.week} ${weekInfo['week']} (${weekInfo['label']} ${AppLocalizations.of(context)!.week}) • ${weekInfo['periodName']}'
                        : AppLocalizations.of(context)!.academicScheduleDesc,
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildViewToggle(cardBg, borderMuted, textColor, subTextColor),
              const SizedBox(width: 16),
              _buildNavButtons(primary, cardBg, borderMuted, subTextColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(
    Color cardBg,
    Color borderMuted,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderMuted),
      ),
      child: Row(
        children: [
          _toggleBtn(
            AppLocalizations.of(context)!.month,
            true,
            () {
              // Static month view
            },
            textColor,
            subTextColor,
            cardBg,
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(
    String label,
    bool active,
    VoidCallback onTap,
    Color textColor,
    Color subTextColor,
    Color cardBg,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF121212) : Colors.grey[200])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? textColor : subTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons(
    Color primary,
    Color cardBg,
    Color borderMuted,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderMuted),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month - 1,
                  _focusedDay.day,
                );
              });
            },
            icon: Icon(Icons.chevron_left, size: 20, color: subTextColor),
            visualDensity: VisualDensity.compact,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              child: Text(
                AppLocalizations.of(context)!.today,
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month + 1,
                  _focusedDay.day,
                );
              });
            },
            icon: Icon(Icons.chevron_right, size: 20, color: subTextColor),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    DateTime day,
    Color color,
    bool isSelected,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkers(DateTime day, List events) {
    // ... existing implementation ...
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 44, 8, 0),
      child: Column(
        children: events.take(3).map((e) {
          String title = '';
          Color markerColor = Colors.blue;

          if (e is Map) {
            final course = e['course'] as Course;
            title = course.title;
            markerColor = Color(course.color);
          } else if (e is Task) {
            title = e.title;
            markerColor = Colors.orange;
          } else if (e is AcademicEvent) {
            title = e.name;
            markerColor = e.type == AcademicEventType.holiday
                ? Colors.red
                : Colors.green;
          } else if (e is AcademicPeriod) {
            title = e.name;
            switch (e.type) {
              case AcademicPeriodType.teaching:
                markerColor = Colors.blue;
                break;
              case AcademicPeriodType.exam:
                markerColor = Colors.redAccent;
                break;
              case AcademicPeriodType.session:
                markerColor = Colors.purple;
                break;
              case AcademicPeriodType.retake:
                markerColor = Colors.deepOrange;
                break;
              case AcademicPeriodType.holiday:
                markerColor = Colors.green;
                break;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: markerColor.withValues(alpha: 0.1),
              border: Border(left: BorderSide(color: markerColor, width: 2)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: markerColor.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgendaTimeline(
    BuildContext context,
    DateTime selectedDay,
    Map<String, dynamic>? weekInfo,
    Color primary,
    Color borderMuted,
    Color cardBg,
    Color scaffoldBg,
    Color textColor,
    Color subTextColor,
  ) {
    // ... existing setup ...
    final taskProvider = Provider.of<TaskProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final courses = courseProvider.courses;

    final allItems = <_AgendaItemData>[];

    // Add Courses
    final dayName = DateFormat('EEEE').format(selectedDay);
    if (weekInfo != null) {
      for (var c in courses) {
        if (c.courseDay == dayName) {
          bool show =
              c.courseFrequency == 'Weekly' ||
              (c.courseFrequency == 'Bi-Weekly (odd)' && weekInfo['isOdd']) ||
              (c.courseFrequency == 'Bi-Weekly (even)' && !weekInfo['isOdd']);
          if (show) {
            allItems.add(
              _AgendaItemData(
                time: c.courseTime,
                title: c.title,
                subtitle: '${AppLocalizations.of(context)!.lecture} • ${c.location}',
                type: 'CLASS',
                color: Color(c.color),
                icon: Icons.school,
              ),
            );
          }
        }
        if (c.seminarDay == dayName) {
          bool show =
              c.seminarFrequency == 'Weekly' ||
              (c.seminarFrequency == 'Bi-Weekly (odd)' && weekInfo['isOdd']) ||
              (c.seminarFrequency == 'Bi-Weekly (even)' && !weekInfo['isOdd']);
          if (show) {
            allItems.add(
              _AgendaItemData(
                time: c.seminarTime,
                title: c.title,
                subtitle: '${AppLocalizations.of(context)!.seminar} • ${c.seminarLocation}',
                type: 'MEETING',
                color: Color(c.color).withValues(alpha: 0.7),
                icon: Icons.groups,
              ),
            );
          }
        }
      }
    }

    // Add Tasks
    for (var t in taskProvider.tasks) {
      if (t.dueDate != null && isSameDay(t.dueDate!, selectedDay)) {
        allItems.add(
          _AgendaItemData(
            time: DateFormat('HH:mm').format(t.dueDate!),
            title: t.title,
            subtitle: t.description ?? 'No description',
            type: 'TASK',
            color: Colors.orange,
            icon: Icons.task_alt,
            isCompleted: t.isCompleted,
            progress: t.progress,
          ),
        );
      }
    }

    if (allItems.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_outlined,
        title: AppLocalizations.of(context)!.nothingScheduled,
        subtitle: AppLocalizations.of(context)!.timelineClear,
      );
    }

    // Sort by time
    allItems.sort((a, b) => a.time.compareTo(b.time));

    return Stack(
      children: [
        Positioned(
          left: 19,
          top: 8,
          bottom: 8,
          child: Container(width: 2, color: borderMuted),
        ),
        ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            final item = allItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: scaffoldBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: item.color, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.type == 'TASK' ? primary : subTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.type == 'TASK'
                                  ? primary.withValues(alpha: 0.3)
                                  : borderMuted,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.type,
                                      style: TextStyle(
                                        color: item.color,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTextColor,
                                ),
                              ),
                              if (item.type == 'TASK' && item.progress > 0) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: item.progress,
                                          backgroundColor: scaffoldBg,
                                          valueColor: AlwaysStoppedAnimation(
                                            primary,
                                          ),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(item.progress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AgendaItemData {
  final String time;
  final String title;
  final String subtitle;
  final String type;
  final Color color;
  final IconData icon;
  final bool isCompleted;
  final double progress;

  _AgendaItemData({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.color,
    required this.icon,
    this.isCompleted = false,
    this.progress = 0.0,
  });
}
