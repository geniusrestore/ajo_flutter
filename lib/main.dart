import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';  // Make sure you have this file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('⏳ Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const AjoApp());
}

class AjoApp extends StatelessWidget {
  const AjoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🏁 Building AjoApp');
    return MaterialApp(
      title: 'Ajo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Roboto',
            ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with your actual auth check logic
    final bool isLoggedIn = false; // example placeholder

    if (isLoggedIn) {
      return const HomeScreen();
    } else {
      return const OnboardingScreen();
      // Or return AuthScreen() if you prefer
    }
  }
}