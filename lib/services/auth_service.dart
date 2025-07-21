import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // LOGIN
  Future<String?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut(); // prevent login
        return 'Please verify your email before logging in. A new verification email has been sent.';
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // REGISTER
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user to Firestore
      await _firestoreService.createOrUpdateUser(
        email: email,
        name: name,
      );

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // RESEND VERIFICATION EMAIL
  Future<String?> resendEmailVerification(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut(); // Log out after sending
        return 'Verification email resent. Please check your inbox.';
      } else {
        return 'Email is already verified or user not found.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to resend verification email.';
    }
  }

  // Current user getter
  User? get currentUser => _auth.currentUser;
}