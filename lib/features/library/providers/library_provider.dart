import 'dart:async';
import 'package:flutter/material.dart';
import 'package:classlly/data/repositories/supabase_repository.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/task_model.dart';

enum LibraryView { dashboard, allNotes, courses, tasks, calendar, archive }

class LibraryProvider with ChangeNotifier {
  final SupabaseRepository _remoteRepository = SupabaseRepository();
  final NotesRepository _localRepository = NotesRepository();
  StreamSubscription? _syncSubscription;

  LibraryView _currentView = LibraryView.dashboard;
  String _searchQuery = '';
  String? _selectedTag;
  DateTime? _lastSynced;

  LibraryView get currentView => _currentView;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  DateTime? get lastSynced => _lastSynced;

  List<Task> get tasks => _localRepository.getAllTasks();

  void initSync() {
    _syncSubscription?.cancel();
    _syncSubscription = _remoteRepository.notesStream().listen((
      remoteNotes,
    ) async {
      await _remoteRepository.syncNotes();
      _lastSynced = DateTime.now();
      notifyListeners();
    });

    // Seed some initial data if empty
    if (tasks.isEmpty) {
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
    await _localRepository.saveTask(
      Task.create(
        title: 'Practice Quiz (Calculus)',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        category: 'Math',
      ),
    );
    await _localRepository.saveTask(
      Task.create(
        title: 'Group Presentation Slides',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        category: 'Project',
      )..progress = 0.4,
    );
    notifyListeners();
  }

  Future<void> addTask(
    String title, {
    DateTime? dueDate,
    String? category,
  }) async {
    final task = Task.create(
      title: title,
      dueDate: dueDate,
      category: category,
    );
    await _localRepository.saveTask(task);
    notifyListeners();
  }

  Future<void> toggleTask(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _localRepository.saveTask(task);
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
