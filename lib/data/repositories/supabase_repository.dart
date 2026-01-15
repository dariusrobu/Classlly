import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/data/models/note_models.dart';
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

  Future<void> syncNotes() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', user.id);

      final remoteNotes = (response as List).map((e) {
        final content = e['content'] as Map<String, dynamic>;
        return Note.fromJson({
          'id': e['id'],
          'title': e['title'],
          'created_at': e['created_at'],
          'updated_at': e['updated_at'],
          ...content,
        });
      }).toList();

      for (var remoteNote in remoteNotes) {
        final localNote = _localRepository.getNote(remoteNote.id);
        if (localNote == null ||
            remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          await _localRepository.saveNote(remoteNote);
        }
      }

      final localNotes = _localRepository.getAllNotes();
      for (var localNote in localNotes) {
        await _upsertNote(localNote, user.id);
      }
    } catch (e) {
      print('Sync Error: $e');
    }
  }

  Future<void> _upsertNote(Note note, String userId) async {
    final content = {
      'strokes': note.strokes.map((s) => s.toJson()).toList(),
      'textBlocks': note.textBlocks.map((t) => t.toJson()).toList(),
      'audioPath': note.audioPath,
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

  Future<void> deleteNote(String noteId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('notes').delete().eq('id', noteId);
  }
}
