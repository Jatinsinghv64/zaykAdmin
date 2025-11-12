import 'package:firebase_auth/firebase_auth.dart';


// This service ONLY handles authentication (signing in, out, and auth state).
// It does NOT know about roles or branches.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of authentication state changes.
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Get the current user, if any.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  /// Returns an error message string on failure, or null on success.
  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Success
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        return 'The email address is not valid.';
      } else {
        return 'An error occurred. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
