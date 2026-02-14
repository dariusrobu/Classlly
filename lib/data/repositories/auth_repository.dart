import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  GoTrueClient get _auth => _client.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<void> deleteAccount() async {
    final cloudService = SupabaseCloudService();
    await cloudService.deleteUserContent();
    await _auth.signOut();
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await NotesRepository().clearAllData();
    await _auth.signOut();
  }

  Future<AuthResponse> signInWithGoogle() async {
    print('DEBUG: AuthRepository.signInWithGoogle called (BROWSER ONLY MODE)');
    return _signInWithGoogleOAuth();
  }

  /// Browser-based Google OAuth for desktop platforms.
  Future<AuthResponse> _signInWithGoogleOAuth() async {
    // Listen for auth state change from the OAuth callback
    final completer = Completer<AuthResponse>();
    late final StreamSubscription<AuthState> subscription;

    subscription = _auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn && event.session != null) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(AuthResponse(
            session: event.session,
            user: event.session!.user,
          ));
        }
      }
    });

    final success = await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.robudarius.classlly://login-callback',
      scopes: 'https://www.googleapis.com/auth/drive.file',
      queryParams: {
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );

    if (!success) {
      subscription.cancel();
      throw const AuthException('Google Sign In failed to launch');
    }

    // Wait for the callback with a timeout
    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        subscription.cancel();
        throw const AuthException('Google Sign In timed out');
      },
    );
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
      throw AuthException('No identity token received from Apple');
    }

    return await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
      nonce: rawNonce,
    );
  }

  String _generateRandomString() {
    return DateTime.now().toIso8601String();
  }
}