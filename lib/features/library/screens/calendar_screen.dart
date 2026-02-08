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
                    AppLocalizations.of(context)!.academicCalendar,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.academicScheduleDesc,
                    style: const TextStyle(color: subTextColor, fontSize: 14),
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
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (index < allItems.length - 1)
                                Container(
                                  width: 2,
                                  height: 60,
                                  color: borderMuted,
                                ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    color: item.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
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
  _AgendaItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
  });
}
