import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:classlly/core/services/google_drive_cloud_service.dart';
import 'package:classlly/core/services/icloud_cloud_service.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

/// Available cloud storage providers for BYOC.
enum CloudProvider {
  none,
  supabase,
  googleDrive,
  iCloud;

  String get displayName {
    switch (this) {
      case CloudProvider.none:
        return 'Offline Only';
      case CloudProvider.supabase:
        return 'Classlly Cloud';
      case CloudProvider.googleDrive:
        return 'Google Drive';
      case CloudProvider.iCloud:
        return 'iCloud';
    }
  }

  String get description {
    switch (this) {
      case CloudProvider.none:
        return 'Data stays on this device only';
      case CloudProvider.supabase:
        return 'Sync via Classlly servers';
      case CloudProvider.googleDrive:
        return 'Store in your personal Google Drive';
      case CloudProvider.iCloud:
        return 'Store in your personal iCloud';
    }
  }

  /// Whether this provider is available on the current platform.
  bool get isAvailable {
    if (this == CloudProvider.iCloud) {
      if (kIsWeb) return false;
      return Platform.isIOS || Platform.isMacOS;
    }
    return true;
  }
}

/// Factory that returns the correct [CloudStorageService] based on user preference.
class CloudProviderManager {
  CloudProviderManager._();

  /// Returns a [CloudStorageService] for the given [provider].
  static CloudStorageService getService(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.none:
        return _OfflineOnlyService();
      case CloudProvider.supabase:
        return SupabaseCloudService();
      case CloudProvider.googleDrive:
        return GoogleDriveCloudService();
      case CloudProvider.iCloud:
        return ICloudStorageService();
    }
  }

  /// Reads the current provider from [UserPreferences].
  static CloudProvider getCurrentProvider() {
    final prefs = NotesRepository().getPreferences();
    return CloudProvider.values.firstWhere(
      (p) => p.name == prefs.cloudProvider,
      orElse: () => CloudProvider.none,
    );
  }
}

/// No-op service for offline-only mode.
class _OfflineOnlyService implements CloudStorageService {
  @override
  Stream<List<Note>> notesStream() => const Stream.empty();

  @override
  Stream<void> get remoteUpdates => const Stream.empty();

  @override
  Future<void> syncAll({bool interactive = false}) async {}

  @override
  Future<void> syncNotes() async {}

  @override
  Future<void> syncCourses() async {}

  @override
  Future<void> syncTasks() async {}

  @override
  Future<void> syncFolders() async {}

  @override
  Future<void> syncCalendar() async {}

  @override
  Future<void> syncGrades() async {}

  @override
  Future<void> syncAttendance() async {}

  @override
  Future<void> syncProfile() async {}

  @override
  Future<void> syncPreferences() async {}

  @override
  Future<bool> verifyConnection() async => true; // Always connected when offline

  @override
  Future<bool> hasProfile() async => true; // Always true for offline

  @override
  Future<void> deleteNote(String noteId) async {}

  @override
  Future<void> deleteUserContent() async {}
}
