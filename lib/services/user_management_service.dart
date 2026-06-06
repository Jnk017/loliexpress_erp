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
      final salesRepCount =
          users.where((u) => u['role'] == 'commercial_staff').length;
      final warehouseCount =
          users.where((u) => u['role'] == 'warehouse_staff').length;
      final comptableCount =
          users.where((u) => u['role'] == 'comptable').length;
      final acheteurCount = users.where((u) => u['role'] == 'acheteur').length;
      final deliveryAgentCount =
          users.where((u) => u['role'] == 'delivery_agent').length;
      final customerCount =
          users.where((u) => u['role'] == 'client_b2b').length;

      return {
        'total_users': users.length,
        'active_users': activeUsers,
        'admin_count': adminCount,
        'sales_rep_count': salesRepCount,
        'warehouse_staff_count': warehouseCount,
        'comptable_count': comptableCount,
        'acheteur_count': acheteurCount,
        'delivery_agent_count': deliveryAgentCount,
        'b2b_customer_count': customerCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  // Invite a new user through the privileged Edge Function; no password is handled by the admin UI.
  Future<void> createUser({
    required String email,
    required String fullName,
    required String role,
    String? phone,
    String? companyName,
  }) async {
    try {
      final response = await _supabase.functions.invoke('create_user', body: {
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'company_name': companyName,
      });
      if (response.status >= 400) {
        throw Exception(response.data);
      }
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
        'phone': phone,
        'company_name': companyName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      final roleRow = await _supabase
          .from('roles')
          .select('id')
          .eq('name', role)
          .single();
      await _supabase.rpc('update_user_role', params: {
        'p_target_user': userId,
        'p_new_role': roleRow['id'],
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Update user status (active/inactive)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _supabase.rpc('update_user_status', params: {
        'p_target_user': userId,
        'p_is_active': isActive,
      });
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
