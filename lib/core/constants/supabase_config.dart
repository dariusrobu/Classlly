import 'dart:io';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String url = 'https://kqwbduqdzgeevtcifnqx.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxd2JkdXFkemdlZXZ0Y2lmbnF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MTk3NDksImV4cCI6MjA4Mzk5NTc0OX0.8EpXvPIoRrtKBwLM1ad0qd3I_85L-JVJ5HVfy4k6jsg';

  // Google OAuth Client IDs (from Google Cloud Console)
  static const String googleClientIdIos =
      'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';
  static const String googleClientIdMacos =
      'YOUR_MACOS_CLIENT_ID.apps.googleusercontent.com';

  // Google OAuth Web Client ID (for serverClientId / Supabase verification)
  static const String googleServerClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  // TODO: Load this from an environment variable (e.g., using flutter_dotenv or String.fromEnvironment)
  // NEVER hardcode secrets in source code.
  static const String googleClientSecret = '';

  /// Returns the correct Google client ID for the current platform.
  static String? get googleClientId {
    if (kIsWeb) return null; // Web uses a different flow
    if (Platform.isIOS) return googleClientIdIos;
    if (Platform.isMacOS) return googleClientIdMacos;
    return null; // Android reads from google-services.json
  }
}
