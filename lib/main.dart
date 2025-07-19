import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AjoApp());
}

class AjoApp extends StatelessWidget {
  const AjoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      home: const AuthScreen(),
    );
  }
}