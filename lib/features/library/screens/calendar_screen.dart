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
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/library/widgets/empty_state.dart';

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

    // 2. Add Tasks
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
    // Using specific colors from the original implementation for the dark calendar look
    const charcoal = Color(0xFF121212);
    const cardBg = Color(0xFF1E1E1E);
    const borderMuted = Color(0xFF2A2A2A);
    const primary = Color(0xFF8B5CF6);

    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final weekInfo = calendarProvider.getWeekInfo(_selectedDay);

    return Container(
      color: charcoal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Calendar Area
          Expanded(
            child: Column(
              children: [
                _buildCalendarHeader(context, weekInfo, primary),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
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
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        eventLoader: (day) => _getEventsForDay(
                          day,
                          calendarProvider,
                          libraryProvider.tasks,
                          NotesRepository().getAllCourses(),
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
                        rowHeight: 120,
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: true,
                          tableBorder: TableBorder.all(
                            color: borderMuted,
                            width: 0.5,
                          ),
                          defaultTextStyle: const TextStyle(color: Colors.grey),
                          weekendTextStyle: const TextStyle(color: Colors.grey),
                          outsideTextStyle: const TextStyle(
                            color: Color(0xFF444444),
                          ),
                          todayDecoration: const BoxDecoration(),
                          todayTextStyle: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                          selectedDecoration: const BoxDecoration(),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          markerDecoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFF2A2A2A)),
                            ),
                          ),
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
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildCell(day, Colors.transparent, false);
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return _buildCell(day, primary, true);
                          },
                          outsideBuilder: (context, day, focusedDay) {
                            return _buildCell(day, Colors.black26, false);
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
              ],
            ),
          ),

          // Right Daily Agenda Sidebar
          Container(
            width: 360,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: borderMuted)),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Agenda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM d').format(_selectedDay),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                        } else if (value == 'calendar') {
                          // Already in calendar view
                        } else if (value == 'clear') {
                          final box = Hive.box<Task>(
                            NotesRepository.taskBoxName,
                          );
                          final today = DateTime.now();
                          final completedToday =
                              box.values
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
                            libraryProvider.deleteTask(task.id);
                          }
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'add',
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add Task'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'clear',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_sweep, size: 18),
                                  SizedBox(width: 8),
                                  Text('Clear Completed'),
                                ],
                              ),
                            ),
                          ],
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: _buildAgendaTimeline(
                    context,
                    _selectedDay,
                    weekInfo,
                    primary,
                    borderMuted,
                    cardBg,
                    charcoal,
                  ),
                ),
              ],
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
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                weekInfo != null
                    ? 'Week ${weekInfo['week']} (${weekInfo['label']} Week) • ${weekInfo['periodName']}'
                    : 'Manage your academic schedule and deadlines.',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              _buildViewToggle(),
              const SizedBox(width: 16),
              _buildNavButtons(primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          _toggleBtn('Month', true, () {
            // Static month view
          }),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF121212) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons(Color primary) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
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
            icon: const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
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
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Colors.white,
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
            icon: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildCell(DateTime day, Color color, bool isSelected) {
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
                  color: isSelected ? Colors.white : Colors.grey,
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
    Color charcoal,
  ) {
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final courses = NotesRepository().getAllCourses();

    final allItems = <_AgendaItemData>[];

    // Add Academic Periods/Events
    for (var p in calendarProvider.periods) {
      if ((selectedDay.isAtSameMomentAs(p.startDate) ||
              selectedDay.isAfter(p.startDate)) &&
          (selectedDay.isAtSameMomentAs(p.endDate) ||
              selectedDay.isBefore(p.endDate))) {
        allItems.add(
          _AgendaItemData(
            time: 'All Day',
            title: p.name,
            subtitle: p.type.name.toUpperCase(),
            type: 'PERIOD',
            color: primary,
            icon: Icons.event_note,
          ),
        );
      }
    }

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
                subtitle: 'Lecture • ${c.location}',
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
                subtitle: 'Seminar • ${c.seminarLocation}',
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
    for (var t in libraryProvider.tasks) {
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
      return const EmptyState(
        icon: Icons.event_available_outlined,
        title: 'Nothing scheduled',
        subtitle: 'Your timeline is clear for this day.',
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
                        color: charcoal,
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
                            color: item.type == 'TASK' ? primary : Colors.grey,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
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
                                          backgroundColor: charcoal,
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
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey,
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
