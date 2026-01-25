import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

class WidgetService {
  final NotesRepository _repository = NotesRepository();
  static const String appGroupId = 'group.com.robudarius.classlly';
  static const String iOSWidgetName = 'ClassllyWidgets';
  static const String androidWidgetName = 'ClassllyWidget';

  // Data Keys
  static const String keyNextClassTitle = 'next_class_title';
  static const String keyNextClassTime = 'next_class_time';
  static const String keyNextClassLocation = 'next_class_location';
  static const String keyNextTaskTitle = 'next_task_title';
  static const String keyNextTaskDate = 'next_task_date';
  static const String keyTodayTaskCount = 'today_task_count';
  static const String keyTodayClassCount = 'today_class_count';
  static const String keyUpdatedAt = 'updated_at';
  static const String keyAllCourses = 'all_courses_json';

  Future<void> refreshUpNextWidget() async {
    final courses = _repository.getAllCourses();
    final tasks = _repository.getAllTasks();
    await updateUpNextData(courses: courses, tasks: tasks);
    await updateAllCoursesData(courses);
  }

  Future<void> updateAllCoursesData(List<Course> courses) async {
    final coursesJson = jsonEncode(courses.map((c) => {
      'id': c.id,
      'title': c.title,
      'grade': c.cachedAverageGrade,
      'attendance': c.cachedAttendanceRate,
      'color': c.color,
    }).toList());
    
    await HomeWidget.saveWidgetData(keyAllCourses, coursesJson);
    
    if (courses.isNotEmpty) {
      await updateSelectedCourseData(courses.first);
    }
  }

  Future<void> updateSelectedCourseData(Course course) async {
    await HomeWidget.saveWidgetData('selected_course_title', course.title);
    await HomeWidget.saveWidgetData('selected_course_grade', course.cachedAverageGrade);
    await HomeWidget.saveWidgetData('selected_course_attendance', course.cachedAttendanceRate);
    await HomeWidget.saveWidgetData('selected_course_color', course.color);
  }

  Future<void> updateUpNextData({
    required List<Course> courses,
    required List<Task> tasks,
  }) async {
    final now = DateTime.now();
    
    // 1. Find Next Class
    Course? nextClass;
    DateTime? nextClassDate;

    // Helper to find next occurrence
    DateTime? getNextOccurrence(Course c) {
      if (c.courseDay.isEmpty || c.courseTime.isEmpty) return null;
      try {
        final timeFormat = DateFormat.jm();
        final time = timeFormat.parse(c.courseTime);
        final days = {
          'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
          'Thursday': 4, 'Friday': 5, 'Saturday': 6, 'Sunday': 7
        };
        final targetDay = days[c.courseDay] ?? 1;
        
        var d = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        
        // If today matches but time passed, or day doesn't match, move forward
        while (d.weekday != targetDay || d.isBefore(now)) {
          d = d.add(const Duration(days: 1));
        }
        return d;
      } catch (e) {
        return null;
      }
    }

    for (var c in courses) {
      final d = getNextOccurrence(c);
      if (d != null) {
        if (nextClassDate == null || d.isBefore(nextClassDate)) {
          nextClassDate = d;
          nextClass = c;
        }
      }
    }

    // 2. Find Next Task
    final pendingTasks = tasks.where((t) => !t.isCompleted && !t.isDeleted && t.dueDate != null).toList();
    pendingTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final nextTask = pendingTasks.firstOrNull;

    // 3. Counts
    final todayTasks = tasks.where((t) => 
      !t.isDeleted && 
      !t.isCompleted && 
      t.dueDate != null && 
      _isSameDay(t.dueDate!, now)
    ).length;

    final todayClasses = courses.where((c) => 
      c.courseDay == DateFormat('EEEE').format(now)
    ).length;

    // 4. Tasks JSON for Checklist
    final tasksJson = jsonEncode(tasks
      .where((t) => !t.isDeleted && !t.isCompleted)
      .take(5) // Limit to top 5 for widget performance
      .map((t) => {
        'id': t.id,
        'title': t.title,
        'priority': t.priority,
      }).toList());

    // Save Data
    await HomeWidget.saveWidgetData(keyNextClassTitle, nextClass?.title ?? 'No classes upcoming');
    await HomeWidget.saveWidgetData(keyNextClassTime, nextClassDate != null ? DateFormat('EEE, h:mm a').format(nextClassDate) : '');
    await HomeWidget.saveWidgetData(keyNextClassLocation, nextClass?.location ?? '');
    
    await HomeWidget.saveWidgetData(keyNextTaskTitle, nextTask?.title ?? 'No pending tasks');
    await HomeWidget.saveWidgetData(keyNextTaskDate, nextTask?.dueDate != null ? DateFormat('MMM d, h:mm a').format(nextTask!.dueDate!) : '');
    
    await HomeWidget.saveWidgetData(keyTodayTaskCount, todayTasks);
    await HomeWidget.saveWidgetData(keyTodayClassCount, todayClasses);
    await HomeWidget.saveWidgetData('all_tasks_json', tasksJson);
    await HomeWidget.saveWidgetData(keyUpdatedAt, DateFormat.Hm().format(now));

    await HomeWidget.updateWidget(
      name: iOSWidgetName,
      iOSName: iOSWidgetName,
      androidName: androidWidgetName,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
