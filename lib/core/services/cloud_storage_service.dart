import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/student_profile_model.dart';

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
