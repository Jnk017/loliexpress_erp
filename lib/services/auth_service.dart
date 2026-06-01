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
      final response = await _client.functions.invoke(
        'request_password_reset_otp',
        body: {'email': email},
      );
      if (response.status >= 400) {
        throw Exception(response.data?.toString() ?? 'Erreur OTP');
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('email_provider_missing') ||
          message.contains('RESEND_API_KEY')) {
        throw Exception(
          'Le service OTP email n’est pas configuré. Ajoutez RESEND_API_KEY dans les secrets Supabase.',
        );
      }
      throw Exception('Échec de réinitialisation: ${e.toString()}');
    }
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'verify_password_reset_otp',
        body: {
          'email': email,
          'otp': otp,
          'password': password,
        },
      );
      if (response.status >= 400) {
        throw Exception(response.data?.toString() ?? 'Code OTP invalide');
      }
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
