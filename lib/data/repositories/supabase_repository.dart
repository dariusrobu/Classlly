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
  final SupabaseClient _client = Supabase.instance.client;
  final NotesRepository _localRepository = NotesRepository();

  Stream<List<Note>> notesStream() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          return data.map((e) {
            final content = e['content'] as Map<String, dynamic>;
            return Note.fromJson({
              'id': e['id'],
              'title': e['title'],
              'created_at': e['created_at'],
              'updated_at': e['updated_at'],
              ...content,
            });
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
      final response =
          await _client.from('notes').select().eq('user_id', user.id);
      final List remoteData = response as List;

      final Map<String, dynamic> remoteNotesMap = {
        for (var e in remoteData) e['id']: e,
      };

      // 1. Sync Remote to Local
      for (var e in remoteData) {
        final content = e['content'] as Map<String, dynamic>;
        final remoteNote = Note.fromJson({
          'id': e['id'],
          'title': e['title'],
          'created_at': e['created_at'],
          'updated_at': e['updated_at'],
          ...content,
        });

        final localNote = _localRepository.getNote(remoteNote.id);
        if (localNote == null ||
            remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          // Use Hive's internal save to avoid setting updatedAt to 'now' again
          await Hive.box<Note>(NotesRepository.boxName).put(
            remoteNote.id,
            remoteNote,
          );
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
    final content = {
      'strokes': note.strokes.map((s) => s.toJson()).toList(),
      'textBlocks': note.textBlocks.map((t) => t.toJson()).toList(),
      'images': note.images.map((i) => i.toJson()).toList(),
      'audioPath': note.audioPath,
      'notebook_id': note.notebookId,
      'template_type': note.templateType,
      'tags': note.tags,
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

    final response =
        await _client.from('courses').select().eq('user_id', user.id);
    final List remoteData = response as List;

    for (var e in remoteData) {
      final course = Course(
        id: e['id'],
        title: e['title'],
        professor: e['professor'] ?? '',
        schedule: e['schedule'] ?? '',
        color: e['color'] ?? 0xFF7C3AED,
        iconCodePoint: e['icon_code'] ?? 0xe559,
        courseDay: e['course_day'] ?? '',
        courseTime: e['course_time'] ?? '',
      );
      await Hive.box<Course>(NotesRepository.courseBoxName).put(
        course.id,
        course,
      );
    }

    final localCourses = _localRepository.getAllCourses();
    for (var c in localCourses) {
      await _client.from('courses').upsert({
        'id': c.id,
        'user_id': user.id,
        'title': c.title,
        'professor': c.professor,
        'schedule': c.schedule,
        'color': c.color,
        'icon_code': c.iconCodePoint,
        'course_day': c.courseDay,
        'course_time': c.courseTime,
      });
    }
  }

  // --- Tasks Sync ---
  Future<void> syncTasks() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client.from('tasks').select().eq('user_id', user.id);
    final List remoteData = response as List;

    for (var e in remoteData) {
      final task = Task(
        id: e['id'],
        title: e['title'],
        description: e['description'] ?? '',
        dueDate: e['due_date'] != null ? DateTime.parse(e['due_date']) : null,
        isCompleted: e['is_completed'] ?? false,
        courseId: e['course_id'],
        priority: e['priority'] ?? 1,
        createdAt:
            e['created_at'] != null
                ? DateTime.parse(e['created_at'])
                : DateTime.now(),
      );
      await Hive.box<Task>(NotesRepository.taskBoxName).put(task.id, task);
    }

    final localTasks = _localRepository.getAllTasks();
    for (var t in localTasks) {
      await _client.from('tasks').upsert({
        'id': t.id,
        'user_id': user.id,
        'title': t.title,
        'description': t.description,
        'due_date': t.dueDate?.toIso8601String(),
        'is_completed': t.isCompleted,
        'course_id': t.courseId,
        'priority': t.priority,
        'created_at': t.createdAt.toIso8601String(),
      });
    }
  }

  // --- Folders Sync ---
  Future<void> syncFolders() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response =
          await _client.from('folders').select().eq('user_id', user.id);
      final List remoteData = response as List;

      final Map<String, dynamic> remoteFoldersMap = {
        for (var e in remoteData) e['id']: e,
      };

      // 1. Sync Remote to Local
      for (var e in remoteData) {
        final remoteFolder = Folder(
          id: e['id'],
          title: e['title'],
          parentId: e['parent_id'],
          type:
              e['type'] == 'resource' ? FolderType.resource : FolderType.notebook,
          createdAt:
              e['created_at'] != null
                  ? DateTime.parse(e['created_at'])
                  : DateTime.now(),
          updatedAt:
              e['updated_at'] != null
                  ? DateTime.parse(e['updated_at'])
                  : DateTime.now(),
        );

        final localFolder = Hive.box<Folder>(NotesRepository.folderBoxName).get(
          remoteFolder.id,
        );
        if (localFolder == null ||
            remoteFolder.updatedAt!.isAfter(localFolder.updatedAt!)) {
          await Hive.box<Folder>(NotesRepository.folderBoxName).put(
            remoteFolder.id,
            remoteFolder,
          );
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
            'id': f.id,
            'user_id': user.id,
            'title': f.title,
            'parent_id': f.parentId,
            'type': f.type == FolderType.resource ? 'resource' : 'notebook',
            'created_at': f.createdAt!.toIso8601String(),
            'updated_at': f.updatedAt!.toIso8601String(),
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
    final pResp = await _client.from('academic_periods').select().eq('user_id', user.id);
    for (var e in (pResp as List)) {
      final period = AcademicPeriod(
        id: e['id'],
        name: e['name'],
        startDate: DateTime.parse(e['start_date']),
        endDate: DateTime.parse(e['end_date']),
        type: AcademicPeriodType.values.firstWhere((t) => t.name == e['type']),
      );
      await _localRepository.savePeriod(period);
    }

    final localPeriods = _localRepository.getAllPeriods();
    for (var p in localPeriods) {
      await _client.from('academic_periods').upsert({
        'id': p.id,
        'user_id': user.id,
        'name': p.name,
        'start_date': p.startDate.toIso8601String(),
        'end_date': p.endDate.toIso8601String(),
        'type': p.type.name,
      });
    }

    // Sync Events
    final eResp = await _client.from('academic_events').select().eq('user_id', user.id);
    for (var e in (eResp as List)) {
      final event = AcademicEvent(
        id: e['id'],
        name: e['name'],
        date: DateTime.parse(e['date']),
        type: AcademicEventType.values.firstWhere((t) => t.name == e['type']),
      );
      await _localRepository.saveEvent(event);
    }

    final localEvents = _localRepository.getAllEvents();
    for (var ev in localEvents) {
      await _client.from('academic_events').upsert({
        'id': ev.id,
        'user_id': user.id,
        'name': ev.name,
        'date': ev.date.toIso8601String(),
        'type': ev.type.name,
      });
    }
  }

  // --- Grades & Attendance Sync ---
  Future<void> syncGrades() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client.from('grades').select().eq('user_id', user.id);
    for (var e in (response as List)) {
      final grade = Grade(
        id: e['id'],
        courseId: e['course_id'],
        title: e['title'],
        score: (e['score'] as num).toDouble(),
        maxScore: (e['max_score'] as num).toDouble(),
        date: DateTime.parse(e['date']),
        weight: (e['weight'] as num).toDouble(),
      );
      await _localRepository.saveGrade(grade);
    }

    final courses = _localRepository.getAllCourses();
    for (var c in courses) {
      final localGrades = _localRepository.getGradesForCourse(c.id);
      for (var g in localGrades) {
        await _client.from('grades').upsert({
          'id': g.id,
          'user_id': user.id,
          'course_id': g.courseId,
          'title': g.title,
          'score': g.score,
          'max_score': g.maxScore,
          'date': g.date.toIso8601String(),
          'weight': g.weight,
        });
      }
    }
  }

  Future<void> syncAttendance() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client.from('attendance').select().eq('user_id', user.id);
    for (var e in (response as List)) {
      final att = Attendance(
        id: e['id'],
        courseId: e['course_id'],
        date: DateTime.parse(e['date']),
        status: AttendanceStatus.values.firstWhere((s) => s.name == e['status']),
      );
      await _localRepository.saveAttendance(att);
    }

    final courses = _localRepository.getAllCourses();
    for (var c in courses) {
      final localAtt = _localRepository.getAttendanceForCourse(c.id);
      for (var a in localAtt) {
        await _client.from('attendance').upsert({
          'id': a.id,
          'user_id': user.id,
          'course_id': a.courseId,
          'date': a.date.toIso8601String(),
          'status': a.status.name,
        });
      }
    }
  }

  // --- Profile Sync ---
  Future<void> syncProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client.from('student_profiles').select().eq('user_id', user.id).maybeSingle();
    if (response != null) {
      final fullName = user.userMetadata?['full_name'] as String? ?? 'Alex';
      final profile = StudentProfile(
        name: fullName,
        university: response['university'] ?? '',
        major: response['major'] ?? '',
        year: response['year'] ?? '',
        studentId: response['student_id'] ?? '',
      );
      await _localRepository.saveStudentProfile(profile);
    }

    final localProfile = _localRepository.getStudentProfile();
    await _client.from('student_profiles').upsert({
      'user_id': user.id,
      'university': localProfile.university,
      'major': localProfile.major,
      'year': localProfile.year,
      'student_id': localProfile.studentId,
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
          .select('id') // Select minimal data to check existence
          .eq('user_id', user.id)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking profile existence: $e');
      return false;
    }
  }
}
