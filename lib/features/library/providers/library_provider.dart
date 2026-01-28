import 'dart:async';
import 'package:flutter/material.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/task_model.dart';

enum LibraryView { dashboard, allNotes, courses, tasks, calendar, archive }

class LibraryProvider with ChangeNotifier {
  final CloudStorageService _cloudService;
  final NotesRepository _localRepository = NotesRepository();
  StreamSubscription? _syncSubscription;

  LibraryProvider({CloudStorageService? cloudService})
    : _cloudService = cloudService ?? SupabaseCloudService();

  LibraryView _currentView = LibraryView.dashboard;
  String _searchQuery = '';
  String? _selectedTag;
  DateTime? _lastSynced;

  LibraryView get currentView => _currentView;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  DateTime? get lastSynced => _lastSynced;

  void initSync() async {
    final prefs = _localRepository.getPreferences();
    final lastSync = prefs.lastSyncTimestamp;

    // Only sync if >15 minutes since last sync to reduce egress
    final shouldSync =
        lastSync == null || DateTime.now().difference(lastSync).inMinutes > 15;

    if (shouldSync) {
      await _cloudService.syncAll();
      _lastSynced = DateTime.now();
      notifyListeners();
    } else {
      _lastSynced = lastSync;
    }

    // Note: Realtime stream disabled to reduce egress.
    // Re-enable when implementing real-time collaboration.
    // _syncSubscription?.cancel();
    // _syncSubscription = _cloudService.notesStream().listen((remoteNotes) {
    //   _lastSynced = DateTime.now();
    //   notifyListeners();
    // });

    // Seed initial data if empty (Tasks and Courses)
    if (_localRepository.getAllTasks().isEmpty &&
        _localRepository.getAllCourses().isEmpty) {
      _seedInitialData();
    }
  }

  void _seedInitialData() async {
    await _localRepository.saveTask(
      Task.create(
        title: 'Read Chapter 4 (Biology)',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        category: 'Science',
      )..isCompleted = true,
    );
    await _localRepository.saveTask(
      Task.create(
        title: 'Submit Abstract (Modern Lit)',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        category: 'Arts',
      ),
    );
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final notes = _localRepository.getDeletedNotes();
    final tasks = _localRepository.getDeletedTasks();
    final folders = _localRepository.getDeletedFolders();

    for (var note in notes) {
      await _localRepository.deleteNote(note.id);
    }
    for (var task in tasks) {
      await _localRepository.deleteTask(task.id);
    }
    for (var folder in folders) {
      await _localRepository.deleteFolder(folder.id);
    }
    notifyListeners();
  }

  void setView(LibraryView view) {
    _currentView = view;
    _selectedTag = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void filterByTag(String tag) {
    _selectedTag = tag;
    _currentView = LibraryView.allNotes;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}
