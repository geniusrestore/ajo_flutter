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
        await _auth.signOut();
        return 'Please verify your email before logging in. A verification link has been sent.';
      }

      return null; // Success
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

      final user = userCredential.user;
      if (user == null) {
        return 'Registration failed: user is null.';
      }

      // Save user data to Firestore with uid
      await _firestoreService.createOrUpdateUser(
        uid: user.uid,
        email: email,
        name: name,
      );

      // Send verification email
      await user.sendEmailVerification();

      await _auth.signOut(); // force them to verify before login
      return 'A verification email has been sent. Please check your inbox before logging in.';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Current user
  User? get currentUser => _auth.currentUser;
}