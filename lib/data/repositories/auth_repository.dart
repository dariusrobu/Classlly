import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:convert';

class AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  GoTrueClient get _auth => _client.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  static const String _settingsBoxName = 'app_settings';
  static const String _lastUserIdKey = 'last_user_id';

  static const List<String> userDataBoxes = [
    'notes',
    'courses',
    'tasks',
    'folders',
    'sync_store',
    'student_profile',
    'user_preferences',
    'academic_calendar',
    'attendance',
    'grades',
  ];

  Future<void> deleteAccount() async {
    final cloudService = SupabaseCloudService();
    await cloudService.deleteUserContent();
    await _auth.signOut();
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _handleSignIn(response.user?.id);
    return response;
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signUp(email: email, password: password);
    await _handleSignIn(response.user?.id);
    return response;
  }

  Future<void> signOut() async {
    if (_auth.currentSession != null) {
      try {
        await SupabaseCloudService().syncAll();
      } catch (e) {
        print('Warning: Could not sync data before sign out: $e');
      }
    }
    await _auth.signOut();
  }

  Future<AuthResponse> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw const AuthException('Google Sign In was cancelled');
    }

    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw const AuthException('No ID token received from Google');
    }

    final response = await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
    );

    await _handleSignIn(response.user?.id);
    return response;
  }

  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateRandomString();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    if (credential.identityToken == null) {
      throw const AuthException('No identity token received from Apple');
    }

    final response = await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
      nonce: rawNonce,
    );

    await _handleSignIn(response.user?.id);
    return response;
  }

  Future<void> _handleSignIn(String? userId) async {
    if (userId == null) return;

    final lastUserId = await _getLastUserId();

    if (lastUserId != null && lastUserId != userId) {
      print('New user detected, clearing local data...');
      await _clearUserData();
    }

    await _setLastUserId(userId);
    print('Signed in as user: $userId');
  }

  Future<String?> _getLastUserId() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      return box.get(_lastUserIdKey) as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _setLastUserId(String userId) async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      await box.put(_lastUserIdKey, userId);
    } catch (e) {
      print('Error saving last user ID: $e');
    }
  }

  Future<void> _clearUserData() async {
    try {
      for (final boxName in userDataBoxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).clear();
          }
        } catch (e) {
          print('Warning: Could not clear box $boxName: $e');
        }
      }
      print('User data cleared');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  String _generateRandomString() {
    return DateTime.now().toIso8601String();
  }
}
