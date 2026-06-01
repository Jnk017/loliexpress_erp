import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  static CustomerService? _instance;
  static CustomerService get instance => _instance ??= CustomerService._();
  CustomerService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCustomers(
      {String? search, int limit = 50, int offset = 0}) async {
    try {
      var query = _client.from('customers').select();
      if (search != null && search.isNotEmpty) {
        query = query.or(
            'company_name.ilike.%$search%,contact_person.ilike.%$search%,email.ilike.%$search%');
      }
      final response =
          await query.order('company_name').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des clients: $e');
    }
  }

  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    try {
      return await _client
          .from('customers')
          .select()
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      throw Exception('Erreur lors du chargement du client: $e');
    }
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.from('customers').insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la création du client: $e');
    }
  }

  Future<Map<String, dynamic>> updateCustomer(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('customers')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du client: $e');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du client: $e');
    }
  }

  Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final customers = await _client
          .from('customers')
          .select('id, credit_limit, current_balance');
      int total = customers.length;
      double totalCredit = 0;
      double totalBalance = 0;
      for (final c in customers) {
        totalCredit += (c['credit_limit'] as num?)?.toDouble() ?? 0;
        totalBalance += (c['current_balance'] as num?)?.toDouble() ?? 0;
      }
      return {
        'total_customers': total,
        'total_credit_limit': totalCredit,
        'total_outstanding': totalBalance,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques clients: $e');
    }
  }
}
