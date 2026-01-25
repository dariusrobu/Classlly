import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/core/services/notification_service.dart';

class CourseProvider with ChangeNotifier {
  final NotesRepository _localRepository;
  final NotificationService _notificationService;

  CourseProvider({NotesRepository? repository, NotificationService? notificationService})
      : _localRepository = repository ?? NotesRepository(),
        _notificationService = notificationService ?? NotificationService();

  List<Course> get courses => _localRepository.getAllCourses();

  Future<void> recalculateStats() async {
    final allCourses = _localRepository.getAllCourses();
    for (var course in allCourses) {
      // 1. Grade Avg
      final grades = _localRepository.getGradesForCourse(course.id);
      double gradeAvg = 0.0;
      if (grades.isNotEmpty) {
        double totalWeightedScore = 0;
        double totalWeight = 0;
        for (var g in grades) {
          totalWeightedScore += ((g.score / g.maxScore) * 100) * g.weight;
          totalWeight += g.weight;
        }
        gradeAvg = totalWeight > 0 ? totalWeightedScore / totalWeight : 0;
      }

      // 2. Attendance Rate
      final records = _localRepository.getAttendanceForCourse(course.id);
      double attRate = 0.0;
      if (records.isNotEmpty) {
        final present = records
            .where(
              (r) =>
                  r.status == AttendanceStatus.present ||
                  r.status == AttendanceStatus.excused,
            )
            .length;
        attRate = (present / records.length) * 100;
      }

      if (course.cachedAverageGrade != gradeAvg ||
          course.cachedAttendanceRate != attRate) {
        course.cachedAverageGrade = gradeAvg;
        course.cachedAttendanceRate = attRate;
        await _localRepository.saveCourse(course);
      }
    }
    notifyListeners();
  }

  Future<void> saveCourse(Course course) async {
    await _notificationService.requestPermissions();
    await _localRepository.saveCourse(course);
    _scheduleCourseNotifications(course);
    await recalculateStats();
    notifyListeners();
  }

  Future<void> deleteCourse(String courseId) async {
    _cancelCourseNotifications(courseId);
    await _localRepository.deleteCourse(courseId);
    await recalculateStats();
    notifyListeners();
  }

  Future<void> saveAttendance(Attendance attendance) async {
    await _localRepository.saveAttendance(attendance);
    await recalculateStats();
    notifyListeners();
  }

  Future<void> deleteAttendance(String id) async {
    await _localRepository.deleteAttendance(id);
    await recalculateStats();
    notifyListeners();
  }

  Future<void> saveGrade(Grade grade) async {
    await _localRepository.saveGrade(grade);
    await recalculateStats();
    notifyListeners();
  }

  Future<void> deleteGrade(String id) async {
    await _localRepository.deleteGrade(id);
    await recalculateStats();
    notifyListeners();
  }

  void _scheduleCourseNotifications(Course course) {
    _cancelCourseNotifications(course.id);

    if (course.courseDay.isNotEmpty && course.courseTime.isNotEmpty) {
      final time = _parseTimeString(course.courseTime);
      if (time != null) {
        _notificationService.scheduleNotification(
          id: '${course.id}lecture'.hashCode,
          title: 'Upcoming Lecture',
          body:
              'Your lecture for "${course.title}" starts at ${course.courseTime} in ${course.location}',
          scheduledDate: _nextOccurrence(course.courseDay, time),
          payload: 'course_${course.id}',
        );
      }
    }

    if (course.seminarDay.isNotEmpty && course.seminarTime.isNotEmpty) {
      final time = _parseTimeString(course.seminarTime);
      if (time != null) {
        _notificationService.scheduleNotification(
          id: '${course.id}seminar'.hashCode,
          title: 'Upcoming Seminar',
          body:
              'Your seminar for "${course.title}" starts at ${course.seminarTime} in ${course.seminarLocation}',
          scheduledDate: _nextOccurrence(course.seminarDay, time),
          payload: 'course_${course.id}',
        );
      }
    }
  }

  void _cancelCourseNotifications(String courseId) {
    _notificationService.cancelNotification('${courseId}lecture'.hashCode);
    _notificationService.cancelNotification('${courseId}seminar'.hashCode);
  }

  DateTime _nextOccurrence(String dayName, TimeOfDay time) {
    final days = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    final targetDay = days[dayName] ?? 1;
    final now = DateTime.now();
    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != targetDay || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final format = DateFormat.jm();
      final dt = format.parse(timeStr);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      return null;
    }
  }
}
