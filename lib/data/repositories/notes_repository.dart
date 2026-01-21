import 'package:hive/hive.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/user_preferences_model.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/data/models/student_profile_model.dart';

class NotesRepository {
  static const String boxName = 'notes';
  static const String notebookBoxName = 'notebooks';
  static const String taskBoxName = 'tasks';
  static const String courseBoxName = 'courses';
  static const String gradeBoxName = 'grades';
  static const String attendanceBoxName = 'attendance';
  static const String folderBoxName = 'folders';
  static const String preferencesBoxName = 'preferences';
  static const String periodsBoxName = 'periods';
  static const String eventsBoxName = 'events';
  static const String profileBoxName = 'profile';

  static Future<void> init() async {
    Hive.registerAdapter(StrokePointAdapter());
    Hive.registerAdapter(StrokeAdapter());
    Hive.registerAdapter(TextBlockAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(NotebookAdapter());
    Hive.registerAdapter(ImageBlockAdapter());
    Hive.registerAdapter(TaskAdapter());

    // New Adapters
    Hive.registerAdapter(CourseAdapter());
    Hive.registerAdapter(GradeAdapter());
    Hive.registerAdapter(AttendanceAdapter());
    Hive.registerAdapter(AttendanceStatusAdapter());
    Hive.registerAdapter(FolderAdapter());
    Hive.registerAdapter(FolderTypeAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    Hive.registerAdapter(AcademicPeriodAdapter());
    Hive.registerAdapter(AcademicPeriodTypeAdapter());
    Hive.registerAdapter(AcademicEventAdapter());
    Hive.registerAdapter(AcademicEventTypeAdapter());
    Hive.registerAdapter(StudentProfileAdapter());

    await Hive.openBox<Note>(boxName);
    await Hive.openBox<Notebook>(notebookBoxName);
    await Hive.openBox<Task>(taskBoxName);
    await Hive.openBox<Course>(courseBoxName);
    await Hive.openBox<Grade>(gradeBoxName);
    await Hive.openBox<Attendance>(attendanceBoxName);
    await Hive.openBox<Folder>(folderBoxName);
    await Hive.openBox<UserPreferences>(preferencesBoxName);
    await Hive.openBox<AcademicPeriod>(periodsBoxName);
    await Hive.openBox<AcademicEvent>(eventsBoxName);
    await Hive.openBox<StudentProfile>(profileBoxName);
  }

  Box<Note> get _box => Hive.box<Note>(boxName);
  Box<Notebook> get _notebookBox => Hive.box<Notebook>(notebookBoxName);
  Box<Task> get _taskBox => Hive.box<Task>(taskBoxName);
  Box<Course> get _courseBox => Hive.box<Course>(courseBoxName);
  Box<Grade> get _gradeBox => Hive.box<Grade>(gradeBoxName);
  Box<Attendance> get _attendanceBox => Hive.box<Attendance>(attendanceBoxName);
  Box<Folder> get _folderBox => Hive.box<Folder>(folderBoxName);
  Box<UserPreferences> get _prefsBox =>
      Hive.box<UserPreferences>(preferencesBoxName);
  Box<AcademicPeriod> get _periodsBox => Hive.box<AcademicPeriod>(periodsBoxName);
  Box<AcademicEvent> get _eventsBox => Hive.box<AcademicEvent>(eventsBoxName);
  Box<StudentProfile> get _profileBox => Hive.box<StudentProfile>(profileBoxName);

  // --- Notes ---
  List<Note> getAllNotes({String? notebookId}) {
    final notes = _box.values.where((n) => !n.isDeleted).toList();
    if (notebookId != null) {
      return notes.where((n) => n.notebookId == notebookId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Note> getNotesInFolder(String? folderId) {
    final notes = _box.values.where((n) => !n.isDeleted).toList();
    return notes
        .where((n) => n.notebookId == folderId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Note> getDeletedNotes() {
    return _box.values.where((n) => n.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // --- Notebooks ---
  List<Notebook> getAllNotebooks() {
    return _notebookBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // --- Tasks ---
  List<Task> getAllTasks() {
    return _taskBox.values.where((t) => !t.isDeleted).toList()
      ..sort(
        (a, b) => (a.dueDate ?? DateTime.now()).compareTo(
          b.dueDate ?? DateTime.now(),
        ),
      );
  }

  List<Task> getDeletedTasks() {
    return _taskBox.values.where((t) => t.isDeleted).toList()
      ..sort(
        (a, b) => (a.dueDate ?? DateTime.now()).compareTo(
          b.dueDate ?? DateTime.now(),
        ),
      );
  }

  // --- Courses ---
  List<Course> getAllCourses() {
    return _courseBox.values.toList();
  }

  Future<void> saveCourse(Course course) async {
    await _courseBox.put(course.id, course);
  }

  Future<void> deleteCourse(String id) async {
    await _courseBox.delete(id);
  }

  // --- Grades ---
  List<Grade> getGradesForCourse(String courseId) {
    return _gradeBox.values.where((g) => g.courseId == courseId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveGrade(Grade grade) async {
    await _gradeBox.put(grade.id, grade);
  }

  // --- Attendance ---
  List<Attendance> getAttendanceForCourse(String courseId) {
    return _attendanceBox.values.where((a) => a.courseId == courseId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveAttendance(Attendance attendance) async {
    await _attendanceBox.put(attendance.id, attendance);
  }

  // --- Folders ---
  List<Folder> getFolders({String? parentId, required FolderType type}) {
    return _folderBox.values
        .where((f) => f.parentId == parentId && f.type == type && !f.isDeleted)
        .toList();
  }

  List<Folder> getDeletedFolders() {
    return _folderBox.values.where((f) => f.isDeleted).toList()
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime.now()).compareTo(
          a.updatedAt ?? DateTime.now(),
        ),
      );
  }

  Future<void> saveFolder(Folder folder) async {
    folder.updatedAt = DateTime.now();
    await _folderBox.put(folder.id, folder);
  }

  Future<void> deleteFolder(String id) async {
    await _folderBox.delete(id);
  }

  Folder? getFolder(String id) {
    return _folderBox.get(id);
  }

  // --- Preferences ---
  UserPreferences getPreferences() {
    if (_prefsBox.isEmpty) {
      final defaultPrefs = UserPreferences();
      _prefsBox.put('user_prefs', defaultPrefs);
      return defaultPrefs;
    }
    return _prefsBox.get('user_prefs')!;
  }

  Future<void> savePreferences(UserPreferences prefs) async {
    await _prefsBox.put('user_prefs', prefs);
  }

  // --- Academic Calendar ---
  List<AcademicPeriod> getAllPeriods() {
    return _periodsBox.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<void> savePeriod(AcademicPeriod period) async {
    await _periodsBox.put(period.id, period);
  }

  Future<void> deletePeriod(String id) async {
    await _periodsBox.delete(id);
  }

  List<AcademicEvent> getAllEvents() {
    return _eventsBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> saveEvent(AcademicEvent event) async {
    await _eventsBox.put(event.id, event);
  }

  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
  }

  // --- Student Profile ---
  StudentProfile getStudentProfile() {
    if (_profileBox.isEmpty) {
      final defaultProfile = StudentProfile(
        name: 'Alex',
        university: 'UBB Cluj-Napoca',
        major: 'Computer Science',
        year: 'Year 2',
        studentId: 'STUD-12345',
      );
      _profileBox.put('student_profile', defaultProfile);
      return defaultProfile;
    }
    return _profileBox.get('student_profile')!;
  }

  Future<void> saveStudentProfile(StudentProfile profile) async {
    await _profileBox.put('student_profile', profile);
  }

  // --- Legacy/Existing ---
  Future<void> saveTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  Task? getTask(String id) {
    return _taskBox.get(id);
  }

  Future<void> saveNotebook(Notebook notebook) async {
    notebook.updatedAt = DateTime.now();
    await _notebookBox.put(notebook.id, notebook);
  }

  Future<void> deleteNotebook(String id) async {
    await _notebookBox.delete(id);
  }

  Future<void> saveNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _box.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  Note? getNote(String id) {
    return _box.get(id);
  }
}
