// lib/services/auth_service.dart

class AuthService {
  Future<void> login(String email, String password) async {
    // Simulate login (replace with real logic like Firebase later)
    await Future.delayed(const Duration(seconds: 1));
    print("✅ Logged in with: $email");
  }

  Future<void> register(String email, String password) async {
    // Simulate registration (replace with real logic like Firebase later)
    await Future.delayed(const Duration(seconds: 1));
    print("✅ Registered with: $email");
  }
}