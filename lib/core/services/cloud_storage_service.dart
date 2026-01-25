import 'package:classlly/data/models/note_models.dart';

abstract class CloudStorageService {
  // Sync Status
  Stream<List<Note>> notesStream();
  
  // High-level Sync
  Future<void> syncAll();
  
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
}
