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

class SupabaseRepository {
  final SupabaseClient _client;
  final NotesRepository _localRepository = NotesRepository();

  SupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Stream<List<Note>> notesStream() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          return data.map((e) {
            return Note.fromJson(e);
          }).toList();
        });
  }

  Future<void> syncAll() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
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
    } catch (e) {
      print('Global Sync Error: $e');
    }
  }

  // --- Notes Sync ---
  Future<void> syncNotes() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', user.id);
      final List remoteData = response as List;

      final Map<String, dynamic> remoteNotesMap = {
        for (var e in remoteData) e['id']: e,
      };

      // 1. Sync Remote to Local
      for (var e in remoteData) {
        final remoteNote = Note.fromJson(e);

        final localNote = _localRepository.getNote(remoteNote.id);
        if (localNote == null ||
            remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          // Use Hive's internal save to avoid setting updatedAt to 'now' again
          await Hive.box<Note>(
            NotesRepository.boxName,
          ).put(remoteNote.id, remoteNote);
        }
      }

      // 2. Sync Local to Remote
      final localNotes = _localRepository.getAllNotes();
      for (var note in localNotes) {
        final remoteData = remoteNotesMap[note.id];
        if (remoteData == null ||
            note.updatedAt.isAfter(DateTime.parse(remoteData['updated_at']))) {
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
  Future<void> syncCourses() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client
        .from('courses')
        .select()
        .eq('user_id', user.id);
    final List remoteData = response as List;

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
  Future<void> syncTasks() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client
        .from('tasks')
        .select()
        .eq('user_id', user.id);
    final List remoteData = response as List;

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
  Future<void> syncFolders() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('folders')
          .select()
          .eq('user_id', user.id);
      final List remoteData = response as List;

      final Map<String, dynamic> remoteFoldersMap = {
        for (var e in remoteData) e['id']: e,
      };

      // 1. Sync Remote to Local
      for (var e in remoteData) {
        final remoteFolder = Folder.fromJson(e);

        final localFolder = Hive.box<Folder>(
          NotesRepository.folderBoxName,
        ).get(remoteFolder.id);
        if (localFolder == null ||
            remoteFolder.updatedAt!.isAfter(localFolder.updatedAt!)) {
          await Hive.box<Folder>(
            NotesRepository.folderBoxName,
          ).put(remoteFolder.id, remoteFolder);
        }
      }

      // 2. Sync Local to Remote
      final notebookFolders = _localRepository.getFolders(
        type: FolderType.notebook,
      );
      final resourceFolders = _localRepository.getFolders(
        type: FolderType.resource,
      );
      final allFolders = [...notebookFolders, ...resourceFolders];

      for (var f in allFolders) {
        final remoteData = remoteFoldersMap[f.id];
        if (remoteData == null ||
            f.updatedAt!.isAfter(DateTime.parse(remoteData['updated_at']))) {
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

  // --- Academic Calendar Sync ---
  Future<void> syncCalendar() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Sync Periods
    final pResp = await _client
        .from('academic_periods')
        .select()
        .eq('user_id', user.id);
    for (var e in (pResp as List)) {
      final period = AcademicPeriod.fromJson(e);
      await _localRepository.savePeriod(period);
    }

    final localPeriods = _localRepository.getAllPeriods();
    for (var p in localPeriods) {
      await _client.from('academic_periods').upsert({
        ...p.toJson(),
        'user_id': user.id,
      });
    }

    // Sync Events
    final eResp = await _client
        .from('academic_events')
        .select()
        .eq('user_id', user.id);
    for (var e in (eResp as List)) {
      final event = AcademicEvent.fromJson(e);
      await _localRepository.saveEvent(event);
    }

    final localEvents = _localRepository.getAllEvents();
    for (var ev in localEvents) {
      await _client.from('academic_events').upsert({
        ...ev.toJson(),
        'user_id': user.id,
      });
    }
  }

  // --- Grades & Attendance Sync ---
  Future<void> syncGrades() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client
        .from('grades')
        .select()
        .eq('user_id', user.id);
    for (var e in (response as List)) {
      final grade = Grade.fromJson(e);
      await _localRepository.saveGrade(grade);
    }

    final courses = _localRepository.getAllCourses();
    for (var c in courses) {
      final localGrades = _localRepository.getGradesForCourse(c.id);
      for (var g in localGrades) {
        await _client.from('grades').upsert({
          ...g.toJson(),
          'user_id': user.id,
        });
      }
    }
  }

  Future<void> syncAttendance() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client
        .from('attendance')
        .select()
        .eq('user_id', user.id);
    for (var e in (response as List)) {
      final att = Attendance.fromJson(e);
      await _localRepository.saveAttendance(att);
    }

    final courses = _localRepository.getAllCourses();
    for (var c in courses) {
      final localAtt = _localRepository.getAttendanceForCourse(c.id);
      for (var a in localAtt) {
        await _client.from('attendance').upsert({
          ...a.toJson(),
          'user_id': user.id,
        });
      }
    }
  }

  // --- Profile Sync ---
  Future<void> syncProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client
        .from('student_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (response != null) {
      final profile = StudentProfile.fromJson(response);
      // Keep Supabase's full_name if available in metadata
      final fullName = user.userMetadata?['full_name'] as String?;
      if (fullName != null) profile.name = fullName;
      
      await _localRepository.saveStudentProfile(profile);
    }

    final localProfile = _localRepository.getStudentProfile();
    await _client.from('student_profiles').upsert({
      ...localProfile.toJson(),
      'user_id': user.id,
    });
  }

  Future<void> deleteNote(String noteId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('notes').delete().eq('id', noteId);
  }

  Future<bool> hasProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('student_profiles')
          .select('user_id') // Select minimal data to check existence
          .eq('user_id', user.id)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking profile existence: $e');
      return false;
    }
  }
}
