import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/folder_model.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';

class SupabaseCloudService implements CloudStorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final NotesRepository _localRepository = NotesRepository();

  @override
  Stream<List<Note>> notesStream() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          return data.map((e) => Note.fromJson(e)).toList();
        });
  }

  @override
  Future<void> syncAll() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final prefs = _localRepository.getPreferences();

      await Future.wait([
        syncNotes(),
        syncCourses(),
        syncTasks(),
        syncFolders(),
        syncCalendar(),
        syncGrades(),
        syncAttendance(),
        syncProfile(),
      ]);

      // Save sync time
      prefs.lastSyncTimestamp = DateTime.now();
      await _localRepository.savePreferences(prefs);
    } catch (e) {
      print('Supabase Sync Error: $e');
    }
  }

  // Helper to get sync filter
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applySyncFilter(
    String table,
    String userId,
  ) {
    final prefs = _localRepository.getPreferences();
    final query = _client.from(table).select().eq('user_id', userId);
    
    if (prefs.lastSyncTimestamp != null) {
      // Offset by 1 second to avoid overlapping due to precision
      final filterTime = prefs.lastSyncTimestamp!.subtract(const Duration(seconds: 1));
      return query.gt('updated_at', filterTime.toIso8601String());
    }
    return query;
  }

  // --- Notes Sync ---
  @override
  Future<void> syncNotes() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch Metadata for ALL notes to check for deletions or local updates
      final response = await _client
          .from('notes')
          .select('id, updated_at, title')
          .eq('user_id', user.id);
      final List remoteMetadataList = response as List;

      final Map<String, dynamic> remoteMetadataMap = {
        for (var e in remoteMetadataList) e['id']: e,
      };

      // 2. Download only CHANGED notes
      for (var meta in remoteMetadataList) {
        final String noteId = meta['id'];
        final DateTime remoteUpdatedAt = DateTime.parse(meta['updated_at']);
        final localNote = _localRepository.getNote(noteId);

        if (localNote == null || remoteUpdatedAt.isAfter(localNote.updatedAt)) {
          final fullNoteData = await _client
              .from('notes')
              .select()
              .eq('id', noteId)
              .single();
          
          final remoteNote = Note.fromJson(fullNoteData);
          await Hive.box<Note>(NotesRepository.boxName).put(remoteNote.id, remoteNote);
        }
      }

      // 3. Sync Local to Remote
      final localNotes = _localRepository.getAllNotes();
      for (var note in localNotes) {
        final remoteMeta = remoteMetadataMap[note.id];
        if (remoteMeta == null ||
            note.updatedAt.isAfter(DateTime.parse(remoteMeta['updated_at']))) {
          await _upsertNote(note, user.id);
        }
      }
    } catch (e) {
      print('Notes Sync Error: $e');
    }
  }

  Future<void> _upsertNote(Note note, String userId) async {
    final json = note.toJson();
    final content = {
      'strokes': json['strokes'],
      'textBlocks': json['textBlocks'],
      'images': json['images'],
      'audioPath': json['audioPath'],
      'notebook_id': json['notebook_id'],
      'template_type': json['template_type'],
      'tags': json['tags'],
      'is_deleted': json['is_deleted'],
      'type': json['type'],
    };

    await _client.from('notes').upsert({
      'id': note.id,
      'user_id': userId,
      'title': note.title,
      'content': content,
      'updated_at': note.updatedAt.toIso8601String(),
      'created_at': note.createdAt.toIso8601String(),
    });
  }

  // --- Courses Sync ---
  @override
  Future<void> syncCourses() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final remoteData = await _applySyncFilter('courses', user.id);

    for (var e in remoteData) {
      final course = Course.fromJson(e);
      await Hive.box<Course>(
        NotesRepository.courseBoxName,
      ).put(course.id, course);
    }

    final localCourses = _localRepository.getAllCourses();
    for (var c in localCourses) {
      await _client.from('courses').upsert({
        ...c.toJson(),
        'user_id': user.id,
      });
    }
  }

  // --- Tasks Sync ---
  @override
  Future<void> syncTasks() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final remoteData = await _applySyncFilter('tasks', user.id);

    for (var e in remoteData) {
      final task = Task.fromJson(e);
      await Hive.box<Task>(NotesRepository.taskBoxName).put(task.id, task);
    }

    final localTasks = _localRepository.getAllTasks();
    for (var t in localTasks) {
      await _client.from('tasks').upsert({
        ...t.toJson(),
        'user_id': user.id,
      });
    }
  }

  // --- Folders Sync ---
  @override
  Future<void> syncFolders() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final remoteData = await _applySyncFilter('folders', user.id);
      final Map<String, dynamic> remoteFoldersMap = {for (var e in remoteData) e['id']: e};

      for (var e in remoteData) {
        final remoteFolder = Folder.fromJson(e);
        final localFolder = Hive.box<Folder>(NotesRepository.folderBoxName).get(remoteFolder.id);
        if (localFolder == null || remoteFolder.updatedAt!.isAfter(localFolder.updatedAt!)) {
          await Hive.box<Folder>(NotesRepository.folderBoxName).put(remoteFolder.id, remoteFolder);
        }
      }

      final notebookFolders = _localRepository.getFolders(type: FolderType.notebook);
      final resourceFolders = _localRepository.getFolders(type: FolderType.resource);
      final allFolders = [...notebookFolders, ...resourceFolders];

      for (var f in allFolders) {
        final remoteData = remoteFoldersMap[f.id];
        if (remoteData == null || f.updatedAt!.isAfter(DateTime.parse(remoteData['updated_at']))) {
          await _client.from('folders').upsert({
            ...f.toJson(),
            'user_id': user.id,
          });
        }
      }
    } catch (e) {
      print('Folders Sync Error: $e');
    }
  }

  @override
  Future<void> syncCalendar() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final pResp = await _applySyncFilter('academic_periods', user.id);
    for (var e in pResp) {
      await _localRepository.savePeriod(AcademicPeriod.fromJson(e));
    }

    final localPeriods = _localRepository.getAllPeriods();
    for (var p in localPeriods) {
      await _client.from('academic_periods').upsert({...p.toJson(), 'user_id': user.id});
    }

    final eResp = await _applySyncFilter('academic_events', user.id);
    for (var e in eResp) {
      await _localRepository.saveEvent(AcademicEvent.fromJson(e));
    }

    final localEvents = _localRepository.getAllEvents();
    for (var ev in localEvents) {
      await _client.from('academic_events').upsert({...ev.toJson(), 'user_id': user.id});
    }
  }

  @override
  Future<void> syncGrades() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final remoteData = await _applySyncFilter('grades', user.id);
    for (var e in remoteData) {
      await _localRepository.saveGrade(Grade.fromJson(e));
    }

    final courses = _localRepository.getAllCourses();
    for (var c in courses) {
      final localGrades = _localRepository.getGradesForCourse(c.id);
      for (var g in localGrades) {
        await _client.from('grades').upsert({...g.toJson(), 'user_id': user.id});
      }
    }
  }

  @override
  Future<void> syncAttendance() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final remoteData = await _applySyncFilter('attendance', user.id);
    for (var e in remoteData) {
      await _localRepository.saveAttendance(Attendance.fromJson(e));
    }

    final courses = _localRepository.getAllCourses();
    for (var c in courses) {
      final localAtt = _localRepository.getAttendanceForCourse(c.id);
      for (var a in localAtt) {
        await _client.from('attendance').upsert({...a.toJson(), 'user_id': user.id});
      }
    }
  }

  @override
  Future<void> syncProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final remoteData = await _applySyncFilter('student_profiles', user.id);
    if (remoteData.isNotEmpty) {
      final response = remoteData.first;
      final profile = StudentProfile.fromJson(response);
      final fullName = user.userMetadata?['full_name'] as String?;
      if (fullName != null) profile.name = fullName;
      await _localRepository.saveStudentProfile(profile);
    }

    final localProfile = _localRepository.getStudentProfile();
    await _client.from('student_profiles').upsert({...localProfile.toJson(), 'user_id': user.id});
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('notes').delete().eq('id', noteId);
  }

  @override
  Future<bool> hasProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      final response = await _client.from('student_profiles').select('user_id').eq('user_id', user.id).maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}
