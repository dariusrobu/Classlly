import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of [CloudStorageService].
///
/// This is a stub implementation — each sync method is a no-op placeholder
/// that you can build out as you set up your Supabase database tables.
class SupabaseCloudService implements CloudStorageService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<List<Note>> notesStream() {
    // TODO: Implement real-time notes stream using Supabase Realtime
    // Example:
    // return _client.from('notes').stream(primaryKey: ['id']).map(...)
    return const Stream.empty();
  }

  @override
  Future<void> syncAll({bool interactive = false}) async {
    await syncProfile();
    await syncNotes();
    await syncCourses();
    await syncTasks();
    await syncFolders();
    await syncCalendar();
    await syncGrades();
    await syncAttendance();
  }

  @override
  Future<void> syncNotes() async {
    // TODO: Implement notes sync with Supabase 'notes' table
  }

  @override
  Future<void> syncCourses() async {
    // TODO: Implement courses sync with Supabase 'courses' table
  }

  @override
  Future<void> syncTasks() async {
    // TODO: Implement tasks sync with Supabase 'tasks' table
  }

  @override
  Future<void> syncFolders() async {
    // TODO: Implement folders sync with Supabase 'folders' table
  }

  @override
  Future<void> syncCalendar() async {
    // TODO: Implement calendar sync with Supabase 'calendar' table
  }

  @override
  Future<void> syncGrades() async {
    // TODO: Implement grades sync with Supabase 'grades' table
  }

  @override
  Future<void> syncAttendance() async {
    // TODO: Implement attendance sync with Supabase 'attendance' table
  }

  @override
  Future<void> syncProfile() async {
    // TODO: Implement profile sync with Supabase 'profiles' table
    // Example:
    // final user = _client.auth.currentUser;
    // if (user == null) return;
    // await _client.from('profiles').upsert({...});
  }

  @override
  Future<bool> hasProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      // Table might not exist yet — treat as no profile
      return false;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    // TODO: Implement note deletion from Supabase
    // Example:
    // await _client.from('notes').delete().eq('id', noteId);
  }

  @override
  Future<void> deleteUserContent() async {
    // TODO: Implement user content deletion from Supabase
    // This should delete all user data from all tables
    // Example:
    // final userId = _client.auth.currentUser?.id;
    // if (userId == null) return;
    // await _client.from('notes').delete().eq('user_id', userId);
    // await _client.from('profiles').delete().eq('user_id', userId);
    // ... etc for all tables
  }
}
