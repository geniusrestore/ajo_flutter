import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  final _auth = AuthService();
  bool loading = false;

  void _submit() async {
    setState(() => loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final user = isLogin
        ? await _auth.loginWithEmail(email, password)
        : await _auth.registerWithEmail(email, password);
    setState(() => loading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(controller: _emailController, label: 'Email'),
            const SizedBox(height: 20),
            CustomTextField(controller: _passwordController, label: 'Password', obscure: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isLogin ? 'Login' : 'Register'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin
                  ? 'No account? Register'
                  : 'Already have an account? Login'),
            )
          ],
        ),
      ),
    );
  }
}