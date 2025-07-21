import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_screen.dart';
import 'package:ajo/screens/home_screen.dart';
import 'profile_setup_screen.dart'; // ✅ Make sure this file exists and is imported

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _handleAuth(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists || !(doc.data()?['name']?.isNotEmpty == true)) {
      // 👆 You can also check other required fields like 'city', 'state', etc. if needed
      return const ProfileSetupScreen();
    } else {
      return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          // ✅ Use FutureBuilder to wait for Firestore check
          return FutureBuilder<Widget>(
            future: _handleAuth(snapshot.data!),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return futureSnapshot.data!;
              }
            },
          );
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}