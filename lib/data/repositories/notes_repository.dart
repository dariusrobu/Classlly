import 'package:hive/hive.dart';
import 'package:classlly/data/models/note_models.dart';

class NotesRepository {

  static const String boxName = 'notes';

  static const String notebookBoxName = 'notebooks';



  static Future<void> init() async {

    Hive.registerAdapter(StrokePointAdapter());

    Hive.registerAdapter(StrokeAdapter());

    Hive.registerAdapter(TextBlockAdapter());

    Hive.registerAdapter(NoteAdapter());

    Hive.registerAdapter(NotebookAdapter());

    await Hive.openBox<Note>(boxName);

    await Hive.openBox<Notebook>(notebookBoxName);

  }



  Box<Note> get _box => Hive.box<Note>(boxName);

  Box<Notebook> get _notebookBox => Hive.box<Notebook>(notebookBoxName);



  List<Note> getAllNotes({String? notebookId}) {

    final notes = _box.values.toList();

    if (notebookId != null) {

      return notes.where((n) => n.notebookId == notebookId).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    }

    return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  }



  List<Notebook> getAllNotebooks() {

    return _notebookBox.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  }



  Future<void> saveNotebook(Notebook notebook) async {

    notebook.updatedAt = DateTime.now();

    await _notebookBox.put(notebook.id, notebook);

  }



  Future<void> deleteNotebook(String id) async {

    await _notebookBox.delete(id);

    // Optional: Cascade delete notes or set notebookId to null

  }



  Future<void> saveNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _box.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  Note? getNote(String id) {
    return _box.get(id);
  }
}
