import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all users from user_profiles
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final users = await getAllUsers();

      final activeUsers = users.where((u) => u['is_active'] == true).length;
      final adminCount = users.where((u) => u['role'] == 'admin').length;
      final salesRepCount = users.where((u) => u['role'] == 'sales_rep').length;
      final warehouseCount =
          users.where((u) => u['role'] == 'warehouse_staff').length;
      final customerCount =
          users.where((u) => u['role'] == 'b2b_customer').length;

      return {
        'total_users': users.length,
        'active_users': activeUsers,
        'admin_count': adminCount,
        'sales_rep_count': salesRepCount,
        'warehouse_staff_count': warehouseCount,
        'b2b_customer_count': customerCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  // Create new user with Supabase auth
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? companyName,
  }) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      // Update user profile with additional data
      await _supabase.from('user_profiles').update({
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'company_name': companyName,
        'is_active': true,
      }).eq('id', authResponse.user!.id);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Update existing user
  Future<void> updateUser({
    required String userId,
    required String fullName,
    required String role,
    String? phone,
    String? companyName,
  }) async {
    try {
      await _supabase.from('user_profiles').update({
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'company_name': companyName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Update user status (active/inactive)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _supabase.from('user_profiles').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch users by role: $e');
    }
  }

  // Get customers assigned to a sales representative
  Future<List<Map<String, dynamic>>> getCustomersByCommercial(
    String commercialId,
  ) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('*, user_profiles!customers_user_id_fkey(*)')
          .eq('commercial_id', commercialId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  // Assign customer to commercial
  Future<void> assignCustomerToCommercial(
    String customerId,
    String commercialId,
  ) async {
    try {
      await _supabase.from('customers').update({
        'commercial_id': commercialId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to assign customer: $e');
    }
  }
}
