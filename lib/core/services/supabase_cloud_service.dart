import 'dart:async';
import 'dart:convert';
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

// Top-level function for Dart Isolate (must be outside the class)
List<Note> parseNotesIsolate(List<Map<String, dynamic>> notesData) {
  return notesData.map((data) => Note.fromJson(data)).toList();
}

/// Supabase implementation of [CloudStorageService].
///
/// Uses a single `data JSONB` column per table, keyed by [id] and [user_id].
/// This makes schema changes trivial — just update toJson/fromJson on the model.
class SupabaseCloudService implements CloudStorageService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  static final _remoteUpdatesController = StreamController<void>.broadcast();

  // ──────────────────────────────────────────────────────────
  // Stream & Realtime
  // ──────────────────────────────────────────────────────────

  @override
  Stream<List<Note>> notesStream() => const Stream.empty();

  @override
  Stream<void> get remoteUpdates => _remoteUpdatesController.stream;

  static RealtimeChannel? _syncChannel;

  /// Starts listening to the sync_store table for changes made by other devices.
  void initRealtime() {
    final uid = _userId;
    if (uid == null) return;

    if (_syncChannel != null) return; // Already listening

    _syncChannel = _client.channel('public:sync_store').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sync_store',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: uid,
      ),
      callback: (PostgresChangePayload payload) async {
        await _handleRealtimePayload(payload);
      },
    ).subscribe();
  }

  Future<void> _handleRealtimePayload(PostgresChangePayload payload) async {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final oldRecord = payload.oldRecord;
        final id = oldRecord['id'] as String?;
        final collection = oldRecord['collection'] as String?;
        if (id != null && collection != null) {
          _deleteFromHive(collection, id);
        }
      } else {
        final newRecord = payload.newRecord;
        final collection = newRecord['collection'] as String?;
        final rawData = newRecord['data'];
        if (collection != null && rawData != null) {
          await _upsertToHive(collection, rawData);
        }
      }
      // Notify UI that a background sync arrived
      _remoteUpdatesController.add(null);
    } catch (e) {
      debugPrint('SUPABASE_REALTIME payload error: $e');
    }
  }

  void _deleteFromHive(String collection, String id) {
    switch (collection) {
      case 'tasks': Hive.box<Task>(NotesRepository.taskBoxName).delete(id); break;
      case 'courses': Hive.box<Course>(NotesRepository.courseBoxName).delete(id); break;
      case 'notes': Hive.box<Note>(NotesRepository.boxName).delete(id); break;
      case 'folders': Hive.box<Folder>(NotesRepository.folderBoxName).delete(id); break;
      case 'grades': Hive.box<Grade>(NotesRepository.gradeBoxName).delete(id); break;
      case 'attendance': Hive.box<Attendance>(NotesRepository.attendanceBoxName).delete(id); break;
    }
  }

  Future<void> _upsertToHive(String collection, dynamic rawData) async {
    final Map<String, dynamic> dataMap;
    if (rawData is String) {
      dataMap = jsonDecode(rawData) as Map<String, dynamic>;
    } else {
      dataMap = Map<String, dynamic>.from(rawData as Map);
    }

    final repo = NotesRepository();
    switch (collection) {
      case 'tasks': await repo.saveTask(Task.fromJson(dataMap)); break;
      case 'courses': await repo.saveCourse(Course.fromJson(dataMap)); break;
      case 'notes': 
        final incomingNote = Note.fromJson(dataMap);
        final localBox = Hive.box<Note>(NotesRepository.boxName);
        final existingNote = localBox.get(incomingNote.id);

        if (existingNote != null) {
          // SMART MERGE: Conflict Resolution
          // If the note exists locally, we merge strokes and text blocks using timestamps
          // to ensure offline edits made on THIS device aren't wiped out by an incoming sync.
          
          // 1. Merge Strokes
          final Map<int, Stroke> strokeMap = {};
          for (var s in existingNote.strokes) { strokeMap[s.createdAt] = s; }
          for (var s in incomingNote.strokes) { strokeMap[s.createdAt] = s; }
          final mergedStrokes = strokeMap.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // 2. Merge Text Blocks
          final Map<int, TextBlock> textMap = {};
          for (var t in existingNote.textBlocks) { textMap[t.createdAt] = t; }
          for (var t in incomingNote.textBlocks) { textMap[t.createdAt] = t; }
          final mergedTextBlocks = textMap.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          // 3. Apply merged lists to incoming note (which holds newest metadata like title)
          incomingNote.strokes.clear();
          incomingNote.strokes.addAll(mergedStrokes);
          
          incomingNote.textBlocks.clear();
          incomingNote.textBlocks.addAll(mergedTextBlocks);
        }
        
        await repo.saveNote(incomingNote); 
        break;
      case 'profiles': await repo.saveStudentProfile(StudentProfile.fromJson(dataMap)); break;
      case 'folders': await repo.saveFolder(Folder.fromJson(dataMap)); break;
      case 'grades': await repo.saveGrade(Grade.fromJson(dataMap)); break;
      case 'attendance': await repo.saveAttendance(Attendance.fromJson(dataMap)); break;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Upload — push local Hive data → Supabase
  // ──────────────────────────────────────────────────────────

  @override
  Future<void> syncAll({bool interactive = false}) async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('SUPABASE_SYNC: No user logged in. Skipping sync.');
      return;
    }
    
    debugPrint('SUPABASE_SYNC: Starting syncAll for user $uid');
    await Future.wait([
      syncProfile(),
      syncCourses(),
      syncTasks(),
      syncNotes(),
      syncFolders(),
      syncGrades(),
      syncAttendance(),
    ]);
    debugPrint('SUPABASE_SYNC: syncAll completed.');
  }

  @override
  Future<void> syncCourses() async {
    await _syncGeneric<Course>(NotesRepository.courseBoxName, 'courses');
  }

  @override
  Future<void> syncTasks() async {
    await _syncGeneric<Task>(NotesRepository.taskBoxName, 'tasks');
  }

  @override
  Future<void> syncNotes() async {
    await _syncGeneric<Note>(NotesRepository.boxName, 'notes');
  }

  @override
  Future<void> syncFolders() async {
    await _syncGeneric<Folder>(NotesRepository.folderBoxName, 'folders');
  }

  @override
  Future<void> syncGrades() async {
    await _syncGeneric<Grade>(NotesRepository.gradeBoxName, 'grades');
  }

  @override
  Future<void> syncAttendance() async {
    await _syncGeneric<Attendance>(NotesRepository.attendanceBoxName, 'attendance');
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
      await _client.from('sync_store').upsert({
        'id': 'profile',
        'user_id': uid,
        'collection': 'profiles',
        'data': profile.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('SUPABASE_DEBUG: syncProfile error: $e');
    }
  }

  Future<void> _syncGeneric<T extends HiveObject>(String boxName, String collection) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final box = Hive.box<T>(boxName);
      final rows = box.values.map((item) {
        final json = (item as dynamic).toJson();
        final id = (item as dynamic).id as String;
        return {
          'id': id,
          'user_id': uid,
          'collection': collection,
          'data': json,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();
      
      if (rows.isEmpty) {
        debugPrint('SUPABASE_DEBUG: No $collection to sync.');
        return;
      }
      debugPrint('SUPABASE_DEBUG: Syncing ${rows.length} $collection...');
      await _client.from('sync_store').upsert(rows);
    } catch (e) {
      debugPrint('SUPABASE_DEBUG: syncGeneric $collection error: $e');
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
    debugPrint('SUPABASE_RESTORE: Starting restoreAll for user $uid');

    try {
      final rows = await _client.from('sync_store').select('id, collection, data').eq('user_id', uid);
      
      final Map<String, List<Map<String, dynamic>>> groupedData = {
        'profiles': [],
        'courses': [],
        'tasks': [],
        'notes': [],
        'folders': [],
        'grades': [],
        'attendance': [],
      };

      for (var row in rows) {
        final collection = row['collection'] as String;
        final rawData = row['data'];
        final Map<String, dynamic> dataMap;
        if (rawData is String) {
          dataMap = jsonDecode(rawData) as Map<String, dynamic>;
        } else {
          dataMap = Map<String, dynamic>.from(rawData as Map);
        }
        
        if (groupedData.containsKey(collection)) {
          groupedData[collection]!.add(dataMap);
        }
      }

      onProgress?.call('Restoring profiles...', 0.1);
      final repo = NotesRepository();
      for (var data in groupedData['profiles']!) {
        await repo.saveStudentProfile(StudentProfile.fromJson(data));
      }

      onProgress?.call('Restoring courses...', 0.25);
      for (var data in groupedData['courses']!) {
        await repo.saveCourse(Course.fromJson(data));
      }

      onProgress?.call('Restoring tasks...', 0.40);
      for (var data in groupedData['tasks']!) {
        await repo.saveTask(Task.fromJson(data));
      }

      onProgress?.call('Restoring folders...', 0.55);
      for (var data in groupedData['folders']!) {
        await repo.saveFolder(Folder.fromJson(data));
      }

      onProgress?.call('Restoring notes...', 0.70);
      // Offload heavy JSON parsing (especially thousands of drawing strokes) to a Background Isolate
      // This prevents the UI from freezing entirely during a cold start hydration.
      final notesData = groupedData['notes']!;
      if (notesData.isNotEmpty) {
        final parsedNotes = await compute(parseNotesIsolate, notesData);
        for (var note in parsedNotes) {
          await repo.saveNote(note);
        }
      }

      onProgress?.call('Restoring grades...', 0.85);
      for (var data in groupedData['grades']!) {
        await repo.saveGrade(Grade.fromJson(data));
      }

      onProgress?.call('Restoring attendance…', 0.95);
      for (var data in groupedData['attendance']!) {
        await repo.saveAttendance(Attendance.fromJson(data));
      }

      onProgress?.call('Done', 1.0);
      debugPrint('SUPABASE_RESTORE: restoreAll completed.');
    } catch (e) {
      debugPrint('SUPABASE_RESTORE error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // Helper / Delete
  // ──────────────────────────────────────────────────────────

  @override
  Future<bool> verifyConnection() async {
    final uid = _userId;
    if (uid == null) return false;
    
    // JWT Service Role Check for BYOC security
    final session = _client.auth.currentSession;
    if (session != null) {
      try {
        final payloadChunks = session.accessToken.split('.');
        if (payloadChunks.length == 3) {
          final payloadBytes = base64Url.normalize(payloadChunks[1]);
          final payloadString = utf8.decode(base64Url.decode(payloadBytes));
          final payloadData = jsonDecode(payloadString);
          if (payloadData['role'] == 'service_role') {
            debugPrint('SUPABASE_SECURITY_RISK: service_role key provided instead of anon key.');
            return false;
          }
        }
      } catch (e) {
        debugPrint('verifyConnection JWT check error: $e');
      }
    }

    try {
      // Setup health_check
      final healthId = 'health_ping_${DateTime.now().millisecondsSinceEpoch}';
      
      // Attempt Write
      await _client.from('sync_store').upsert({
        'id': healthId,
        'user_id': uid,
        'collection': 'health_check',
        'data': {'ping': true},
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Attempt Read
      final result = await _client
        .from('sync_store')
        .select('id')
        .eq('id', healthId)
        .eq('user_id', uid)
        .eq('collection', 'health_check')
        .limit(1);
        
      if ((result as List).isEmpty) return false;
      
      // Cleanup
      await _client.from('sync_store').delete().eq('id', healthId).eq('collection', 'health_check');
      
      return true;
    } catch (e) {
      // RLS or schema is improperly configured
      debugPrint('SUPABASE_HANDSHAKE_ERROR: $e');
      return false;
    }
  }

  @override
  Future<bool> hasProfile() async {
    try {
      final uid = _userId;
      if (uid == null) return false;
      final response = await _client
          .from('sync_store')
          .select('id')
          .eq('user_id', uid)
          .eq('collection', 'profiles')
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
          .from('sync_store')
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
      await _client.from('sync_store').delete().eq('id', noteId).eq('collection', 'notes');
    } catch (e) {
      debugPrint('deleteNote error: $e');
    }
  }

  @override
  Future<void> deleteUserContent() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _client.from('sync_store').delete().eq('user_id', uid);
    } catch (e) {
      debugPrint('deleteUserContent error: $e');
    }
  }
}
