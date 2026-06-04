import 'package:flutter/foundation.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

class SearchResult {
  final Note note;
  final String matchedText;
  final List<String> matchedTokens;

  SearchResult({
    required this.note,
    required this.matchedText,
    required this.matchedTokens,
  });
}

class SearchService {
  final Map<String, Set<String>> _invertedIndex = {};
  final Map<String, Note> _notesCache = {};
  bool _isIndexed = false;

  Future<void> indexAllNotes() async {
    _invertedIndex.clear();
    _notesCache.clear();

    final repo = NotesRepository();
    final notes = repo.getAllNotes();

    for (final note in notes) {
      await _indexNote(note);
    }

    _isIndexed = true;
    debugPrint('SEARCH_SERVICE: Indexed ${notes.length} notes');
  }

  Future<void> _indexNote(Note note) async {
    _notesCache[note.id] = note;

    final tokens = _tokenize(note.title);
    tokens.addAll(_tokenize(_extractTextContent(note)));

    for (final token in tokens) {
      _invertedIndex.putIfAbsent(token, () => {});
      _invertedIndex[token]!.add(note.id);
    }
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toList();
  }

  String _extractTextContent(Note note) {
    return note.textBlocks
        .map((tb) => tb.text)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> updateNote(Note note) async {
    await _indexNote(note);
  }

  Future<void> removeNote(String noteId) async {
    _notesCache.remove(noteId);
    for (final tokens in _invertedIndex.values) {
      tokens.remove(noteId);
    }
  }

  List<SearchResult> search(String query, {int limit = 20}) {
    if (!_isIndexed) {
      debugPrint('SEARCH_SERVICE: Index not ready, returning empty');
      return [];
    }

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    final Map<String, int> noteScores = {};

    for (final token in queryTokens) {
      for (final noteId in _invertedIndex[token] ?? {}) {
        noteScores[noteId] = (noteScores[noteId] ?? 0) + 1;
      }
    }

    final sortedIds = noteScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final results = <SearchResult>[];
    for (var i = 0; i < sortedIds.length && i < limit; i++) {
      final noteId = sortedIds[i].key;
      final note = _notesCache[noteId];
      if (note != null) {
        results.add(
          SearchResult(
            note: note,
            matchedText: _getMatchedText(note, queryTokens),
            matchedTokens: queryTokens,
          ),
        );
      }
    }

    return results;
  }

  String _getMatchedText(Note note, List<String> tokens) {
    final fullText = '${note.title} ${_extractTextContent(note)}';

    for (final token in tokens) {
      final index = fullText.toLowerCase().indexOf(token);
      if (index != -1) {
        final start = (index - 20).clamp(0, fullText.length);
        final end = (index + token.length + 40).clamp(0, fullText.length);
        final snippet = fullText.substring(start, end);
        return '${start > 0 ? '...' : ''}$snippet${end < fullText.length ? '...' : ''}';
      }
    }

    return fullText.length > 80 ? '${fullText.substring(0, 80)}...' : fullText;
  }

  bool get isIndexed => _isIndexed;
}
