import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('⏳ Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const AjoApp());
}

class AjoApp extends StatelessWidget {
  const AjoApp({Key? key}) : super(key: key);

  Future<bool> isProfileComplete(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists &&
        doc.data()?['fullName'] != null &&
        doc.data()?['phoneNumber'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ajo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (user == null) {
            return const OnboardingScreen(); // Not logged in
          }

          if (!user.emailVerified) {
            return const VerifyEmailScreen(); // Email not verified
          }

          return FutureBuilder<bool>(
            future: isProfileComplete(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (profileSnapshot.hasData && profileSnapshot.data == false) {
                return const ProfileSetupScreen(); // Complete profile
              }

              return const HomeScreen(); // All good
            },
          );
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/verify': (context) => const VerifyEmailScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
      },
    );
  }
}