import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService wraps Firebase Authentication and Google Sign-In functionality.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1017758929444-uhsjm5tov9eu3qostftajcduob9t8k8v.apps.googleusercontent.com',
  );

  /// Stream listening to auth state changes (logged in vs logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign up user with Email and Password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in user with Email and Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google (OAuth2 popup / credential exchange)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled flow

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in using College admission number and college code (Synthetic Email format)
  Future<UserCredential?> signInWithSyntheticEmail({
    required String admissionNo,
    required String collegeCode,
    required String password,
  }) async {
    final syntheticEmail = '${admissionNo.trim().toLowerCase()}@${collegeCode.trim().toLowerCase()}.internal';
    return await signInWithEmail(syntheticEmail, password);
  }

  /// Update current user password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('No authenticated user found.');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Ignored for fallback demo mode
    }
  }
}
