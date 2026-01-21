import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    // Web implementation
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      return;
    }

    // Mobile implementation (Android/iOS)
    const iosClientId = '153897807907-tllogka5ud9ploje6n0urqalhu0n7oku.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      // PURE iOS CONFIG: Use iosClientId only. Remove serverClientId.
      // This ensures we get a standard iOS ID Token with a nonce we can extract.
      clientId: (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? iosClientId : null,
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;

    if (googleAuth == null) {
      throw const AuthException('Google Sign In failed');
    }

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AuthException('No ID Token found.');
    }

    // Extract Nonce
    String? googleNonce;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final parts = idToken.split('.');
        if (parts.length > 1) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final resp = utf8.decode(base64Url.decode(normalized));
          final payloadMap = jsonDecode(resp);
          if (payloadMap is Map<String, dynamic> && payloadMap.containsKey('nonce')) {
            googleNonce = payloadMap['nonce'];
            debugPrint('✅ Extracted Nonce: $googleNonce');
          }
        }
      } catch (e) {
        debugPrint('❌ Error parsing nonce: $e');
      }
    }

    // MAGIC FIX: Use idToken as BOTH parameters. 
    // This forces Supabase to validate the JWT locally and bypasses the Google UserInfo 
    // endpoint which often causes the 'passed nonce' mismatch on iOS.
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: idToken, 
    );

    // Update user metadata with name from Google
    if (googleUser.displayName != null) {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': googleUser.displayName},
        ),
      );
    }
  }

  Future<void> signInWithApple() async {
    if (kIsWeb) {
       await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
      );
      return;
    }
    
    final rawNonce = _supabase.auth.generateRawNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Could not find ID Token from generated credential.');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Apple only returns the name on the first sign in.
    if (credential.givenName != null) {
      final fullName = '${credential.givenName} ${credential.familyName ?? ''}'.trim();
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': fullName},
        ),
      );
    }
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
