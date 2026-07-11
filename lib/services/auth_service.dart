import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const auditorEmail = 'cso_auditor@aclcmandaue.com';
  static const treasurerEmail = 'cso_treasurer@aclcmandaue.com';

  Future<User?> registerWithEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      await user?.updateDisplayName(username);
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  static String roleFromEmail(String? email) {
    final normalized = email?.trim().toLowerCase() ?? '';
    if (normalized == auditorEmail) return 'Auditor';
    return 'Treasurer';
  }

  static String messageForError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'Could not sign in. Please try again.';
    }
  }
}
