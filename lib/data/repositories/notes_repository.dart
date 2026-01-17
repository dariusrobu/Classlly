import 'package:hive/hive.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/user_preferences_model.dart';

class NotesRepository {
  static const String boxName = 'notes';
  static const String notebookBoxName = 'notebooks';
  static const String taskBoxName = 'tasks';
  static const String courseBoxName = 'courses';
  static const String gradeBoxName = 'grades';
  static const String attendanceBoxName = 'attendance';
  static const String folderBoxName = 'folders';
  static const String preferencesBoxName = 'preferences';

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

    await Hive.openBox<Note>(boxName);
    await Hive.openBox<Notebook>(notebookBoxName);
    await Hive.openBox<Task>(taskBoxName);
    await Hive.openBox<Course>(courseBoxName);
    await Hive.openBox<Grade>(gradeBoxName);
    await Hive.openBox<Attendance>(attendanceBoxName);
    await Hive.openBox<Folder>(folderBoxName);
    await Hive.openBox<UserPreferences>(preferencesBoxName);
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

  // --- Notes ---
  List<Note> getAllNotes({String? notebookId}) {
    final notes = _box.values.toList();
    if (notebookId != null) {
      return notes.where((n) => n.notebookId == notebookId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Note> getNotesInFolder(String? folderId) {
    final notes = _box.values.toList();
    return notes
        .where((n) => n.notebookId == folderId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // --- Notebooks ---
  List<Notebook> getAllNotebooks() {
    return _notebookBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // --- Tasks ---
  List<Task> getAllTasks() {
    return _taskBox.values.toList()..sort(
      (a, b) =>
          (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()),
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
        .where((f) => f.parentId == parentId && f.type == type)
        .toList();
  }

  Future<void> saveFolder(Folder folder) async {
    await _folderBox.put(folder.id, folder);
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

  // --- Legacy/Existing ---
  Future<void> saveTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
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
