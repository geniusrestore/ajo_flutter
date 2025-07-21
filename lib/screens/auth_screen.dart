import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ajo/screens/main_navigation_screen.dart';
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  String email = '';
  String password = '';
  String confirmPassword = '';
  String? result;
  bool showResendButton = false;
  bool isLoading = false;

  Future<bool> isProfileComplete(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists &&
        doc.data()?['fullName'] != null &&
        doc.data()?['phoneNumber'] != null;
  }

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formKey.currentState!.save();
    setState(() => isLoading = true);
    setState(() {
      result = null;
      showResendButton = false;
    });

    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (isLogin) {
        userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        if (password != confirmPassword) {
          setState(() {
            result = 'Passwords do not match';
            isLoading = false;
          });
          return;
        }

        userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user!.sendEmailVerification();

        setState(() {
          result = 'A verification email has been sent. Please verify your email.';
          showResendButton = true;
          isLoading = false;
        });

        await auth.signOut();
        return;
      }

      final user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await auth.signOut();
        await user.sendEmailVerification();

        setState(() {
          result =
              'Please verify your email before logging in. A new verification link has been sent.';
          showResendButton = true;
          isLoading = false;
        });
        return;
      }

      if (user != null && user.emailVerified) {
        final profileComplete = await isProfileComplete(user.uid);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => profileComplete
                ? const MainNavigationScreen()
                : const ProfileSetupScreen(),
          ),
        );
        return;
      }
    } catch (e) {
      setState(() {
        result = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _resendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      setState(() {
        result = 'Verification email resent. Please check your inbox.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (val) => email = val!.trim(),
                validator: (val) =>
                    val == null || !val.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (val) => password = val!,
                validator: (val) =>
                    val != null && val.length < 6 ? 'Min 6 characters' : null,
              ),
              if (!isLogin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  onSaved: (val) => confirmPassword = val!,
                  validator: (val) =>
                      val != null && val.length < 6 ? 'Min 6 characters' : null,
                ),
              ],
              const SizedBox(height: 20),
              if (result != null)
                Text(
                  result!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              if (showResendButton)
                TextButton(
                  onPressed: _resendEmailVerification,
                  child: const Text('Resend Verification Email'),
                ),
              const SizedBox(height: 12),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(isLogin ? 'Login' : 'Register'),
                    ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    result = null;
                    showResendButton = false;
                  });
                },
                child: Text(isLogin
                    ? 'Don\'t have an account? Register'
                    : 'Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}