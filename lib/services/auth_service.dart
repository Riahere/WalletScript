// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Web Client ID dari Google Cloud Console (tipe Web application)
      const webClientId =
          '933976545522-vqspnkrrnu5jkhmfddbq6ohc242tvs4b.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // user batal

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw Exception('ID Token null');

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  // ─── Email & Password ─────────────────────────────────────────────────────

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password,
      {String? fullName}) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ─── Session & Sign Out ───────────────────────────────────────────────────

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;
  String? get userName =>
      currentUser?.userMetadata?['full_name'] as String? ??
      currentUser?.userMetadata?['name'] as String?;
  String? get userAvatar =>
      currentUser?.userMetadata?['avatar_url'] as String? ??
      currentUser?.userMetadata?['picture'] as String?;

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }

  // ─── Auth State Stream ────────────────────────────────────────────────────

  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;
}
