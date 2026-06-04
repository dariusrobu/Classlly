import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

/// BYOC iCloud implementation of [CloudStorageService].
///
/// Stores all Classlly data as JSON files in the user's iCloud
/// container. Only available on iOS and macOS.
class ICloudStorageService implements CloudStorageService {
  static const _containerId = 'iCloud.com.robudarius.classlly';

  /// Upload JSON data to iCloud as a file.
  Future<void> _uploadJson(String fileName, Object data) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsString(jsonEncode(data));

    try {
      await ICloudStorage.upload(
        containerId: _containerId,
        filePath: tempFile.path,
        destinationRelativePath: fileName,
      );
    } catch (e) {
      debugPrint('iCloud upload error for $fileName: $e');
      if (e.toString().contains('Invalid containerId')) {
        debugPrint('TIP: Ensure you are signed into iCloud on this device and "Classlly" is enabled in iCloud settings.');
      }
      rethrow;
    }

    // Clean up temp file
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  /// Download and parse JSON from iCloud.
  Future<dynamic> _downloadJson(String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final destPath = '${tempDir.path}/icloud_$fileName';

      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: fileName,
        destinationFilePath: destPath,
      );

      final file = File(destPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        await file.delete();
        return jsonDecode(content);
      }
      return null;
    } catch (e) {
      debugPrint('iCloud download error for $fileName: $e');
      return null;
    }
  }

  // ── CloudStorageService Implementation ──

  @override
  Stream<List<Note>> notesStream() => const Stream.empty();

  @override
  Stream<void> get remoteUpdates => const Stream.empty();

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
    debugPrint('iCloud: Full sync completed');
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
  Future<void> syncPreferences() async {}

  @override
  Future<bool> hasProfile() async {
    final data = await _downloadJson('profile.json');
    return data != null;
  }

  @override
  Future<bool> verifyConnection() async {
    try {
      final healthId = 'health_check_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = '$healthId.json';
      
      // Attempt Write
      await _uploadJson(fileName, {'ping': true, 'timestamp': healthId});
      
      // Attempt Delete (Cleanup)
      await ICloudStorage.delete(
        containerId: _containerId,
        relativePath: fileName,
      );
      
      return true;
    } catch (e) {
      debugPrint('iCloud Handshake Failed: $e');
      return false;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await syncNotes();
  }

  @override
  Future<void> deleteUserContent() async {
    final files = [
      'notes.json', 'courses.json', 'tasks.json', 'folders.json',
      'calendar.json', 'grades.json', 'attendance.json', 'profile.json',
    ];
    for (final file in files) {
      try {
        await ICloudStorage.delete(
          containerId: _containerId,
          relativePath: file,
        );
      } catch (e) {
        debugPrint('iCloud delete error for $file: $e');
      }
    }
  }
}
