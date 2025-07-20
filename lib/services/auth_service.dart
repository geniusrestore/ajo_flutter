import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Register new user
  Future<String?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Save user info in Firestore
        await _firestoreService.createOrUpdateUser(
          email: user.email!,
          name: name,
        );
        return null; // success
      } else {
        return 'User registration failed';
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Login existing user
  Future<String?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Update Firestore user info
        await _firestoreService.createOrUpdateUser(
          email: user.email!,
          name: user.displayName ?? "No Name",
        );
        return null; // success
      } else {
        return 'Login failed';
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth state stream
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}