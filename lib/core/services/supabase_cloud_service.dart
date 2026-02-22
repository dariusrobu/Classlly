import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of [CloudStorageService].
///
/// Uses a single `data JSONB` column per table, keyed by [id] and [user_id].
/// This makes schema changes trivial — just update toJson/fromJson on the model.
class SupabaseCloudService implements CloudStorageService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  // ──────────────────────────────────────────────────────────
  // Stream (placeholder — Realtime not yet wired)
  // ──────────────────────────────────────────────────────────

  @override
  Stream<List<Note>> notesStream() => const Stream.empty();

  // ──────────────────────────────────────────────────────────
  // Upload — push local Hive data → Supabase
  // ──────────────────────────────────────────────────────────

  @override
  Future<void> syncAll({bool interactive = false}) async {
    if (_userId == null) return;
    await Future.wait([
      syncProfile(),
      syncCourses(),
      syncTasks(),
      syncNotes(),
      syncFolders(),
      syncGrades(),
      syncAttendance(),
    ]);
  }

  @override
  Future<void> syncCourses() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final box = Hive.box<Course>(NotesRepository.courseBoxName);
      final rows = box.values.map((c) => {
        'id': c.id,
        'user_id': uid,
        'data': c.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      if (rows.isEmpty) return;
      await _client.from('courses').upsert(rows, onConflict: 'id');
    } catch (e) {
      debugPrint('syncCourses error: $e');
    }
  }

  @override
  Future<void> syncTasks() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final box = Hive.box<Task>(NotesRepository.taskBoxName);
      final rows = box.values.map((t) => {
        'id': t.id,
        'user_id': uid,
        'data': t.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      if (rows.isEmpty) return;
      await _client.from('tasks').upsert(rows, onConflict: 'id');
    } catch (e) {
      debugPrint('syncTasks error: $e');
    }
  }

  @override
  Future<void> syncNotes() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final box = Hive.box<Note>(NotesRepository.boxName);
      final rows = box.values.map((n) => {
        'id': n.id,
        'user_id': uid,
        'data': n.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      if (rows.isEmpty) return;
      await _client.from('notes').upsert(rows, onConflict: 'id');
    } catch (e) {
      debugPrint('syncNotes error: $e');
    }
  }

  @override
  Future<void> syncFolders() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final box = Hive.box<Folder>(NotesRepository.folderBoxName);
      final rows = box.values.map((f) => {
        'id': f.id,
        'user_id': uid,
        'data': f.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      if (rows.isEmpty) return;
      await _client.from('folders').upsert(rows, onConflict: 'id');
    } catch (e) {
      debugPrint('syncFolders error: $e');
    }
  }

  @override
  Future<void> syncGrades() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final box = Hive.box<Grade>(NotesRepository.gradeBoxName);
      final rows = box.values.map((g) => {
        'id': g.id,
        'user_id': uid,
        'data': g.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      if (rows.isEmpty) return;
      await _client.from('grades').upsert(rows, onConflict: 'id');
    } catch (e) {
      debugPrint('syncGrades error: $e');
    }
  }

  @override
  Future<void> syncAttendance() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final box = Hive.box<Attendance>(NotesRepository.attendanceBoxName);
      final rows = box.values.map((a) => {
        'id': a.id,
        'user_id': uid,
        'data': a.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      if (rows.isEmpty) return;
      await _client.from('attendance').upsert(rows, onConflict: 'id');
    } catch (e) {
      debugPrint('syncAttendance error: $e');
    }
  }

  @override
  Future<void> syncCalendar() async {
    // Calendar events come from an external API (academic calendar),
    // so they don't need to be backed up to Supabase.
  }

  @override
  Future<void> syncProfile() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final repo = NotesRepository();
      final profile = repo.getStudentProfile();
      await _client.from('profiles').upsert({
        'user_id': uid,
        'data': profile.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('syncProfile error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // Restore — pull Supabase data → Hive
  // ──────────────────────────────────────────────────────────

  /// Fetches all user data from Supabase and writes it into Hive.
  /// Called once after login to restore from cloud backup.
  Future<void> restoreAll({
    void Function(String step, double progress)? onProgress,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final repo = NotesRepository();

    onProgress?.call('Restoring profile…', 0.05);
    await _restoreProfile(uid, repo);

    onProgress?.call('Restoring courses…', 0.20);
    await _restoreCourses(uid, repo);

    onProgress?.call('Restoring tasks…', 0.40);
    await _restoreTasks(uid, repo);

    onProgress?.call('Restoring notes…', 0.55);
    await _restoreNotes(uid, repo);

    onProgress?.call('Restoring folders…', 0.65);
    await _restoreFolders(uid, repo);

    onProgress?.call('Restoring grades…', 0.78);
    await _restoreGrades(uid, repo);

    onProgress?.call('Restoring attendance…', 0.90);
    await _restoreAttendance(uid, repo);

    onProgress?.call('Done', 1.0);
  }

  Future<void> _restoreProfile(String uid, NotesRepository repo) async {
    try {
      final row = await _client
          .from('profiles')
          .select('data')
          .eq('user_id', uid)
          .maybeSingle();
      if (row != null && row['data'] != null) {
        final profile = StudentProfile.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        await repo.saveStudentProfile(profile);
      }
    } catch (e) {
      debugPrint('_restoreProfile error: $e');
    }
  }

  Future<void> _restoreCourses(String uid, NotesRepository repo) async {
    try {
      final rows = await _client
          .from('courses')
          .select('data')
          .eq('user_id', uid);
      for (final row in rows) {
        final course = Course.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        await repo.saveCourse(course);
      }
    } catch (e) {
      debugPrint('_restoreCourses error: $e');
    }
  }

  Future<void> _restoreTasks(String uid, NotesRepository repo) async {
    try {
      final rows = await _client
          .from('tasks')
          .select('data')
          .eq('user_id', uid);
      for (final row in rows) {
        final task = Task.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        await repo.saveTask(task);
      }
    } catch (e) {
      debugPrint('_restoreTasks error: $e');
    }
  }

  Future<void> _restoreNotes(String uid, NotesRepository repo) async {
    try {
      final rows = await _client
          .from('notes')
          .select('data')
          .eq('user_id', uid);
      for (final row in rows) {
        final note = Note.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        await repo.saveNote(note);
      }
    } catch (e) {
      debugPrint('_restoreNotes error: $e');
    }
  }

  Future<void> _restoreFolders(String uid, NotesRepository repo) async {
    try {
      final rows = await _client
          .from('folders')
          .select('data')
          .eq('user_id', uid);
      for (final row in rows) {
        final folder = Folder.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        await repo.saveFolder(folder);
      }
    } catch (e) {
      debugPrint('_restoreFolders error: $e');
    }
  }

  Future<void> _restoreGrades(String uid, NotesRepository repo) async {
    try {
      final rows = await _client
          .from('grades')
          .select('data')
          .eq('user_id', uid);
      for (final row in rows) {
        final grade = Grade.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        await repo.saveGrade(grade);
      }
    } catch (e) {
      debugPrint('_restoreGrades error: $e');
    }
  }

  Future<void> _restoreAttendance(String uid, NotesRepository repo) async {
    try {
      final rows = await _client
          .from('attendance')
          .select('data')
          .eq('user_id', uid);
      for (final row in rows) {
        final attendance = Attendance.fromJson(
          Map<String, dynamic>.from(row['data'] as Map),
        );
        await repo.saveAttendance(attendance);
      }
    } catch (e) {
      debugPrint('_restoreAttendance error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // Helper / Delete
  // ──────────────────────────────────────────────────────────

  @override
  Future<bool> hasProfile() async {
    try {
      final uid = _userId;
      if (uid == null) return false;
      final response = await _client
          .from('profiles')
          .select('user_id')
          .eq('user_id', uid)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Returns true if the user has any data backed up in Supabase.
  Future<bool> hasCloudData() async {
    try {
      final uid = _userId;
      if (uid == null) return false;
      final result = await _client
          .from('courses')
          .select('id')
          .eq('user_id', uid)
          .limit(1);
      return (result as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      await _client.from('notes').delete().eq('id', noteId);
    } catch (e) {
      debugPrint('deleteNote error: $e');
    }
  }

  @override
  Future<void> deleteUserContent() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await Future.wait([
        _client.from('notes').delete().eq('user_id', uid),
        _client.from('courses').delete().eq('user_id', uid),
        _client.from('tasks').delete().eq('user_id', uid),
        _client.from('folders').delete().eq('user_id', uid),
        _client.from('grades').delete().eq('user_id', uid),
        _client.from('attendance').delete().eq('user_id', uid),
        _client.from('profiles').delete().eq('user_id', uid),
      ]);
    } catch (e) {
      debugPrint('deleteUserContent error: $e');
    }
  }
}
