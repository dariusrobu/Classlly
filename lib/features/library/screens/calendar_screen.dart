import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';

import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';

import 'package:classlly/l10n/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    const subTextColor = Colors.grey;
    final borderMuted = Theme.of(context).dividerColor.withValues(alpha: 0.1);

    final weekInfo = calendarProvider.getWeekInfo(_selectedDay ?? _focusedDay);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Row(
        children: [
          // 1. Calendar Sidebar (on large screens)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (MediaQuery.of(context).size.width <= 1000)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu, color: textColor),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(
                      _selectedDay ?? _focusedDay,
                    ),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.academicScheduleDesc,
                    style: const TextStyle(color: subTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // Filter + New Event buttons
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderMuted),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: subTextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'New Event',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: borderMuted),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: primary,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: primary,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: const TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                          weekendStyle: TextStyle(
                            color: primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: TextStyle(color: textColor),
                          weekendTextStyle: TextStyle(color: textColor),
                          outsideTextStyle: TextStyle(
                            color: subTextColor.withValues(alpha: 0.5),
                          ),
                          todayDecoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                            ),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) =>
                              _buildMarkers(date, events),
                        ),
                        eventLoader: (day) => _getEventsForDay(
                          day,
                          calendarProvider,
                          taskProvider.tasks,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 2. Agenda Panel
          if (MediaQuery.of(context).size.width > 1100)
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(left: BorderSide(color: borderMuted)),
              ),
              child: _buildAgendaTimeline(
                context,
                _selectedDay ?? _focusedDay,
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
    );
  }

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

  Widget _buildMarkers(DateTime day, List events) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 6,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: events.where((e) => e is! AcademicPeriod).take(3).map((e) {
          Color color = Colors.blue;
          if (e is Task) {
            color = Colors.orange;
          } else if (e is AcademicEvent) {
            color = Colors.green;
          }

          return Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    final taskProvider = Provider.of<TaskProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final courses = courseProvider.courses;

    final allItems = <_AgendaItemData>[];

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
                title: c.title,
                subtitle: '${c.courseTime} • ${c.location}',
                icon: Icons.school,
                color: Color(c.color),
                time: c.courseTime,
                type: 'LECTURE',
              ),
            );
          }
        }
      }
    }

    for (var t in taskProvider.tasks) {
      if (t.dueDate != null &&
          isSameDay(t.dueDate!, selectedDay) &&
          !t.isDeleted) {
        allItems.add(
          _AgendaItemData(
            title: t.title,
            subtitle: t.category ?? '',
            icon: Icons.check_circle,
            color: t.priority == 2 ? Colors.redAccent : Colors.orange,
            time: DateFormat.Hm().format(t.dueDate!),
            type: t.priority == 2 ? 'ASSIGNMENT' : 'TASK',
          ),
        );
      }
    }

    allItems.sort((a, b) => a.time.compareTo(b.time));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(selectedDay),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(selectedDay),
                style: TextStyle(color: subTextColor, fontSize: 14),
              ),
              if (weekInfo != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    weekInfo['week'] != null
                        ? 'Week ${weekInfo['week']} (${weekInfo['label']})'
                        : weekInfo['label'],
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: allItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: subTextColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events today',
                        style: TextStyle(color: subTextColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: allItems.length + 1, // +1 for Tomorrow's Highlights
                  itemBuilder: (context, index) {
                    if (index == allItems.length) {
                      // Tomorrow's Highlights section
                      final tomorrow = selectedDay.add(const Duration(days: 1));
                      final tomorrowItems = <_AgendaItemData>[];
                      final tomorrowName = DateFormat('EEEE').format(tomorrow);
                      if (weekInfo != null) {
                        for (var c in courses) {
                          if (c.courseDay == tomorrowName) {
                            tomorrowItems.add(
                              _AgendaItemData(
                                title: c.title,
                                subtitle: '${c.courseTime} • ${c.location}',
                                icon: Icons.school,
                                color: Color(c.color),
                                time: c.courseTime,
                                type: 'LECTURE',
                              ),
                            );
                          }
                        }
                      }
                      for (var t in taskProvider.tasks) {
                        if (t.dueDate != null &&
                            isSameDay(t.dueDate!, tomorrow) &&
                            !t.isDeleted) {
                          tomorrowItems.add(
                            _AgendaItemData(
                              title: t.title,
                              subtitle: t.category ?? '',
                              icon: Icons.check_circle,
                              color: t.priority == 2
                                  ? Colors.redAccent
                                  : Colors.orange,
                              time: DateFormat.Hm().format(t.dueDate!),
                              type: t.priority == 2 ? 'ASSIGNMENT' : 'TASK',
                            ),
                          );
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              "TOMORROW'S HIGHLIGHTS",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (tomorrowItems.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No events tomorrow',
                                  style: TextStyle(
                                    color: subTextColor.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...tomorrowItems.map((item) {
                                final borderColor = item.type == 'ASSIGNMENT'
                                    ? Colors.redAccent
                                    : item.type == 'LECTURE'
                                        ? Colors.blueAccent
                                        : Colors.orange;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scaffoldBg.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(color: borderColor, width: 3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(item.icon, size: 16, color: borderColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        item.time,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    }

                    final item = allItems[index];
                    // Categorized card with colored left border
                    final borderColor = item.type == 'ASSIGNMENT'
                        ? Colors.redAccent
                        : item.type == 'LECTURE'
                            ? Colors.blueAccent
                            : Colors.orange;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderMuted),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Colored left border
                            Container(
                              width: 4,
                              height: 80,
                              decoration: BoxDecoration(
                                color: borderColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: borderColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.type,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: borderColor,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          item.time,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: subTextColor,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    if (item.subtitle.isNotEmpty)
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AgendaItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String time;
  final String type;
  _AgendaItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
    this.type = 'TASK',
  });
}
