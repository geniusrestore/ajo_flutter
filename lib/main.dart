import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'onboarding/onboarding_screen.dart'; // ✅ Add this line

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
      home: const OnboardingScreen(), // ✅ Starts here
    );
  }
}