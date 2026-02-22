import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';

import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';

import 'package:classlly/features/library/widgets/add_event_dialog.dart';
// import 'package:classlly/l10n/app_localizations.dart';

enum CalendarView { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarView _currentView = CalendarView.week;

  final List<String> _hours = List.generate(24, (index) => '${index.toString().padLeft(2, '0')}:00');

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // We'll handle the initial view in didChangeDependencies if needed, 
    // but building with MediaQuery is more reactive.
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    const subTextColor = Colors.grey;
    final borderMuted = Theme.of(context).dividerColor.withValues(alpha: 0.1);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final currentView = isMobile ? CalendarView.day : _currentView;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          _buildChronosHeader(context, textColor, primary, subTextColor, borderMuted, isMobile),
          Expanded(
            child: _buildMainContent(
              context,
              calendarProvider,
              taskProvider,
              primary,
              cardBg,
              scaffoldBg,
              textColor,
              subTextColor,
              borderMuted,
              currentView,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChronosHeader(
    BuildContext context,
    Color textColor,
    Color primary,
    Color subTextColor,
    Color borderMuted,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: borderMuted)),
      ),
      child: Row(
        children: [
          // Month/Year Title
          Expanded(
            child: Text(
              DateFormat(isMobile ? 'MMM yyyy' : 'MMMM yyyy').format(_focusedDay),
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Navigation
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
            decoration: BoxDecoration(
              color: borderMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18),
                  onPressed: () => _navigate(-1, isMobile),
                  color: textColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                Container(height: 16, width: 1, color: borderMuted),
                TextButton(
                  onPressed: () => setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = _focusedDay;
                  }),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: isMobile ? 11 : 13),
                  ),
                ),
                Container(height: 16, width: 1, color: borderMuted),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  onPressed: () => _navigate(1, isMobile),
                  color: textColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 24),
            // View Selector
            _buildViewSelector(textColor, borderMuted),
            const SizedBox(width: 16),
            // New Event Button
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddEventDialog(
                    initialDate: _selectedDay ?? _focusedDay,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewSelector(Color textColor, Color borderMuted) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: borderMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _ViewTab(
            label: 'Day',
            isSelected: _currentView == CalendarView.day,
            onTap: () => setState(() => _currentView = CalendarView.day),
          ),
          _ViewTab(
            label: 'Week',
            isSelected: _currentView == CalendarView.week,
            onTap: () => setState(() => _currentView = CalendarView.week),
          ),
          _ViewTab(
            label: 'Month',
            isSelected: _currentView == CalendarView.month,
            onTap: () => setState(() => _currentView = CalendarView.month),
          ),
        ],
      ),
    );
  }

  void _navigate(int offset, bool isMobile) {
    setState(() {
      final effectiveView = isMobile ? CalendarView.day : _currentView;
      if (effectiveView == CalendarView.month) {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset, 1);
      } else if (effectiveView == CalendarView.week) {
        _focusedDay = _focusedDay.add(Duration(days: offset * 7));
      } else {
        _focusedDay = _focusedDay.add(Duration(days: offset));
      }
      _selectedDay = _focusedDay;
    });
  }

  Widget _buildMainContent(
    BuildContext context,
    AcademicCalendarProvider calendarProvider,
    TaskProvider taskProvider,
    Color primary,
    Color cardBg,
    Color scaffoldBg,
    Color textColor,
    Color subTextColor,
    Color borderMuted,
    CalendarView view,
  ) {
    switch (view) {
      case CalendarView.month:
        return _buildMonthlyCalendar(context, calendarProvider, taskProvider, primary, textColor, subTextColor, borderMuted);
      case CalendarView.week:
        return _buildWeeklyTimetable(context, calendarProvider, taskProvider, primary, cardBg, textColor, subTextColor, borderMuted);
      case CalendarView.day:
        return _buildDailyView(context, calendarProvider, taskProvider, primary, cardBg, textColor, subTextColor, borderMuted, view == CalendarView.day && MediaQuery.of(context).size.width < 600);
    }
  }

  Widget _buildMonthlyCalendar(
    BuildContext context,
    AcademicCalendarProvider calendarProvider,
    TaskProvider taskProvider,
    Color primary,
    Color textColor,
    Color subTextColor,
    Color borderMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderMuted),
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _currentView = CalendarView.day;
            });
          },
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerVisible: false,
          calendarStyle: CalendarStyle(
            defaultTextStyle: TextStyle(color: textColor),
            weekendTextStyle: TextStyle(color: textColor),
            todayDecoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
          ),
          eventLoader: (day) => _getEventsForDay(day, calendarProvider, taskProvider.tasks),
        ),
      ),
    );
  }

  Widget _buildWeeklyTimetable(
    BuildContext context,
    AcademicCalendarProvider calendarProvider,
    TaskProvider taskProvider,
    Color primary,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderMuted,
  ) {
    final monday = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed-width markers that scroll vertically with content
                Container(
                  width: 60,
                  padding: const EdgeInsets.only(top: 110),
                  child: Column(
                    children: _hours.skip(8).take(16).map((h) => Container(
                      height: 100,
                      alignment: Alignment.topCenter,
                      child: Text(h, style: TextStyle(color: subTextColor, fontSize: 11)),
                    )).toList(),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      // Day Headers
                      Row(
                        children: List.generate(5, (i) {
                          final day = monday.add(Duration(days: i));
                          final isToday = isSameDay(day, DateTime.now());
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedDay = day;
                                _currentView = CalendarView.day;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('EEE').format(day).toUpperCase(),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isToday ? primary : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        day.day.toString(),
                                        style: TextStyle(
                                          color: isToday ? Colors.white : textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      // Grid and Events
                      SizedBox(
                        height: 1600,
                        child: Stack(
                          children: [
                            Column(
                              children: List.generate(16, (i) => Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: borderMuted.withValues(alpha: 0.05))),
                                ),
                              )),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                final day = monday.add(Duration(days: i));
                                return Expanded(
                                  child: Container(
                                    height: 1600,
                                    decoration: BoxDecoration(
                                      border: Border(left: BorderSide(color: borderMuted.withValues(alpha: 0.05))),
                                    ),
                                    child: Stack(children: _buildDayEvents(context, day, calendarProvider, primary)),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (MediaQuery.of(context).size.width > 1200)
          Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: borderMuted)),
            ),
            child: _buildSidebarInfo(context, primary, textColor, subTextColor, borderMuted),
          ),
      ],
    );
  }

  Widget _buildDailyView(
    BuildContext context,
    AcademicCalendarProvider calendarProvider,
    TaskProvider taskProvider,
    Color primary,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderMuted,
    bool isMobile,
  ) {
    final day = _selectedDay ?? _focusedDay;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 0, right: isMobile ? 12 : 24, top: 0, bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time markers column (now inside scroll)
          Container(
            width: isMobile ? 45 : 60,
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              children: _hours.skip(8).take(16).map((h) => Container(
                height: 100,
                alignment: Alignment.topCenter,
                child: Text(
                  h,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(isMobile ? 'EEE, MMM d' : 'EEEE, MMMM d').format(day),
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Stack(
                          children: [
                            Column(
                              children: List.generate(16, (i) => Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: borderMuted.withValues(alpha: 0.05))),
                                ),
                              )),
                            ),
                            ..._buildDayEvents(context, day, calendarProvider, primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.of(context).size.width > 1200) ...[
                    const SizedBox(width: 32),
                    Expanded(
                      child: _buildSidebarInfo(
                        context,
                        primary,
                        textColor,
                        subTextColor,
                        borderMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarInfo(BuildContext context, Color primary, Color textColor, Color subTextColor, Color borderMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Next Class', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            Icon(Icons.info_outline, color: subTextColor, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('UI Workshop', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Starts in 15 mins', style: TextStyle(color: subTextColor, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Join Meeting'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<dynamic> _getEventsForDay(DateTime day, AcademicCalendarProvider calendarProvider, List<Task> tasks) {
    final events = <dynamic>[];
    for (var event in calendarProvider.events) {
      if (isSameDay(event.date, day)) events.add(event);
    }
    for (var period in calendarProvider.periods) {
      if ((day.isAtSameMomentAs(period.startDate) || day.isAfter(period.startDate)) &&
          (day.isAtSameMomentAs(period.endDate) || day.isBefore(period.endDate))) {
        if (period.type != AcademicPeriodType.teaching) events.add(period);
      }
    }
    for (var task in tasks) {
      if (task.dueDate != null && isSameDay(task.dueDate!, day)) events.add(task);
    }
    return events;
  }

  List<Widget> _buildDayEvents(BuildContext context, DateTime day, AcademicCalendarProvider provider, Color primary) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final events = <Widget>[];

  // Use fixed English locale for matching with database strings
  final dayName = DateFormat('EEEE', 'en_US').format(day);
  final weekInfo = provider.getWeekInfo(day);

  // 1. Courses & Seminars
  for (var c in courseProvider.courses) {
    if (c.courseDay == dayName && c.courseTime.isNotEmpty) {
      bool show = c.courseFrequency == 'Weekly' || 
          c.courseFrequency.isEmpty ||
          (c.courseFrequency == 'Bi-Weekly (odd)' && (weekInfo?['isOdd'] ?? true)) ||
          (c.courseFrequency == 'Bi-Weekly (even)' && !(weekInfo?['isOdd'] ?? true));
      if (show) {
        events.add(_positionEvent(c.courseTime, c.title, c.location, Color(c.color), 'LECTURE'));
      }
    }
    if (c.seminarDay == dayName && c.seminarTime.isNotEmpty) {
      bool show = c.seminarFrequency == 'Weekly' || 
          c.seminarFrequency.isEmpty ||
          (c.seminarFrequency == 'Bi-Weekly (odd)' && (weekInfo?['isOdd'] ?? true)) ||
          (c.seminarFrequency == 'Bi-Weekly (even)' && !(weekInfo?['isOdd'] ?? true));
      if (show) {
        events.add(_positionEvent(c.seminarTime, '${c.title} (Seminar)', c.seminarLocation, Color(c.color), 'SEMINAR'));
      }
    }
  }

    // 2. Academic Events (Holidays, Free Days)
    for (var ae in provider.events) {
      if (isSameDay(ae.date, day)) {
        events.add(_positionEvent('08:00-09:00', ae.name, 'Campus', Colors.orange, 'EVENT'));
      }
    }

    // 3. Academic Periods (Exams, Breaks, etc.)
    for (var ap in provider.periods) {
      if (ap.type != AcademicPeriodType.teaching) {
        final start = DateTime(ap.startDate.year, ap.startDate.month, ap.startDate.day);
        final end = DateTime(ap.endDate.year, ap.endDate.month, ap.endDate.day);
        final normalizedDay = DateTime(day.year, day.month, day.day);

        if ((normalizedDay.isAtSameMomentAs(start) || normalizedDay.isAfter(start)) &&
            (normalizedDay.isAtSameMomentAs(end) || normalizedDay.isBefore(end))) {
          events.add(_positionEvent('08:00-09:30', ap.name, 'Academic Period', Colors.redAccent, 'PERIOD'));
        }
      }
    }

    // 4. Tasks (Due Today)
    for (var task in taskProvider.tasks) {
      if (task.dueDate != null && isSameDay(task.dueDate!, day) && !task.isCompleted && !task.isDeleted) {
        String timeStr = '09:00-10:00';
        if (task.reminderTime != null) {
          final startTime = task.reminderTime!;
          final endTime = startTime.add(const Duration(hours: 1));
          timeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}-${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
        }
        events.add(_positionEvent(timeStr, task.title, task.category ?? 'General', primary, 'TASK'));
      }
    }

    return events;
  }

  Widget _positionEvent(String timeRange, String title, String location, Color color, String type) {
  try {
    final parts = timeRange.split('-');
    final startStr = parts[0].trim();
    final String? endStr = parts.length > 1 ? parts[1].trim() : null;

    TimeOfDay parseTime(String s) {
      try {
        final df = DateFormat.jm();
        final dt = df.parse(s.trim());
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {
        final tParts = s.trim().split(':');
        return TimeOfDay(
          hour: int.parse(tParts[0]),
          minute: int.parse(tParts[1]),
        );
      }
    }

    final startTime = parseTime(startStr);
    TimeOfDay endTime;
    
    if (endStr != null) {
      endTime = parseTime(endStr);
    } else {
      // Default to 1.5 hours if only start time is provided
      int endHour = startTime.hour + 1;
      int endMinute = startTime.minute + 30;
      if (endMinute >= 60) {
        endHour += 1;
        endMinute -= 60;
      }
      endTime = TimeOfDay(hour: endHour % 24, minute: endMinute);
    }

      final double top = (startTime.hour - 8) * 100.0 + (startTime.minute / 60.0) * 100.0;
      final double durationHours = (endTime.hour - startTime.hour) + (endTime.minute - startTime.minute) / 60.0;
      final double height = durationHours * 100.0;

      return Positioned(
        top: top,
        left: 4,
        right: 4,
        height: height,
        child: _ChronosEventCard(
          title: title,
          time: timeRange,
          location: location,
          color: color,
          type: type,
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? textColor : textColor.withValues(alpha: 0.5),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ChronosEventCard extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final Color color;
  final String type;

  const _ChronosEventCard({
    required this.title,
    required this.time,
    required this.location,
    required this.color,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 10, color: color.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
