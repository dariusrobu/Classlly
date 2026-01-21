import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:classlly/data/repositories/supabase_repository.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:intl/intl.dart';
import 'package:classlly/core/services/notification_service.dart';

enum LibraryView { dashboard, allNotes, courses, tasks, calendar, archive }

class LibraryProvider with ChangeNotifier {
  final SupabaseRepository _remoteRepository = SupabaseRepository();
  final NotesRepository _localRepository = NotesRepository();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _syncSubscription;

  LibraryView _currentView = LibraryView.dashboard;
  String _searchQuery = '';
  String? _selectedTag;
  DateTime? _lastSynced;
  String? _currentFolderId;

  LibraryView get currentView => _currentView;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  DateTime? get lastSynced => _lastSynced;
  String? get currentFolderId => _currentFolderId;

  List<Task> get tasks => _localRepository.getAllTasks();
  List<Course> get courses => _localRepository.getAllCourses();
  List<Note> get deletedNotes => _localRepository.getDeletedNotes();
  List<Task> get deletedTasks => _localRepository.getDeletedTasks();
  List<Folder> get deletedFolders => _localRepository.getDeletedFolders();
  StudentProfile get studentProfile => _localRepository.getStudentProfile();

  void initSync() async {
    // Perform full background sync
    await _remoteRepository.syncAll();
    _lastSynced = DateTime.now();
    notifyListeners();

    // Keep listening for note changes specifically for real-time
    _syncSubscription?.cancel();
    _syncSubscription = _remoteRepository.notesStream().listen((remoteNotes) {
      _lastSynced = DateTime.now();
      notifyListeners();
    });

    // Seed initial data if empty
    if (tasks.isEmpty) {
      _seedInitialData();
    }
  }

  Future<void> createDemoProfile() async {
    final random = Random();
    
    // 1. Create 5 Courses
    final coursesData = [
      {
        'title': 'Computer Science 101',
        'professor': 'Dr. Alan Turing',
        'location': 'Lab 3B',
        'day': 'Monday',
        'time': '10:00 AM',
        'color': const Color(0xFF3B82F6), // Blue
        'frequency': 'Weekly',
        'seminarProf': 'T.A. Ada Lovelace',
        'seminarLoc': 'Room 202',
        'seminarDay': 'Wednesday',
        'seminarTime': '02:00 PM',
        'seminarFreq': 'Weekly',
      },
      {
        'title': 'Calculus II',
        'professor': 'Prof. Isaac Newton',
        'location': 'Room 204',
        'day': 'Tuesday',
        'time': '02:00 PM',
        'color': const Color(0xFFEF4444), // Red
        'frequency': 'Weekly',
        'seminarProf': 'T.A. Gottfried Leibniz',
        'seminarLoc': 'Room 301',
        'seminarDay': 'Thursday',
        'seminarTime': '04:00 PM',
        'seminarFreq': 'Weekly',
      },
      {
        'title': 'Physics: Mechanics',
        'professor': 'Dr. Marie Curie',
        'location': 'Hall A',
        'day': 'Wednesday',
        'time': '09:00 AM',
        'color': const Color(0xFF10B981), // Green
        'frequency': 'Weekly',
        'seminarProf': 'T.A. Albert Einstein',
        'seminarLoc': 'Lab 1',
        'seminarDay': 'Friday',
        'seminarTime': '10:00 AM',
        'seminarFreq': 'Bi-Weekly (odd)',
      },
      {
        'title': 'English Literature',
        'professor': 'Prof. Shakespeare',
        'location': 'Library 1',
        'day': 'Thursday',
        'time': '11:00 AM',
        'color': const Color(0xFFF59E0B), // Amber
        'frequency': 'Weekly',
        'seminarProf': 'T.A. Jane Austen',
        'seminarLoc': 'Reading Room',
        'seminarDay': 'Monday',
        'seminarTime': '01:00 PM',
        'seminarFreq': 'Weekly',
      },
      {
        'title': 'World History',
        'professor': 'Dr. Herodotus',
        'location': 'Room 105',
        'day': 'Friday',
        'time': '01:00 PM',
        'color': const Color(0xFF8B5CF6), // Purple
        'frequency': 'Weekly',
        'seminarProf': 'T.A. Cleopatra',
        'seminarLoc': 'History Annex',
        'seminarDay': 'Tuesday',
        'seminarTime': '09:00 AM',
        'seminarFreq': 'Bi-Weekly (even)',
      },
    ];

    final createdCourses = <Course>[];

    for (var data in coursesData) {
      final course = Course.create(
        title: data['title'] as String,
        professor: data['professor'] as String,
        location: data['location'] as String,
        courseDay: data['day'] as String,
        courseTime: data['time'] as String,
        color: data['color'] as Color,
        semester: 'Semester 1',
        credits: 6.0,
        courseFrequency: data['frequency'] as String,
        seminarProfessor: data['seminarProf'] as String,
        seminarLocation: data['seminarLoc'] as String,
        seminarDay: data['seminarDay'] as String,
        seminarTime: data['seminarTime'] as String,
        seminarFrequency: data['seminarFreq'] as String,
      );
      await _localRepository.saveCourse(course);
      createdCourses.add(course);
    }

    // 2. Create 50+ Attendance Records
    // Distribute randomly across last 10 weeks for each course
    for (var course in createdCourses) {
      for (int i = 0; i < 12; i++) { // 12 weeks back
        // 80% chance of being present, 10% absent, 10% excused
        final r = random.nextDouble();
        AttendanceStatus status;
        if (r < 0.8) {
          status = AttendanceStatus.present;
        } else if (r < 0.9) {
          status = AttendanceStatus.absent;
        } else {
          status = AttendanceStatus.excused;
        }

        final date = DateTime.now().subtract(Duration(days: i * 7));
        final attendance = Attendance.create(
          courseId: course.id,
          date: date,
          status: status,
        );
        await _localRepository.saveAttendance(attendance);
      }
    }

    // 3. Create 25 Grades
    final assignmentTypes = ['Quiz', 'Homework', 'Lab Report', 'Midterm', 'Project'];
    
    for (var course in createdCourses) {
      for (int i = 0; i < 5; i++) { // 5 grades per course
        final type = assignmentTypes[i];
        final score = 60 + random.nextInt(41); // Score between 60 and 100
        
        final grade = Grade.create(
          courseId: course.id,
          title: '$type ${i + 1}',
          score: score.toDouble(),
          maxScore: 100,
          weight: (i == 3 || i == 4) ? 30 : 10, // Midterm/Project worth more
          date: DateTime.now().subtract(Duration(days: random.nextInt(60))),
        );
        await _localRepository.saveGrade(grade);
      }
    }

    // 4. Create some tasks
    await _localRepository.saveTask(
      Task.create(
        title: 'Review Calculus Notes',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        category: 'Math',
        priority: 2,
      ),
    );
    await _localRepository.saveTask(
      Task.create(
        title: 'Physics Lab Report',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        category: 'Science',
        priority: 1,
      ),
    );
    await _localRepository.saveTask(
      Task.create(
        title: 'Read History Chapter 5',
        dueDate: DateTime.now().add(const Duration(days: 4)),
        category: 'History',
      ),
    );

    notifyListeners();
  }

  void _seedInitialData() async {
    await _localRepository.saveTask(
      Task.create(
        title: 'Read Chapter 4 (Biology)',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        category: 'Science',
      )..isCompleted = true,
    );
    await _localRepository.saveTask(
      Task.create(
        title: 'Submit Abstract (Modern Lit)',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        category: 'Arts',
      ),
    );
    await _localRepository.saveTask(
      Task.create(
        title: 'Practice Quiz (Calculus)',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        category: 'Math',
      ),
    );
    await _localRepository.saveTask(
      Task.create(
        title: 'Group Presentation Slides',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        category: 'Project',
      )..progress = 0.4,
    );
    notifyListeners();
  }

  Future<void> saveCourse(Course course) async {
    await _localRepository.saveCourse(course);
    _scheduleCourseNotifications(course);
    notifyListeners();
  }

  Future<void> deleteCourse(String courseId) async {
    _cancelCourseNotifications(courseId);
    await _localRepository.deleteCourse(courseId);
    notifyListeners();
  }

  void _scheduleCourseNotifications(Course course) {
    _cancelCourseNotifications(course.id);

    // 1. Schedule Lecture
    if (course.courseDay.isNotEmpty && course.courseTime.isNotEmpty) {
      final time = _parseTimeString(course.courseTime);
      if (time != null) {
        _notificationService.scheduleNotification(
          id: '${course.id}lecture'.hashCode,
          title: 'Upcoming Lecture',
          body: 'Your lecture for "${course.title}" starts at ${course.courseTime} in ${course.location}',
          scheduledDate: _nextOccurrence(course.courseDay, time),
          payload: 'course_${course.id}',
        );
      }
    }

    // 2. Schedule Seminar
    if (course.seminarDay.isNotEmpty && course.seminarTime.isNotEmpty) {
      final time = _parseTimeString(course.seminarTime);
      if (time != null) {
        _notificationService.scheduleNotification(
          id: '${course.id}seminar'.hashCode,
          title: 'Upcoming Seminar',
          body: 'Your seminar for "${course.title}" starts at ${course.seminarTime} in ${course.seminarLocation}',
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
    // ...
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
    
    DateTime scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
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

  Future<void> saveTask(Task task) async {
    await _localRepository.saveTask(task);
    _scheduleTaskReminders(task);
    notifyListeners();
  }

  void _scheduleTaskReminders(Task task) {
    final notificationId = task.id.hashCode;
    _notificationService.cancelNotification(notificationId);

    if (task.isCompleted || task.isDeleted) return;

    if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
      _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Task Reminder',
        body: 'Reminder: ${task.title}',
        scheduledDate: task.reminderTime!,
        payload: 'task_${task.id}',
      );
    } else if (task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
      final reminder = task.dueDate!.subtract(const Duration(hours: 1));
      if (reminder.isAfter(DateTime.now())) {
        _notificationService.scheduleNotification(
          id: notificationId,
          title: 'Upcoming Deadline',
          body: 'Your task "${task.title}" is due in 1 hour.',
          scheduledDate: reminder,
          payload: 'task_${task.id}',
        );
      }
    }
  }

  Future<void> addTask(String title, {DateTime? dueDate, String? category}) async {
    final task = Task.create(
      title: title,
      dueDate: dueDate,
      category: category,
      priority: category == 'Exam' ? 2 : 1,
    );
    await saveTask(task);
  }

  Future<void> createFolder(String title) async {
    final folder = Folder.create(
      title: title,
      parentId: _currentFolderId,
      type: FolderType.notebook,
    );
    await _localRepository.saveFolder(folder);
    notifyListeners();
  }

  Future<void> renameFolder(Folder folder, String newTitle) async {
    folder.title = newTitle;
    await _localRepository.saveFolder(folder);
    notifyListeners();
  }

  Future<void> deleteFolder(String folderId) async {
    final folder = _localRepository.getFolder(folderId);
    if (folder != null) {
      folder.isDeleted = true;
      await _localRepository.saveFolder(folder);
      notifyListeners();
    }
  }

  Future<void> restoreFolder(String folderId) async {
    final folder = _localRepository.getFolder(folderId);
    if (folder != null) {
      folder.isDeleted = false;
      await _localRepository.saveFolder(folder);
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteFolder(String folderId) async {
    await _localRepository.deleteFolder(folderId);
    notifyListeners();
  }

  Future<void> moveFolder(Folder folder, String? newParentId) async {
    if (folder.id == newParentId) return;
    folder.parentId = newParentId;
    await _localRepository.saveFolder(folder);
    notifyListeners();
  }

  void navigateToFolder(String? folderId) {
    _currentFolderId = folderId;
    notifyListeners();
  }

  Future<Note> createNoteInCurrentFolder() async {
    final note = Note.create(notebookId: _currentFolderId);
    await _localRepository.saveNote(note);
    notifyListeners();
    return note;
  }

  Future<void> renameNote(Note note, String newTitle) async {
    note.title = newTitle;
    await _localRepository.saveNote(note);
    notifyListeners();
  }

  Future<void> moveNote(Note note, String? newFolderId) async {
    note.notebookId = newFolderId;
    await _localRepository.saveNote(note);
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    final note = _localRepository.getNote(noteId);
    if (note != null) {
      note.isDeleted = true;
      await _localRepository.saveNote(note);
      notifyListeners();
    }
  }

  Future<void> restoreNote(String noteId) async {
    final note = _localRepository.getNote(noteId);
    if (note != null) {
      note.isDeleted = false;
      await _localRepository.saveNote(note);
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteNote(String noteId) async {
    await _localRepository.deleteNote(noteId);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    final task = _localRepository.getTask(taskId);
    if (task != null) {
      task.isDeleted = true;
      await _localRepository.saveTask(task);
      notifyListeners();
    }
  }

  Future<void> restoreTask(String taskId) async {
    final task = _localRepository.getTask(taskId);
    if (task != null) {
      task.isDeleted = false;
      await _localRepository.saveTask(task);
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteTask(String taskId) async {
    _notificationService.cancelNotification(taskId.hashCode);
    await _localRepository.deleteTask(taskId);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final notes = _localRepository.getDeletedNotes();
    final tasks = _localRepository.getDeletedTasks();
    final folders = _localRepository.getDeletedFolders();

    for (var note in notes) {
      await _localRepository.deleteNote(note.id);
    }
    for (var task in tasks) {
      await _localRepository.deleteTask(task.id);
    }
    for (var folder in folders) {
      await _localRepository.deleteFolder(folder.id);
    }
    notifyListeners();
  }

  Future<void> toggleTask(Task task) async {
    task.isCompleted = !task.isCompleted;
    if (task.isCompleted) {
      _notificationService.cancelNotification(task.id.hashCode);
    } else {
      _scheduleTaskReminders(task);
    }
    await _localRepository.saveTask(task);
    notifyListeners();
  }

  void setView(LibraryView view) {
    _currentView = view;
    _selectedTag = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void filterByTag(String tag) {
    _selectedTag = tag;
    _currentView = LibraryView.allNotes;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}
