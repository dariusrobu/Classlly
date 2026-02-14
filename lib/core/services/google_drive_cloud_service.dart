import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/core/constants/supabase_config.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

/// BYOC Google Drive implementation of [CloudStorageService].
///
/// Uses Supabase Auth tokens to access Google Drive API via [googleapis_auth].
/// Requires user to have signed in with Google and granted 'drive.file' scope.
class GoogleDriveCloudService implements CloudStorageService {
  static const _folderName = 'Classlly';
  static const _mimeFolder = 'application/vnd.google-apps.folder';

  drive.DriveApi? _driveApi;
  String? _appFolderId;
  AuthClient? _authClient;

  /// Get the authenticated Drive API client using Supabase session.
  Future<drive.DriveApi?> _getDriveApi({bool interactive = false}) async {
    if (_driveApi != null && _authClient != null) {
      // Check if client is still valid or auto-refreshed
      return _driveApi!;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.providerToken == null) {
      if (interactive) {
        // If interactive, prompt user to login (handled by UI, strictly speaking)
        debugPrint('GoogleDrive: User not signed in. Please sign in via Settings.');
      }
      return null;
    }

    try {
      final accessToken = AccessToken(
        'Bearer',
        session.providerToken!,
        DateTime.now().add(const Duration(hours: 1)), // Assumed expiry if unknown
      );

      // Create credentials. If we have a refresh token, use it for auto-refresh.
      AccessCredentials credentials;
      if (session.providerRefreshToken != null) {
        credentials = AccessCredentials(
          accessToken,
          session.providerRefreshToken,
          [drive.DriveApi.driveFileScope],
        );

        final clientId = ClientId(
          SupabaseConfig.googleServerClientId,
          SupabaseConfig.googleClientSecret,
        );

        _authClient = autoRefreshingClient(clientId, credentials, http.Client());
      } else {
        // Fallback to simple authenticated client (no refresh)
        credentials = AccessCredentials(
          accessToken,
          null,
          [drive.DriveApi.driveFileScope],
        );
        _authClient = authenticatedClient(http.Client(), credentials);
      }

      _driveApi = drive.DriveApi(_authClient!);
      return _driveApi!;
    } catch (e) {
      debugPrint('GoogleDrive: Failed to create client: $e');
      return null;
    }
  }

  /// Get or create the Classlly app folder on Google Drive.
  Future<String?> _getAppFolderId() async {
    if (_appFolderId != null) return _appFolderId!;

    final api = await _getDriveApi();
    if (api == null) return null;

    try {
      // Search for existing folder
      final result = await api.files.list(
        q: "name = '$_folderName' and mimeType = '$_mimeFolder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        _appFolderId = result.files!.first.id;
        return _appFolderId!;
      }

      // Create folder
      final folder = drive.File()
        ..name = _folderName
        ..mimeType = _mimeFolder;

      final created = await api.files.create(folder);
      _appFolderId = created.id;
      return _appFolderId!;
    } catch (e) {
      debugPrint('GoogleDrive: Error getting folder: $e');
      return null;
    }
  }

  /// Upload JSON data as a file to the app folder.
  Future<void> _uploadJson(String fileName, Object data) async {
    final api = await _getDriveApi();
    if (api == null) return;

    final folderId = await _getAppFolderId();
    if (folderId == null) return;

    final jsonBytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(
      Stream.value(jsonBytes),
      jsonBytes.length,
    );

    try {
      // Check if file already exists
      final existing = await api.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id)',
      );

      if (existing.files != null && existing.files!.isNotEmpty) {
        // Update existing file
        await api.files.update(
          drive.File(),
          existing.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final file = drive.File()
          ..name = fileName
          ..parents = [folderId];
        await api.files.create(file, uploadMedia: media);
      }
    } catch (e) {
      debugPrint('GoogleDrive: Upload failed for $fileName: $e');
    }
  }

  /// Download and parse JSON from a file in the app folder.
  Future<dynamic> _downloadJson(String fileName) async {
    final api = await _getDriveApi();
    if (api == null) return null;

    final folderId = await _getAppFolderId();
    if (folderId == null) return null;

    try {
      final result = await api.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id)',
      );

      if (result.files == null || result.files!.isEmpty) return null;

      final fileId = result.files!.first.id!;
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      return jsonDecode(utf8.decode(bytes));
    } catch (e) {
      debugPrint('GoogleDrive: Download failed for $fileName: $e');
      return null;
    }
  }

  // ── CloudStorageService Implementation ──

  @override
  Stream<List<Note>> notesStream() => const Stream.empty();

  @override
  Future<void> syncAll({bool interactive = false}) async {
    // Attempt to get API. If interactive, we might prompt user (not implemented here, relies on Auth Screen).
    final api = await _getDriveApi(interactive: interactive);
    if (api == null) {
      if (interactive) {
        debugPrint('GoogleDrive: Sync aborted, no auth.');
      }
      return;
    }

    try {
      await syncProfile();
      await syncNotes();
      await syncCourses();
      await syncTasks();
      await syncFolders();
      await syncCalendar();
      await syncGrades();
      await syncAttendance();
      debugPrint('GoogleDrive: Full sync completed via Supabase Tokens');
    } catch (e) {
      debugPrint('GoogleDrive: Sync failed: $e');
      if (interactive) rethrow; // Rethrow if user initiated to show error toast
    }
  }


  @override
  Future<void> syncNotes() async {
    final repo = NotesRepository();
    final localNotes = repo.getAllNotes();
    final jsonList = localNotes.map((n) => n.toJson()).toList();
    await _uploadJson('notes.json', jsonList);
  }

  @override
  Future<void> syncCourses() async {
    final repo = NotesRepository();
    final localCourses = repo.getAllCourses();
    final jsonList = localCourses.map((c) => c.toJson()).toList();
    await _uploadJson('courses.json', jsonList);
  }

  @override
  Future<void> syncTasks() async {
    final repo = NotesRepository();
    final localTasks = repo.getAllTasks();
    final jsonList = localTasks.map((t) => t.toJson()).toList();
    await _uploadJson('tasks.json', jsonList);
  }

  @override
  Future<void> syncFolders() async {
    await _uploadJson('folders.json', []);
  }

  @override
  Future<void> syncCalendar() async {
    final repo = NotesRepository();
    final events = repo.getAllEvents();
    final periods = repo.getAllPeriods();
    await _uploadJson('calendar.json', {
      'events': events.map((e) => e.toJson()).toList(),
      'periods': periods.map((p) => p.toJson()).toList(),
    });
  }

  @override
  Future<void> syncGrades() async {
    final repo = NotesRepository();
    final courses = repo.getAllCourses();
    final allGrades = <Map<String, dynamic>>[];
    for (final course in courses) {
      final grades = repo.getGradesForCourse(course.id);
      allGrades.addAll(grades.map((g) => g.toJson()));
    }
    await _uploadJson('grades.json', allGrades);
  }

  @override
  Future<void> syncAttendance() async {
    final repo = NotesRepository();
    final courses = repo.getAllCourses();
    final allAttendance = <Map<String, dynamic>>[];
    for (final course in courses) {
      final attendance = repo.getAttendanceForCourse(course.id);
      allAttendance.addAll(attendance.map((a) => a.toJson()));
    }
    await _uploadJson('attendance.json', allAttendance);
  }

  @override
  Future<void> syncProfile() async {
    final repo = NotesRepository();
    final profile = repo.getStudentProfile();
    await _uploadJson('profile.json', profile.toJson());
  }

  @override
  Future<bool> hasProfile() async {
    final data = await _downloadJson('profile.json');
    return data != null;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await syncNotes();
  }

  @override
  Future<void> deleteUserContent() async {
    final api = await _getDriveApi();
    if (api == null) return;

    final folderId = await _getAppFolderId();
    if (folderId == null) return;

    try {
      final result = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id)',
      );

      if (result.files != null) {
        for (final file in result.files!) {
          await api.files.delete(file.id!);
        }
      }
      await api.files.delete(folderId);
      _appFolderId = null;
    } catch (e) {
      debugPrint('GoogleDrive: Delete content failed: $e');
    }
  }
}
