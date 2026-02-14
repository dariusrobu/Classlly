import 'dart:io';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String url = 'https://kqwbduqdzgeevtcifnqx.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxd2JkdXFkemdlZXZ0Y2lmbnF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MTk3NDksImV4cCI6MjA4Mzk5NTc0OX0.8EpXvPIoRrtKBwLM1ad0qd3I_85L-JVJ5HVfy4k6jsg';

  // Google OAuth Client IDs (from Google Cloud Console)
  static const String googleClientIdIos =
      '153868073469-0qfpvncp240nqhp8e5cnhge4p1j2h6uh.apps.googleusercontent.com';
  static const String googleClientIdMacos =
      '153897807907-tllogka5ud9ploje6n0urqalhu0n7oku.apps.googleusercontent.com';

  // Google OAuth Web Client ID (for serverClientId / Supabase verification)
  static const String googleServerClientId =
      '153897807907-bp8dka0fij0l82tp887ea0mf520uris8.apps.googleusercontent.com';
  static const String googleClientSecret = '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'; // Required for Desktop loopback flow

  /// Returns the correct Google client ID for the current platform.
  static String? get googleClientId {
    if (kIsWeb) return null; // Web uses a different flow
    if (Platform.isIOS) return googleClientIdIos;
    if (Platform.isMacOS) return googleClientIdMacos;
    return null; // Android reads from google-services.json
  }
}
