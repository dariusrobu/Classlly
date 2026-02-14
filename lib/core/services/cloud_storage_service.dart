import 'package:classlly/data/models/note_models.dart';

abstract class CloudStorageService {
  // Sync Status
  Stream<List<Note>> notesStream();

  /// Syncs all data types (notes, courses, tasks, etc.)
  ///
  /// [interactive] determines oif the user should be prompted for authentication
  /// if not currently signed in.
  Future<void> syncAll({bool interactive = false});

  // Domain Specific Sync Methods
  Future<void> syncNotes();
  Future<void> syncCourses();
  Future<void> syncTasks();
  Future<void> syncFolders();
  Future<void> syncCalendar();
  Future<void> syncGrades();
  Future<void> syncAttendance();
  Future<void> syncProfile();

  // Helper Methods
  Future<bool> hasProfile();
  Future<void> deleteNote(String noteId);
  Future<void> deleteUserContent();
}
