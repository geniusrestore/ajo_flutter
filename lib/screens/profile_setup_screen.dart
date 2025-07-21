import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ajo/services/firestore_service.dart';
import 'main_navigation_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String phoneNumber = '';
  bool isLoading = false;
  String errorMessage = '';

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      await FirestoreService().createOrUpdateUser(
        uid: user.uid,
        email: user.email ?? '',
        name: fullName,
        phone: phoneNumber,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to save profile: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Profile Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter your name'
                              : null,
                      onSaved: (value) => fullName = value!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter your phone number'
                              : null,
                      onSaved: (value) => phoneNumber = value!.trim(),
                    ),
                    const SizedBox(height: 24),
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Save & Continue'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}