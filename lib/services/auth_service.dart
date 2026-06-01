import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    try {
      return await _client.auth
          .signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Échec de connexion: ${e.toString()}');
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName ?? ''},
      );
      return response;
    } catch (e) {
      throw Exception('Échec d\'inscription: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Échec de déconnexion: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
    } catch (e) {
      throw Exception('Échec de réinitialisation: ${e.toString()}');
    }
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      await _client.auth.updateUser(UserAttributes(password: password));
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Échec de validation OTP: ${e.toString()}');
    }
  }

  Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final response = await _client
          .from('user_profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      return response?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }
}
