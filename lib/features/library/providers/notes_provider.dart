import 'package:flutter/material.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/models/folder_model.dart';

class NotesProvider with ChangeNotifier {
  final NotesRepository _localRepository;
  String? _currentFolderId;

  NotesProvider({NotesRepository? repository})
    : _localRepository = repository ?? NotesRepository();

  String? get currentFolderId => _currentFolderId;
  List<Note> get notes => _localRepository.getAllNotes();
  List<Note> get deletedNotes => _localRepository.getDeletedNotes();
  List<Folder> get deletedFolders => _localRepository.getDeletedFolders();

  void navigateToFolder(String? folderId) {
    _currentFolderId = folderId;
    notifyListeners();
  }

  Future<void> createFolder(String title) async {
    final folder = Folder.create(
      title: title,
      parentId: _currentFolderId,
      type: FolderType.notebook,
    );
    await _localRepository.saveFolder(folder);
    notifyListeners();
  }

  Future<void> renameFolder(Folder folder, String newTitle) async {
    folder.title = newTitle;
    await _localRepository.saveFolder(folder);
    notifyListeners();
  }

  Future<void> deleteFolder(String folderId) async {
    final folder = _localRepository.getFolder(folderId);
    if (folder != null) {
      folder.isDeleted = true;
      await _localRepository.saveFolder(folder);
      notifyListeners();
    }
  }

  Future<void> restoreFolder(String folderId) async {
    final folder = _localRepository.getFolder(folderId);
    if (folder != null) {
      folder.isDeleted = false;
      await _localRepository.saveFolder(folder);
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteFolder(String folderId) async {
    await _localRepository.deleteFolder(folderId);
    notifyListeners();
  }

  Future<void> moveFolder(Folder folder, String? newParentId) async {
    if (folder.id == newParentId) return;
    folder.parentId = newParentId;
    await _localRepository.saveFolder(folder);
    notifyListeners();
  }

  Future<Note> createNoteInCurrentFolder({
    String title = 'Untitled',
    String type = 'drawing',
  }) async {
    final note = Note.create(
      notebookId: _currentFolderId,
      title: title,
      type: type,
    );
    await _localRepository.saveNote(note);
    notifyListeners();
    return note;
  }

  Future<void> renameNote(Note note, String newTitle) async {
    note.title = newTitle;
    await _localRepository.saveNote(note);
    notifyListeners();
  }

  Future<void> moveNote(Note note, String? newFolderId) async {
    note.notebookId = newFolderId;
    await _localRepository.saveNote(note);
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    final note = _localRepository.getNote(noteId);
    if (note != null) {
      note.isDeleted = true;
      await _localRepository.saveNote(note);
      notifyListeners();
    }
  }

  Future<void> restoreNote(String noteId) async {
    final note = _localRepository.getNote(noteId);
    if (note != null) {
      note.isDeleted = false;
      await _localRepository.saveNote(note);
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteNote(String noteId) async {
    await _localRepository.deleteNote(noteId);
    notifyListeners();
  }

  Future<void> permanentlyDeleteAll() async {
    final notes = deletedNotes;
    final folders = deletedFolders;

    for (var n in notes) {
      await _localRepository.deleteNote(n.id);
    }
    for (var f in folders) {
      await _localRepository.deleteFolder(f.id);
    }
    notifyListeners();
  }
}
