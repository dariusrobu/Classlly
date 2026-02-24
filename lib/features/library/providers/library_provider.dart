import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/core/services/cloud_provider.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/task_model.dart';

enum LibraryView { dashboard, allNotes, courses, tasks, calendar, archive }

class LibraryProvider with ChangeNotifier {
  CloudStorageService _cloudService;
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

  Future<void> initSync({bool interactive = false}) async {
    final prefs = _localRepository.getPreferences();
    
    // Auto-migrate legacy users to supabase if they are logged in but have 'none' selected
    if (prefs.cloudProvider == 'none' && Supabase.instance.client.auth.currentUser != null) {
      prefs.cloudProvider = 'supabase';
      await _localRepository.savePreferences(prefs);
    }

    // Load the currently selected Cloud Engine
    final currentProvider = CloudProvider.values.firstWhere(
      (p) => p.name == prefs.cloudProvider,
      orElse: () => CloudProvider.none,
    );
    _cloudService = CloudProviderManager.getService(currentProvider);

    if (_cloudService is SupabaseCloudService) {
      (_cloudService as SupabaseCloudService).initRealtime();
    }

    final lastSync = prefs.lastSyncTimestamp;

    // Only sync if >1 minute since last sync to ensure relative freshness
    // Or if interactive (manual button press)
    final shouldSync =
        interactive ||
        lastSync == null ||
        DateTime.now().difference(lastSync).inMinutes > 1;

    if (shouldSync) {
      debugPrint('SUPABASE_SYNC: Triggering sync and restore...');
      
      await _cloudService.syncAll(interactive: interactive);
      
      // Also RESTORE to pull changes from other devices
      if (_cloudService is SupabaseCloudService) {
        await (_cloudService as SupabaseCloudService).restoreAll();
      }

      _lastSynced = DateTime.now();
      
      // Update prefs
      prefs.lastSyncTimestamp = _lastSynced;
      await _localRepository.savePreferences(prefs);
      
      notifyListeners();
    } else {
      _lastSynced = lastSync;
    }

    _syncSubscription?.cancel();
    _syncSubscription = _cloudService.remoteUpdates.listen((_) {
      _lastSynced = DateTime.now();
      
      final prefs = _localRepository.getPreferences();
      prefs.lastSyncTimestamp = _lastSynced;
      _localRepository.savePreferences(prefs);
      
      notifyListeners();
    });

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
