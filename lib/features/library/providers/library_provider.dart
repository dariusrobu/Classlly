import 'dart:async';
import 'package:flutter/material.dart';
import 'package:classlly/data/repositories/supabase_repository.dart';

enum LibraryView { dashboard, allNotes, courses, tasks, archive }

class LibraryProvider with ChangeNotifier {
  final SupabaseRepository _remoteRepository = SupabaseRepository();
  StreamSubscription? _syncSubscription;

  LibraryView _currentView = LibraryView.dashboard;
  String _searchQuery = '';
  String? _selectedTag;
  DateTime? _lastSynced;

  LibraryView get currentView => _currentView;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  DateTime? get lastSynced => _lastSynced;

  void initSync() {
    _syncSubscription?.cancel();
    _syncSubscription = _remoteRepository.notesStream().listen((
      remoteNotes,
    ) async {
      await _remoteRepository.syncNotes();
      _lastSynced = DateTime.now();
      notifyListeners();
    });
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
